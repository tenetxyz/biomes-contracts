// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder } from "../Utils.sol";
import { transferInventoryNonEntity, transferInventoryEntity, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, PickupNotifData } from "../utils/NotifUtils.sol";
import { PickupData } from "../Types.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_PICKUP_ENERGY_COST } from "../Constants.sol";
import { transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";

contract PickupSystem is System {
  function pickupCommon(VoxelCoord memory coord) internal returns (EntityId, EntityId) {
    require(inWorldBorder(coord), "Cannot pickup outside the world border");

    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId.exists(), "No entity at pickup location");

    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == AirObjectID, "Cannot pickup from a non-air block");

    transferEnergyFromPlayerToPool(playerEntityId, playerCoord, PLAYER_PICKUP_ENERGY_COST);

    return (playerEntityId, entityId);
  }

  function pickupAll(VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    uint256 numTransferred = transferAllInventoryEntities(entityId, playerEntityId, PlayerObjectID);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: AirObjectID, pickupAmount: uint16(numTransferred) })
    );
  }

  function pickup(ObjectTypeId pickupObjectTypeId, uint16 numToPickup, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    transferInventoryNonEntity(entityId, playerEntityId, PlayerObjectID, pickupObjectTypeId, numToPickup);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: pickupObjectTypeId, pickupAmount: numToPickup })
    );
  }

  function pickupTool(EntityId toolEntityId, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    ObjectTypeId toolObjectTypeId = transferInventoryEntity(entityId, playerEntityId, PlayerObjectID, toolEntityId);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 })
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

      notify(
        playerEntityId,
        PickupNotifData({
          pickupCoord: coord,
          pickupObjectTypeId: pickupObject.objectTypeId,
          pickupAmount: pickupObject.numToPickup
        })
      );
    }

    for (uint256 i = 0; i < pickupTools.length; i++) {
      ObjectTypeId toolObjectTypeId = transferInventoryEntity(entityId, playerEntityId, PlayerObjectID, pickupTools[i]);

      notify(
        playerEntityId,
        PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 })
      );
    }
  }
}
