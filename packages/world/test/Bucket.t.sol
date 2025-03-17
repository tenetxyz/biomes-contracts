// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { ReversePosition, PlayerPosition } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract BucketTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function testFillBucket() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3 waterCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    assertEq(TerrainLib.getBlockType(waterCoord), ObjectTypes.Water, "Water coord is not water");

    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.Bucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("fill bucket");
    world.fillBucket(waterCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 0);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 1);
  }

  function testWetFarmland() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    EntityId farmlandEntityId = setObjectAtCoord(farmlandCoord, ObjectTypes.Farmland);

    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WaterBucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("wet farmland");
    world.wetFarmland(farmlandCoord);
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

    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.Bucket, 1);

    vm.prank(alice);
    vm.expectRevert("Not water");
    world.fillBucket(nonWaterCoord);
  }

  function testFillBucketFailsIfNoBucket() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3 waterCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    assertEq(TerrainLib.getBlockType(waterCoord), ObjectTypes.Water, "Water coord is not water");

    assertInventoryHasObject(aliceEntityId, ObjectTypes.Bucket, 0);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.fillBucket(waterCoord);
  }

  function testFillBucketFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3 waterCoord = vec3(playerCoord.x() + int32(MAX_PLAYER_INFLUENCE_HALF_WIDTH) + 1, 0, playerCoord.z());

    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.Bucket, 1);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.fillBucket(waterCoord);
  }

  function testWetFarmlandFailsIfNotFarmland() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 nonFarmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(nonFarmlandCoord, ObjectTypes.Dirt);

    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WaterBucket, 1);

    vm.prank(alice);
    vm.expectRevert("Not farmland");
    world.wetFarmland(nonFarmlandCoord);
  }

  function testWetFarmlandFailsIfNoWaterBucket() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.Farmland);

    assertInventoryHasObject(aliceEntityId, ObjectTypes.WaterBucket, 0);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.wetFarmland(farmlandCoord);
  }

  function testWetFarmlandFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 farmlandCoord = vec3(playerCoord.x() + int32(MAX_PLAYER_INFLUENCE_HALF_WIDTH) + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.Farmland);

    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WaterBucket, 1);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.wetFarmland(farmlandCoord);
  }
}
