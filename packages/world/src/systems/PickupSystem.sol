// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { ReversePosition } from "../utils/Vec3Storage.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { inWorldBorder } from "../Utils.sol";
import { transferInventoryNonEntity, transferInventoryEntity, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, PickupNotifData } from "../utils/NotifUtils.sol";
import { PickupData } from "../Types.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { PLAYER_PICKUP_ENERGY_COST } from "../Constants.sol";
import { transferEnergyToPool } from "../utils/EnergyUtils.sol";

contract PickupSystem is System {
  function pickupCommon(Vec3 coord) internal returns (EntityId, EntityId) {
    require(inWorldBorder(coord), "Cannot pickup outside the world border");

    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    EntityId entityId = ReversePosition._get(coord);
    require(entityId.exists(), "No entity at pickup location");

    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == ObjectTypes.Air, "Cannot pickup from a non-air block");

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_PICKUP_ENERGY_COST);

    return (playerEntityId, entityId);
  }

  function pickupAll(Vec3 coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    uint256 numTransferred = transferAllInventoryEntities(entityId, playerEntityId, ObjectTypes.Player);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: ObjectTypes.Air, pickupAmount: uint16(numTransferred) })
    );
  }

  function pickup(ObjectTypeId pickupObjectTypeId, uint16 numToPickup, Vec3 coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    transferInventoryNonEntity(entityId, playerEntityId, ObjectTypes.Player, pickupObjectTypeId, numToPickup);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: pickupObjectTypeId, pickupAmount: numToPickup })
    );
  }

  function pickupTool(EntityId toolEntityId, Vec3 coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    ObjectTypeId toolObjectTypeId = transferInventoryEntity(entityId, playerEntityId, ObjectTypes.Player, toolEntityId);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 })
    );
  }

  function pickupMultiple(PickupData[] memory pickupObjects, EntityId[] memory pickupTools, Vec3 coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      PickupData memory pickupObject = pickupObjects[i];
      transferInventoryNonEntity(
        entityId,
        playerEntityId,
        ObjectTypes.Player,
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
      ObjectTypeId toolObjectTypeId = transferInventoryEntity(
        entityId,
        playerEntityId,
        ObjectTypes.Player,
        pickupTools[i]
      );

      notify(
        playerEntityId,
        PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 })
      );
    }
  }
}
