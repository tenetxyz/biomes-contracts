// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";
import { voxelCoordsAreEqual } from "../utils/VoxelCoordUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ObjectCategory, ActionType, DisplayContentType } from "../codegen/common.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity, positionDataToVoxelCoord } from "../Utils.sol";
import { addToInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { notify, MineNotifData } from "../utils/NotifUtils.sol";
import { GravityLib } from "./libraries/GravityLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";

contract MineSystem is System {
  function mineObjectAtCoord(VoxelCoord memory coord) internal returns (EntityId, uint16) {
    require(inWorldBorder(coord), "Cannot mine outside the world border");

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    uint16 mineObjectTypeId;
    if (!entityId.exists()) {
      mineObjectTypeId = TerrainLib._getBlockType(coord);
      require(mineObjectTypeId != AnyOreObjectID, "Ore must be computed before it can be mined");

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      mineObjectTypeId = ObjectType._get(entityId);
      address chipAddress = Chip._get(entityId);
      require(chipAddress == address(0), "Cannot mine a chipped block");
      EnergyData memory machineData = updateMachineEnergyLevel(entityId);
      require(machineData.energy == 0, "Cannot mine a machine that has energy");
      if (DisplayContent._getContentType(entityId) != DisplayContentType.None) {
        DisplayContent._deleteRecord(entityId);
      }
    }
    require(
      ObjectTypeMetadata._getObjectCategory(mineObjectTypeId) == ObjectCategory.Block,
      "Cannot mine non-block object"
    );
    require(mineObjectTypeId != AirObjectID, "Cannot mine air");
    require(mineObjectTypeId != WaterObjectID, "Cannot mine water");

    ObjectType._set(entityId, AirObjectID);

    return (entityId, mineObjectTypeId);
  }

  function mineWithExtraData(VoxelCoord memory coord, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId firstEntityId, uint16 mineObjectTypeId) = mineObjectAtCoord(coord);
    uint256 numRelativePositions = ObjectTypeSchema._lengthRelativePositionsX(mineObjectTypeId);
    VoxelCoord[] memory coords = new VoxelCoord[](numRelativePositions + 1);

    VoxelCoord memory baseCoord = coord;
    EntityId baseEntityId = BaseEntity._get(firstEntityId);
    if (baseEntityId.exists()) {
      baseCoord = positionDataToVoxelCoord(Position._get(baseEntityId));
      mineObjectAtCoord(baseCoord);
      BaseEntity._deleteRecord(firstEntityId);
    }
    coords[0] = baseCoord;

    if (numRelativePositions > 0) {
      ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(mineObjectTypeId);
      for (uint256 i = 0; i < numRelativePositions; i++) {
        VoxelCoord memory relativeCoord = VoxelCoord(
          baseCoord.x + schemaData.relativePositionsX[i],
          baseCoord.y + schemaData.relativePositionsY[i],
          baseCoord.z + schemaData.relativePositionsZ[i]
        );
        coords[i + 1] = relativeCoord;
        if (voxelCoordsAreEqual(relativeCoord, coord)) {
          continue;
        }
        (EntityId relativeEntityId, ) = mineObjectAtCoord(relativeCoord);
        BaseEntity._deleteRecord(relativeEntityId);
      }
    }

    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    // TODO: useEquipped
    // TODO: apply energy cost to player

    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory aboveCoord = VoxelCoord(coords[i].x, coords[i].y + 1, coords[i].z);
      EntityId aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId.exists() && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        GravityLib.runGravity(aboveEntityId, aboveCoord);
      }
    }

    notify(
      playerEntityId,
      MineNotifData({
        mineEntityId: baseEntityId.exists() ? baseEntityId : firstEntityId,
        mineCoord: baseCoord,
        mineObjectTypeId: mineObjectTypeId
      })
    );

    ForceFieldLib.requireMinesAllowed(
      playerEntityId,
      baseEntityId.exists() ? baseEntityId : firstEntityId,
      mineObjectTypeId,
      coords,
      extraData
    );
  }

  function mine(VoxelCoord memory coord) public payable {
    mineWithExtraData(coord, new bytes(0));
  }
}
