// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder } from "../Utils.sol";
import { transferInventoryNonEntity, transferInventoryEntity, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

import { PickupData } from "../Types.sol";
import { EntityId } from "../EntityId.sol";

contract PickupSystem is System {
  function pickupCommon(VoxelCoord memory coord) internal returns (EntityId, EntityId) {
    require(inWorldBorder(coord), "Cannot pickup outside the world border");

    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId.exists(), "Cannot pickup from an unrevealed block");

    uint16 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == AirObjectID, "Cannot pickup from a non-air block");

    return (playerEntityId, entityId);
  }

  function pickupAll(VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
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
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    transferInventoryNonEntity(entityId, playerEntityId, PlayerObjectID, pickupObjectTypeId, numToPickup);

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

  function pickupTool(EntityId toolEntityId, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    uint16 toolObjectTypeId = transferInventoryEntity(entityId, playerEntityId, PlayerObjectID, toolEntityId);

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
    EntityId[] memory pickupTools,
    VoxelCoord memory coord
  ) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      PickupData memory pickupObject = pickupObjects[i];
      transferInventoryNonEntity(
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
      uint16 toolObjectTypeId = transferInventoryEntity(entityId, playerEntityId, PlayerObjectID, pickupTools[i]);

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
