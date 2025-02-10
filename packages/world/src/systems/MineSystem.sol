// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { DisplayContent, DisplayContentData } from "../codegen/tables/DisplayContent.sol";
import { ObjectCategory, ActionType, DisplayContentType } from "../codegen/common.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, inWorldBorder, positionDataToVoxelCoord } from "../Utils.sol";
import { addToInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { IForceFieldSystem } from "../codegen/world/IForceFieldSystem.sol";

contract MineSystem is System {
  function mineObjectAtCoord(VoxelCoord memory coord) internal returns (bytes32, uint16) {
    require(inWorldBorder(coord), "Cannot mine outside the world border");

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId != bytes32(0), "Cannot mine an unrevealed block");
    uint16 mineObjectTypeId = ObjectType._get(entityId);
    address chipAddress = Chip._get(entityId);
    require(chipAddress == address(0), "Cannot mine a chipped block");
    EnergyData memory machineData = updateMachineEnergyLevel(entityId);
    require(machineData.energy == 0, "Cannot mine a machine that has energy");
    if (DisplayContent._getContentType(entityId) != DisplayContentType.None) {
      DisplayContent._deleteRecord(entityId);
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
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (bytes32 firstEntityId, uint16 mineObjectTypeId) = mineObjectAtCoord(coord);
    uint256 numRelativePositions = ObjectTypeSchema._lengthRelativePositionsX(mineObjectTypeId);
    VoxelCoord[] memory coords = new VoxelCoord[](numRelativePositions + 1);

    VoxelCoord memory baseCoord = coord;
    bytes32 baseEntityId = BaseEntity._get(firstEntityId);
    if (baseEntityId != bytes32(0)) {
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
        (bytes32 relativeEntityId, ) = mineObjectAtCoord(relativeCoord);
        BaseEntity._deleteRecord(relativeEntityId);
      }
    }

    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    // TODO: useEquipped
    // TODO: apply energy cost to player

    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory aboveCoord = VoxelCoord(coords[i].x, coords[i].y + 1, coords[i].z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Mine,
        entityId: baseEntityId != bytes32(0) ? baseEntityId : firstEntityId,
        objectTypeId: mineObjectTypeId,
        coordX: baseCoord.x,
        coordY: baseCoord.y,
        coordZ: baseCoord.z,
        amount: 1
      })
    );

    callInternalSystem(
      abi.encodeCall(
        IForceFieldSystem.requireMinesAllowed,
        (playerEntityId, baseEntityId != bytes32(0) ? baseEntityId : firstEntityId, mineObjectTypeId, coords, extraData)
      ),
      _msgValue()
    );
  }

  function mine(VoxelCoord memory coord) public payable {
    mineWithExtraData(coord, new bytes(0));
  }
}
