// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ActionType } from "../codegen/common.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import {
  transferAllInventoryEntities,
  transferInventoryEntity,
  transferInventoryNonEntity
} from "../utils/InventoryUtils.sol";

import { PickupNotifData, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { ReversePosition } from "../utils/Vec3Storage.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { Vec3 } from "../Vec3.sol";

contract PickupSystem is System {
  function pickupCommon(EntityId callerEntityId, Vec3 coord) internal returns (EntityId) {
    callerEntityId.activate();
    callerEntityId.requireConnected(coord);

    EntityId entityId = ReversePosition._get(coord);
    require(entityId.exists(), "No entity at pickup location");

    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(ObjectTypeMetadata._getCanPassThrough(objectTypeId), "Cannot pickup from a non-passable block");

    return entityId;
  }

  function pickupAll(EntityId callerEntityId, Vec3 coord) public {
    EntityId entityId = pickupCommon(callerEntityId, coord);
    uint256 numTransferred = transferAllInventoryEntities(entityId, callerEntityId, ObjectTypes.Player);

    notify(
      callerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: ObjectTypes.Air, pickupAmount: uint16(numTransferred) })
    );
  }

  function pickup(EntityId callerEntityId, ObjectTypeId pickupObjectTypeId, uint16 numToPickup, Vec3 coord) public {
    EntityId entityId = pickupCommon(callerEntityId, coord);
    transferInventoryNonEntity(entityId, callerEntityId, ObjectTypes.Player, pickupObjectTypeId, numToPickup);

    notify(
      callerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: pickupObjectTypeId, pickupAmount: numToPickup })
    );
  }

  function pickupTool(EntityId callerEntityId, EntityId toolEntityId, Vec3 coord) public {
    EntityId entityId = pickupCommon(callerEntityId, coord);
    ObjectTypeId toolObjectTypeId = transferInventoryEntity(entityId, callerEntityId, ObjectTypes.Player, toolEntityId);

    notify(
      callerEntityId, PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 })
    );
  }

  function pickupMultiple(
    EntityId callerEntityId,
    ObjectAmount[] memory pickupObjects,
    EntityId[] memory pickupTools,
    Vec3 coord
  ) public {
    EntityId entityId = pickupCommon(callerEntityId, coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      ObjectAmount memory pickupObject = pickupObjects[i];
      transferInventoryNonEntity(
        entityId, callerEntityId, ObjectTypes.Player, pickupObject.objectTypeId, pickupObject.amount
      );

      notify(
        callerEntityId,
        PickupNotifData({
          pickupCoord: coord,
          pickupObjectTypeId: pickupObject.objectTypeId,
          pickupAmount: pickupObject.amount
        })
      );
    }

    for (uint256 i = 0; i < pickupTools.length; i++) {
      ObjectTypeId toolObjectTypeId =
        transferInventoryEntity(entityId, callerEntityId, ObjectTypes.Player, pickupTools[i]);

      notify(
        callerEntityId, PickupNotifData({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 })
      );
    }
  }
}
