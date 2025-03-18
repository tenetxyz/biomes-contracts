// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { safeGetObjectTypeIdAt, getOrCreateEntityAt } from "../utils/EntityUtils.sol";
import { removeFromInventory, addToInventory } from "../utils/InventoryUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { Vec3 } from "../Vec3.sol";
import { EntityId } from "../EntityId.sol";

// TODO: should we have an "emptyBucket()" function or should we allow placing water in the build system?
contract BucketSystem is System {
  function fillBucket(Vec3 waterCoord) external {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());
    PlayerUtils.requireInPlayerInfluence(playerCoord, waterCoord);

    require(safeGetObjectTypeIdAt(waterCoord) == ObjectTypes.Water, "Not water");

    removeFromInventory(playerEntityId, ObjectTypes.Bucket, 1);
    addToInventory(playerEntityId, ObjectTypes.Player, ObjectTypes.WaterBucket, 1);
  }

  function wetFarmland(Vec3 coord) external {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());
    PlayerUtils.requireInPlayerInfluence(playerCoord, coord);

    (EntityId farmlandEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId == ObjectTypes.Farmland, "Not farmland");
    ObjectType._set(farmlandEntityId, ObjectTypes.WetFarmland);

    removeFromInventory(playerEntityId, ObjectTypes.WaterBucket, 1);
    addToInventory(playerEntityId, ObjectTypes.Player, ObjectTypes.Bucket, 1);
  }
}
