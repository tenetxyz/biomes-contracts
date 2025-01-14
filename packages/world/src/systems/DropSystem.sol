// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { AirObjectID, WaterObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity, callMintXP } from "../Utils.sol";
import { transferInventoryNonTool, transferInventoryTool } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

contract DropSystem is System {
  function dropCommon(VoxelCoord memory coord) internal returns (bytes32, bytes32) {
    require(inWorldBorder(coord), "DropSystem: cannot drop outside world border");
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "DropSystem: cannot drop on non-air block"
      );

      // Create new entity
      entityId = getUniqueEntity();
      ObjectType._set(entityId, AirObjectID);
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "DropSystem: cannot drop on non-air block");
    }

    return (playerEntityId, entityId);
  }

  function drop(uint8 dropObjectTypeId, uint16 numToDrop, VoxelCoord memory coord) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, bytes32 entityId) = dropCommon(coord);
    transferInventoryNonTool(playerEntityId, entityId, AirObjectID, dropObjectTypeId, numToDrop);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Drop,
        entityId: entityId,
        objectTypeId: dropObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: numToDrop
      })
    );

    callMintXP(playerEntityId, initialGas, 1);
  }

  function dropTool(bytes32 toolEntityId, VoxelCoord memory coord) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, bytes32 entityId) = dropCommon(coord);
    uint8 toolObjectTypeId = transferInventoryTool(playerEntityId, entityId, AirObjectID, toolEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Drop,
        entityId: entityId,
        objectTypeId: toolObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: 1
      })
    );

    callMintXP(playerEntityId, initialGas, 1);
  }

  function dropTools(bytes32[] memory toolEntityIds, VoxelCoord memory coord) public {
    uint256 initialGas = gasleft();
    require(toolEntityIds.length > 0, "DropSystem: must drop at least one tool");
    require(toolEntityIds.length < type(uint16).max, "DropSystem: too many tools to drop");

    (bytes32 playerEntityId, bytes32 entityId) = dropCommon(coord);

    uint8 toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      uint8 currentToolObjectTypeId = transferInventoryTool(playerEntityId, entityId, AirObjectID, toolEntityIds[i]);
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "DropSystem: all tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Drop,
        entityId: entityId,
        objectTypeId: toolObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: toolEntityIds.length
      })
    );

    callMintXP(playerEntityId, initialGas, 1);
  }
}
