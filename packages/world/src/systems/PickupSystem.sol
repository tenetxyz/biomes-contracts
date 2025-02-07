// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity, callMintXP } from "../Utils.sol";
import { transferInventoryNonTool, transferInventoryTool, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { PickupData } from "../Types.sol";

contract PickupSystem is System {
  function pickupCommon(VoxelCoord memory coord) internal returns (bytes32, bytes32) {
    require(inWorldBorder(coord), "Cannot pickup outside the world border");

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId != bytes32(0), "Cannot pickup from an unrevealed block");

    uint16 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == AirObjectID, "Cannot pickup from a non-air block");

    return (playerEntityId, entityId);
  }

  function pickupAll(VoxelCoord memory coord) public {
    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);
    uint256 numTransferred = transferAllInventoryEntities(entityId, playerEntityId, PlayerObjectID);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Pickup,
        entityId: entityId,
        objectTypeId: AirObjectID,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: numTransferred
      })
    );
  }

  function pickup(uint16 pickupObjectTypeId, uint16 numToPickup, VoxelCoord memory coord) public {
    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);
    transferInventoryNonTool(entityId, playerEntityId, PlayerObjectID, pickupObjectTypeId, numToPickup);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Pickup,
        entityId: entityId,
        objectTypeId: pickupObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: numToPickup
      })
    );
  }

  function pickupTool(bytes32 toolEntityId, VoxelCoord memory coord) public {
    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);
    uint16 toolObjectTypeId = transferInventoryTool(entityId, playerEntityId, PlayerObjectID, toolEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Pickup,
        entityId: entityId,
        objectTypeId: toolObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: 1
      })
    );
  }

  function pickupMultiple(
    PickupData[] memory pickupObjects,
    bytes32[] memory pickupTools,
    VoxelCoord memory coord
  ) public {
    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      PickupData memory pickupObject = pickupObjects[i];
      transferInventoryNonTool(
        entityId,
        playerEntityId,
        PlayerObjectID,
        pickupObject.objectTypeId,
        pickupObject.numToPickup
      );

      PlayerActionNotif._set(
        playerEntityId,
        PlayerActionNotifData({
          actionType: ActionType.Pickup,
          entityId: entityId,
          objectTypeId: pickupObject.objectTypeId,
          coordX: coord.x,
          coordY: coord.y,
          coordZ: coord.z,
          amount: pickupObject.numToPickup
        })
      );
    }

    for (uint256 i = 0; i < pickupTools.length; i++) {
      uint16 toolObjectTypeId = transferInventoryTool(entityId, playerEntityId, PlayerObjectID, pickupTools[i]);

      PlayerActionNotif._set(
        playerEntityId,
        PlayerActionNotifData({
          actionType: ActionType.Pickup,
          entityId: entityId,
          objectTypeId: toolObjectTypeId,
          coordX: coord.x,
          coordY: coord.y,
          coordZ: coord.z,
          amount: 1
        })
      );
    }
  }
}
