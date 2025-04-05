// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { console } from "forge-std/console.sol";

import { EntityId } from "../src/EntityId.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { MovablePosition, ReversePosition } from "../src/utils/Vec3Storage.sol";

import { MAX_ENTITY_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { DustTest } from "./DustTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract BucketTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testFillBucket() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3 waterCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    assertEq(TerrainLib.getBlockType(waterCoord), ObjectTypes.Water, "Water coord is not water");

    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.Bucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 0);

    vm.prank(alice);
    startGasReport("fill bucket");
    world.fillBucket(aliceEntityId, waterCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 0);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 1);
  }

  function testWetFarmland() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    EntityId farmlandEntityId = setObjectAtCoord(farmlandCoord, ObjectTypes.Farmland);

    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.WaterBucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 0);

    vm.prank(alice);
    startGasReport("wet farmland");
    world.wetFarmland(aliceEntityId, farmlandCoord);
    endGasReport();

    assertEq(ObjectType.get(farmlandEntityId), ObjectTypes.WetFarmland, "Farmland was not converted to wet farmland");
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 0);
  }

  function testFillBucketFailsIfNotWater() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 nonWaterCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(nonWaterCoord, ObjectTypes.Dirt);
    assertEq(TerrainLib.getBlockType(nonWaterCoord), ObjectTypes.Dirt, "Non-water coord is not dirt");

    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.Bucket, 1);

    vm.prank(alice);
    vm.expectRevert("Not water");
    world.fillBucket(aliceEntityId, nonWaterCoord);
  }

  function testFillBucketFailsIfNoBucket() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3 waterCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    assertEq(TerrainLib.getBlockType(waterCoord), ObjectTypes.Water, "Water coord is not water");

    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 0);

    vm.prank(alice);
    vm.expectRevert("No objects of this type in inventory");
    world.fillBucket(aliceEntityId, waterCoord);
  }

  function testFillBucketFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3 waterCoord = vec3(playerCoord.x() + int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, playerCoord.z());

    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.Bucket, 1);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.fillBucket(aliceEntityId, waterCoord);
  }

  function testWetFarmlandFailsIfNotFarmland() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 nonFarmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(nonFarmlandCoord, ObjectTypes.Dirt);

    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.WaterBucket, 1);

    vm.prank(alice);
    vm.expectRevert("Not farmland");
    world.wetFarmland(aliceEntityId, nonFarmlandCoord);
  }

  function testWetFarmlandFailsIfNoWaterBucket() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.Farmland);

    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 0);

    vm.prank(alice);
    vm.expectRevert("No objects of this type in inventory");
    world.wetFarmland(aliceEntityId, farmlandCoord);
  }

  function testWetFarmlandFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 farmlandCoord = vec3(playerCoord.x() + int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.Farmland);

    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.WaterBucket, 1);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.wetFarmland(aliceEntityId, farmlandCoord);
  }
}
