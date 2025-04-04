// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { getOrCreateEntityAt, safeGetObjectTypeIdAt } from "../utils/EntityUtils.sol";
import { InventoryUtils } from "../utils/InventoryUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3 } from "../Vec3.sol";

// TODO: should we have an "emptyBucket()" function or should we allow placing water in the build system?
contract BucketSystem is System {
  function fillBucket(EntityId caller, Vec3 waterCoord) external {
    caller.activate();
    caller.requireConnected(waterCoord);

    require(safeGetObjectTypeIdAt(waterCoord) == ObjectTypes.Water, "Not water");

    InventoryUtils.removeObject(caller, ObjectTypes.Bucket, 1);
    InventoryUtils.addObject(caller, ObjectTypes.WaterBucket, 1);
  }

  function wetFarmland(EntityId caller, Vec3 coord) external {
    caller.activate();
    caller.requireConnected(coord);

    (EntityId farmland, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId == ObjectTypes.Farmland, "Not farmland");
    ObjectType._set(farmland, ObjectTypes.WetFarmland);

    InventoryUtils.removeObject(caller, ObjectTypes.WaterBucket, 1);
    InventoryUtils.addObject(caller, ObjectTypes.Bucket, 1);
  }
}
