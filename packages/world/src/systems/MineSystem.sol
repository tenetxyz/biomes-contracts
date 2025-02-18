// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ActionType, DisplayContentType } from "../codegen/common.sol";

import { ObjectTypeId, AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel, energyToMass, transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { notify, MineNotifData } from "../utils/NotifUtils.sol";
import { GravityLib } from "./libraries/GravityLib.sol";
import { ForceFieldLib } from "./libraries/ForceFieldLib.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_MINE_ENERGY_COST } from "../Constants.sol";

contract MineSystem is System {
  using VoxelCoordLib for *;

  function mineObjectAtCoord(VoxelCoord memory coord) internal returns (EntityId, ObjectTypeId) {
    require(inWorldBorder(coord), "Cannot mine outside the world border");

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    ObjectTypeId mineObjectTypeId;
    if (!entityId.exists()) {
      // TODO: move wrapping to TerrainLib?
      mineObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(coord));
      require(mineObjectTypeId != AnyOreObjectID, "Ore must be computed before it can be mined");

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
      Mass._setMass(entityId, ObjectTypeMetadata._getMass(mineObjectTypeId));
    } else {
      mineObjectTypeId = ObjectType._get(entityId);
      require(entityId.getChipAddress() == address(0), "Cannot mine a chipped block");
      EnergyData memory machineData = updateMachineEnergyLevel(entityId);
      require(machineData.energy == 0, "Cannot mine a machine that has energy");
    }
    require(mineObjectTypeId.isBlock(), "Cannot mine non-block object");
    require(mineObjectTypeId != AirObjectID, "Cannot mine air");
    require(mineObjectTypeId != WaterObjectID, "Cannot mine water");

    return (entityId, mineObjectTypeId);
  }

  function mineWithExtraData(VoxelCoord memory coord, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId baseEntityId, ObjectTypeId mineObjectTypeId) = mineObjectAtCoord(coord);
    require(!BaseEntity._get(baseEntityId).exists(), "Invalid mine coord, must mine the base coord");

    uint128 totalMassReduction = energyToMass(PLAYER_MINE_ENERGY_COST) + useEquipped(playerEntityId);
    uint128 massLeft = Mass._getMass(baseEntityId);
    transferEnergyFromPlayerToPool(playerEntityId, playerCoord, PLAYER_MINE_ENERGY_COST);

    uint256 numRelativePositions = ObjectTypeSchema._lengthRelativePositionsX(mineObjectTypeId);
    VoxelCoord[] memory coords = new VoxelCoord[](numRelativePositions + 1);
    coords[0] = coord;

    if (numRelativePositions > 0) {
      ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(mineObjectTypeId);
      for (uint256 i = 0; i < numRelativePositions; i++) {
        VoxelCoord memory relativeCoord = VoxelCoord(
          coord.x + schemaData.relativePositionsX[i],
          coord.y + schemaData.relativePositionsY[i],
          coord.z + schemaData.relativePositionsZ[i]
        );
        coords[i + 1] = relativeCoord;

        if (massLeft <= totalMassReduction) {
          (EntityId relativeEntityId, ) = mineObjectAtCoord(relativeCoord);
          BaseEntity._deleteRecord(relativeEntityId);
          ObjectType._set(relativeEntityId, AirObjectID);
        }
      }
    }

    if (massLeft <= totalMassReduction) {
      Mass._deleteRecord(baseEntityId);
      if (DisplayContent._getContentType(baseEntityId) != DisplayContentType.None) {
        DisplayContent._deleteRecord(baseEntityId);
      }
      ObjectType._set(baseEntityId, AirObjectID);

      addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

      for (uint256 i = 0; i < coords.length; i++) {
        VoxelCoord memory aboveCoord = VoxelCoord(coords[i].x, coords[i].y + 1, coords[i].z);
        EntityId aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
        if (aboveEntityId.exists() && ObjectType._get(aboveEntityId) == PlayerObjectID) {
          GravityLib.runGravity(aboveEntityId, aboveCoord);
        }
      }
    } else {
      Mass._setMass(baseEntityId, massLeft - totalMassReduction);
    }

    notify(
      playerEntityId,
      MineNotifData({ mineEntityId: baseEntityId, mineCoord: coord, mineObjectTypeId: mineObjectTypeId })
    );

    ForceFieldLib.requireMinesAllowed(playerEntityId, baseEntityId, mineObjectTypeId, coords, extraData);
  }

  function mine(VoxelCoord memory coord) public payable {
    mineWithExtraData(coord, new bytes(0));
  }
}
