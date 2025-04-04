// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Action } from "../codegen/common.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { InventoryUtils } from "../utils/InventoryUtils.sol";

import { PickupNotification, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { ReversePosition } from "../utils/Vec3Storage.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { Vec3 } from "../Vec3.sol";

contract PickupSystem is System {
  function pickupCommon(EntityId caller, Vec3 coord) internal returns (EntityId) {
    caller.activate();
    caller.requireConnected(coord);

    EntityId entityId = ReversePosition._get(coord);
    require(entityId.exists(), "No entity at pickup location");

    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(ObjectTypeMetadata._getCanPassThrough(objectTypeId), "Cannot pickup from a non-passable block");

    return entityId;
  }

  function pickupAll(EntityId caller, Vec3 coord) public {
    EntityId entityId = pickupCommon(caller, coord);
    uint256 numTransferred = InventoryUtils.transferAll(entityId, caller, ObjectTypes.Player);

    notify(
      caller,
      PickupNotification({
        pickupCoord: coord,
        pickupObjectTypeId: ObjectTypes.Air,
        pickupAmount: uint16(numTransferred)
      })
    );
  }

  function pickup(EntityId caller, ObjectTypeId pickupObjectTypeId, uint16 numToPickup, Vec3 coord) public {
    EntityId entityId = pickupCommon(caller, coord);
    InventoryUtils.transfer(entityId, caller, ObjectTypes.Player, pickupObjectTypeId, numToPickup);

    notify(
      caller,
      PickupNotification({ pickupCoord: coord, pickupObjectTypeId: pickupObjectTypeId, pickupAmount: numToPickup })
    );
  }

  function pickupTool(EntityId caller, EntityId tool, Vec3 coord) public {
    EntityId entityId = pickupCommon(caller, coord);
    ObjectTypeId toolObjectTypeId = transferInventoryEntity(entityId, caller, ObjectTypes.Player, tool);

    notify(caller, PickupNotification({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 }));
  }

  function pickupMultiple(
    EntityId caller,
    ObjectAmount[] memory pickupObjects,
    EntityId[] memory pickupTools,
    Vec3 coord
  ) public {
    EntityId entityId = pickupCommon(caller, coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      ObjectAmount memory pickupObject = pickupObjects[i];
      InventoryUtils.transfer(entityId, caller, ObjectTypes.Player, pickupObject.objectTypeId, pickupObject.amount);

      notify(
        caller,
        PickupNotification({
          pickupCoord: coord,
          pickupObjectTypeId: pickupObject.objectTypeId,
          pickupAmount: pickupObject.amount
        })
      );
    }

    for (uint256 i = 0; i < pickupTools.length; i++) {
      ObjectTypeId toolObjectTypeId = transferInventoryEntity(entityId, caller, ObjectTypes.Player, pickupTools[i]);

      notify(caller, PickupNotification({ pickupCoord: coord, pickupObjectTypeId: toolObjectTypeId, pickupAmount: 1 }));
    }
  }
}
