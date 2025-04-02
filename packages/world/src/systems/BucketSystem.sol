// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { getOrCreateEntityAt, safeGetObjectTypeIdAt } from "../utils/EntityUtils.sol";
import { addToInventory, removeFromInventory } from "../utils/InventoryUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3 } from "../Vec3.sol";

// TODO: should we have an "emptyBucket()" function or should we allow placing water in the build system?
contract BucketSystem is System {
  function fillBucket(EntityId callerEntityId, Vec3 waterCoord) external {
    callerEntityId.activate();
    callerEntityId.requireConnected(waterCoord);

    require(safeGetObjectTypeIdAt(waterCoord) == ObjectTypes.Water, "Not water");

    removeFromInventory(callerEntityId, ObjectTypes.Bucket, 1);
    addToInventory(callerEntityId, ObjectType._get(callerEntityId), ObjectTypes.WaterBucket, 1);
  }

  function wetFarmland(EntityId callerEntityId, Vec3 coord) external {
    callerEntityId.activate();
    callerEntityId.requireConnected(coord);

    (EntityId farmlandEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId == ObjectTypes.Farmland, "Not farmland");
    ObjectType._set(farmlandEntityId, ObjectTypes.WetFarmland);

    removeFromInventory(callerEntityId, ObjectTypes.WaterBucket, 1);
    addToInventory(callerEntityId, ObjectType._get(callerEntityId), ObjectTypes.Bucket, 1);
  }
}
