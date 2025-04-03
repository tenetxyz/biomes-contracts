// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { console } from "forge-std/console.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { ResourceCount } from "../src/codegen/tables/ResourceCount.sol";
import { SeedGrowth } from "../src/codegen/tables/SeedGrowth.sol";

import { LocalEnergyPool } from "../src/utils/Vec3Storage.sol";

import { MovablePosition, ReversePosition } from "../src/utils/Vec3Storage.sol";

import {
  BUILD_ENERGY_COST,
  CHUNK_COMMIT_EXPIRY_BLOCKS,
  MAX_ENTITY_INFLUENCE_HALF_WIDTH,
  MINE_ENERGY_COST,
  TILL_ENERGY_COST
} from "../src/Constants.sol";

import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { DustTest } from "./DustTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract FarmingTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testTillDirt() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);
    EntityId dirtEntityId = ReversePosition.get(dirtCoord);
    assertFalse(dirtEntityId.exists(), "Dirt entity already exists");

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(aliceEntityId, hoeEntityId);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("till dirt");
    world.till(aliceEntityId, dirtCoord);
    endGasReport();

    dirtEntityId = ReversePosition.get(dirtCoord);
    assertTrue(dirtEntityId.exists(), "Dirt entity doesn't exist after tilling");
    assertEq(ObjectType.get(dirtEntityId), ObjectTypes.Farmland, "Dirt was not converted to farmland");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTillGrass() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 grassCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(grassCoord, ObjectTypes.Grass);
    EntityId grassEntityId = ReversePosition.get(grassCoord);
    assertFalse(grassEntityId.exists(), "Grass entity already exists");

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(aliceEntityId, hoeEntityId);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("till grass");
    world.till(aliceEntityId, grassCoord);
    endGasReport();

    grassEntityId = ReversePosition.get(grassCoord);
    assertTrue(grassEntityId.exists(), "Grass entity doesn't exist after tilling");
    assertEq(ObjectType.get(grassEntityId), ObjectTypes.Farmland, "Grass was not converted to farmland");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTillWithDifferentHoes() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    ObjectTypeId[] memory hoeTypes = new ObjectTypeId[](1);
    hoeTypes[0] = ObjectTypes.WoodenHoe;

    for (uint256 i = 0; i < hoeTypes.length; i++) {
      Vec3 testCoord = dirtCoord + vec3(int32(int256(i)), 0, 0);
      setObjectAtCoord(testCoord, ObjectTypes.Dirt);

      EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, hoeTypes[i]);
      vm.prank(alice);
      world.equip(aliceEntityId, hoeEntityId);

      vm.prank(alice);
      world.till(aliceEntityId, testCoord);

      EntityId farmlandEntityId = ReversePosition.get(testCoord);
      assertTrue(farmlandEntityId.exists(), "Farmland entity doesn't exist after tilling");
      assertEq(ObjectType.get(farmlandEntityId), ObjectTypes.Farmland, "Dirt was not converted to farmland");
    }
  }

  function testTillFailsIfNotDirtOrGrass() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 nonDirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(nonDirtCoord, ObjectTypes.Stone);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(aliceEntityId, hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Not dirt or grass");
    world.till(aliceEntityId, nonDirtCoord);
  }

  function testTillFailsIfNoHoeEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    // No hoe equipped

    vm.prank(alice);
    vm.expectRevert("Must equip a hoe");
    world.till(aliceEntityId, dirtCoord);

    // Equipped but not a hoe
    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.SilverPick);
    vm.prank(alice);
    world.equip(aliceEntityId, hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Must equip a hoe");
    world.till(aliceEntityId, dirtCoord);
  }

  function testTillFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(aliceEntityId, hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.till(aliceEntityId, dirtCoord);
  }

  function testTillFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(aliceEntityId, hoeEntityId);

    // Set player energy to less than required
    uint128 toolMass = 0; // Assuming tool mass is 0 for simplicity
    uint128 energyCost = TILL_ENERGY_COST + toolMass;
    Energy.set(
      aliceEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: energyCost - 1, drainRate: 0 })
    );

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.till(aliceEntityId, dirtCoord);
  }

  function testPlantWheatSeeds() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeed, 1);

    // Check initial local energy pool
    uint128 initialLocalEnergy = LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord());
    uint128 seedEnergy = ObjectTypeMetadata.getEnergy(ObjectTypes.WheatSeed);

    // Plant wheat seeds
    vm.prank(alice);
    world.build(aliceEntityId, ObjectTypes.WheatSeed, farmlandCoord + vec3(0, 1, 0), "");

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(farmlandCoord + vec3(0, 1, 0));
    assertTrue(cropEntityId.exists(), "Crop entity doesn't exist after planting");
    assertEq(ObjectType.get(cropEntityId), ObjectTypes.WheatSeed, "Wheat seeds were not planted correctly");

    // Verify energy was taken from local pool
    assertEq(
      LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord()),
      initialLocalEnergy + BUILD_ENERGY_COST - seedEnergy,
      "Energy not correctly taken from local pool"
    );

    // Verify build time was set
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);
    assertTrue(fullyGrownAt > 0, "FullyGrownAt not set correctly");
    assertEq(fullyGrownAt, uint128(block.timestamp) + ObjectTypes.WheatSeed.timeToGrow(), "Incorrect fullyGrownAt set");

    // Verify seeds were removed from inventory
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeed, 0);
  }

  function testPlantSeedsFailsIfNotOnWetFarmland() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeed, 1);

    // Try to plant on dirt (not farmland)
    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    vm.prank(alice);
    vm.expectRevert("Crop seeds need wet farmland");
    world.build(aliceEntityId, ObjectTypes.WheatSeed, dirtCoord + vec3(0, 1, 0), "");

    // Try to plant on farmland (not wet)
    Vec3 farmlandCoord = vec3(playerCoord.x() + 2, 0, playerCoord.z());
    setTerrainAtCoord(farmlandCoord, ObjectTypes.Farmland);

    vm.prank(alice);
    vm.expectRevert("Crop seeds need wet farmland");
    world.build(aliceEntityId, ObjectTypes.WheatSeed, farmlandCoord + vec3(0, 1, 0), "");
  }

  function testHarvestMatureWheatCrop() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeed, 1);
    // Set seed count to 1 so we can grow it
    ResourceCount.set(ObjectTypes.WheatSeed, 1);

    Vec3 cropCoord = farmlandCoord + vec3(0, 1, 0);

    // Plant wheat seeds
    vm.prank(alice);
    world.build(aliceEntityId, ObjectTypes.WheatSeed, cropCoord, "");

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(cropCoord);
    assertTrue(cropEntityId.exists(), "Crop entity doesn't exist after planting");

    // Get growth time required for the crop
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Advance time beyond the growth period
    vm.warp(fullyGrownAt);
    vm.prank(alice);
    world.growSeed(aliceEntityId, cropCoord);

    // Set up chunk commitment for randomness when mining
    Vec3 chunkCoord = cropCoord.toChunkCoord();
    vm.prank(alice);
    world.chunkCommit(aliceEntityId, chunkCoord);
    // Move forward a block to make the commitment valid
    vm.roll(vm.getBlockNumber() + 2);

    // Check local energy pool before harvesting
    uint128 initialLocalEnergy = LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord());

    // Harvest the crop
    vm.prank(alice);
    world.mineUntilDestroyed(aliceEntityId, farmlandCoord + vec3(0, 1, 0), "");

    // Verify wheat and seeds were obtained
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 1);
    // TODO: test randomness
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeed, 0);

    // Verify crop no longer exists
    assertEq(ObjectType.get(cropEntityId), ObjectTypes.Air, "Crop wasn't removed after harvesting");
    assertEq(ResourceCount.get(ObjectTypes.WheatSeed), 0, "Seed wasn't removed from circulation");

    // Verify local energy pool hasn't changed (energy not returned since crop was fully grown)
    // NOTE: player's energy is not reduced as currently wheat has 0 mass
    assertEq(
      LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord()),
      initialLocalEnergy,
      "Local energy pool shouldn't change after harvesting mature crop"
    );
  }

  function testHarvestImmatureWheatCrop() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeed, 1);

    Vec3 cropCoord = farmlandCoord + vec3(0, 1, 0);

    // Get initial energy
    uint128 seedEnergy = ObjectTypeMetadata.getEnergy(ObjectTypes.WheatSeed);

    // Plant wheat seeds
    vm.prank(alice);
    world.build(aliceEntityId, ObjectTypes.WheatSeed, cropCoord, "");

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(cropCoord);
    assertTrue(cropEntityId.exists(), "Crop entity doesn't exist after planting");

    // Get growth time required for the crop
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Advance time but not enough for full growth
    vm.warp(fullyGrownAt - 1); // 1 second before full growth

    // Update player's energy and transfer to pool
    world.activatePlayer(alice);

    // Set up chunk commitment for randomness when mining
    Vec3 chunkCoord = cropCoord.toChunkCoord();
    vm.prank(alice);
    world.chunkCommit(aliceEntityId, chunkCoord);
    // Move forward a block to make the commitment valid
    vm.roll(block.number + 1);

    // Check local energy pool before harvesting
    uint128 beforeHarvestEnergy = LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord());

    // Harvest the crop
    vm.prank(alice);
    world.mineUntilDestroyed(aliceEntityId, cropCoord, "");

    // Verify original seeds were returned (not wheat)
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeed, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 0);

    // Verify crop no longer exists
    assertEq(ObjectType.get(cropEntityId), ObjectTypes.Air, "Crop wasn't removed after harvesting");

    // Verify energy was returned to local pool
    // Note: currently player's energy is only decreased if the
    assertEq(
      LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord()),
      beforeHarvestEnergy + seedEnergy,
      // beforeHarvestEnergy + seedEnergy + MINE_ENERGY_COST,
      "Energy not correctly returned to local pool"
    );
  }

  function testMiningFescueGrassDropsWheatSeeds() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Verify no wheat seeds in inventory initially
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeed, 0);

    Vec3 grassCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());

    // Try up to 10 times to get wheat seeds (there's a 40% chance of getting 0 seeds)
    for (uint256 i = 0; i < 10; i++) {
      // Create FescueGrass
      setTerrainAtCoord(grassCoord, ObjectTypes.FescueGrass);

      // Set up chunk commitment for randomness when mining grass
      Vec3 chunkCoord = grassCoord.toChunkCoord();
      vm.prank(alice);
      world.chunkCommit(aliceEntityId, chunkCoord);
      // Move forward 2 blocks to make the commitment valid
      vm.roll(vm.getBlockNumber() + 2);

      // Harvest the FescueGrass
      vm.prank(alice);
      world.mineUntilDestroyed(aliceEntityId, grassCoord, "");

      // Check if we got seeds
      uint256 seedCount = InventoryCount.get(aliceEntityId, ObjectTypes.WheatSeed);

      if (seedCount > 0) break;

      vm.roll(vm.getBlockNumber() + CHUNK_COMMIT_EXPIRY_BLOCKS);
    }

    // Verify wheat seeds were obtained in at least one attempt
    assertGt(InventoryCount.get(aliceEntityId, ObjectTypes.WheatSeed), 0, "Should have at least one wheat seed");
  }

  function testCropGrowthLifecycle() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeed, 1);

    Vec3 cropCoord = farmlandCoord + vec3(0, 1, 0);
    // Plant wheat seeds
    vm.prank(alice);
    world.build(aliceEntityId, ObjectTypes.WheatSeed, cropCoord, "");

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(cropCoord);
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Mid-growth - Try harvesting before fully grown
    vm.warp(fullyGrownAt - 1);

    vm.prank(alice);
    vm.expectRevert("Seed cannot be grown yet");
    world.growSeed(aliceEntityId, cropCoord);

    // Mine the crop
    vm.prank(alice);
    world.mineUntilDestroyed(aliceEntityId, cropCoord, "");

    // We get seeds back, not wheat
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeed, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 0);

    // Reset test by planting again
    vm.prank(alice);
    world.build(aliceEntityId, ObjectTypes.WheatSeed, cropCoord, "");

    cropEntityId = ReversePosition.get(cropCoord);
    fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Full growth - Warp past the full growth time
    vm.roll(vm.getBlockNumber() + CHUNK_COMMIT_EXPIRY_BLOCKS + 1);
    vm.warp(fullyGrownAt + 1);
    vm.prank(alice);
    world.growSeed(aliceEntityId, cropCoord);

    // Set up chunk commitment for randomness when mining
    Vec3 chunkCoord = cropCoord.toChunkCoord();
    vm.prank(alice);
    world.chunkCommit(aliceEntityId, chunkCoord);
    // Move forward 2 blocks to make the commitment valid
    vm.roll(vm.getBlockNumber() + 2);

    // Mine the crop
    vm.prank(alice);
    world.mineUntilDestroyed(aliceEntityId, cropCoord, "");

    // Now we get wheat and seeds
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 1);
    // TODO: test randomness
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeed, 0);
  }
}
