// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { LocalEnergyPool } from "../src/utils/Vec3Storage.sol";
import { SeedGrowth } from "../src/codegen/tables/SeedGrowth.sol";

import { ReversePosition, PlayerPosition } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib, TreeData } from "../src/ObjectTypeLib.sol";
import { PLAYER_TILL_ENERGY_COST, PLAYER_BUILD_ENERGY_COST, PLAYER_MINE_ENERGY_COST, MAX_PLAYER_INFLUENCE_HALF_WIDTH, CHUNK_SIZE } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { EntityId } from "../src/EntityId.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract FarmingTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function testTillDirt() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);
    EntityId dirtEntityId = ReversePosition.get(dirtCoord);
    assertFalse(dirtEntityId.exists(), "Dirt entity already exists");

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("till dirt");
    world.till(dirtCoord);
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
    world.equip(hoeEntityId);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("till grass");
    world.till(grassCoord);
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
      world.equip(hoeEntityId);

      vm.prank(alice);
      world.till(testCoord);

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
    world.equip(hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Not dirt or grass");
    world.till(nonDirtCoord);
  }

  function testTillFailsIfNoHoeEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    // No hoe equipped

    vm.prank(alice);
    vm.expectRevert("Must equip a hoe");
    world.till(dirtCoord);

    // Equipped but not a hoe
    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.SilverPick);
    vm.prank(alice);
    world.equip(hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Must equip a hoe");
    world.till(dirtCoord);
  }

  function testTillFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.till(dirtCoord);
  }

  function testTillFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    // Set player energy to less than required
    uint128 toolMass = 0; // Assuming tool mass is 0 for simplicity
    uint128 energyCost = PLAYER_TILL_ENERGY_COST + massToEnergy(toolMass);
    Energy.set(
      aliceEntityId,
      EnergyData({
        lastUpdatedTime: uint128(block.timestamp),
        energy: energyCost - 1,
        drainRate: 0,
        accDepletedTime: 0
      })
    );

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.till(dirtCoord);
  }

  function testPlantWheatSeeds() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeeds, 1);

    // Check initial local energy pool
    uint128 initialLocalEnergy = LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord());
    uint128 seedEnergy = ObjectTypeMetadata.getEnergy(ObjectTypes.WheatSeeds);

    // Plant wheat seeds
    vm.prank(alice);
    world.build(ObjectTypes.WheatSeeds, farmlandCoord + vec3(0, 1, 0));

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(farmlandCoord + vec3(0, 1, 0));
    assertTrue(cropEntityId.exists(), "Crop entity doesn't exist after planting");
    assertEq(ObjectType.get(cropEntityId), ObjectTypes.WheatSeeds, "Wheat seeds were not planted correctly");

    // Verify energy was taken from local pool
    assertEq(
      LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord()),
      initialLocalEnergy + PLAYER_BUILD_ENERGY_COST - seedEnergy,
      "Energy not correctly taken from local pool"
    );

    // Verify build time was set
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);
    assertTrue(fullyGrownAt > 0, "FullyGrownAt not set correctly");
    assertEq(
      fullyGrownAt,
      uint128(block.timestamp) + ObjectTypes.WheatSeeds.timeToGrow(),
      "Incorrect fullyGrownAt set"
    );

    // Verify seeds were removed from inventory
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 0);
  }

  function testPlantSeedsFailsIfNotOnWetFarmland() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeeds, 1);

    // Try to plant on dirt (not farmland)
    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    vm.prank(alice);
    vm.expectRevert("Crop seeds need wet farmland");
    world.build(ObjectTypes.WheatSeeds, dirtCoord + vec3(0, 1, 0));

    // Try to plant on farmland (not wet)
    Vec3 farmlandCoord = vec3(playerCoord.x() + 2, 0, playerCoord.z());
    setTerrainAtCoord(farmlandCoord, ObjectTypes.Farmland);

    vm.prank(alice);
    vm.expectRevert("Crop seeds need wet farmland");
    world.build(ObjectTypes.WheatSeeds, farmlandCoord + vec3(0, 1, 0));
  }

  function testHarvestMatureWheatCrop() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeeds, 1);

    Vec3 cropCoord = farmlandCoord + vec3(0, 1, 0);

    // Plant wheat seeds
    vm.prank(alice);
    world.build(ObjectTypes.WheatSeeds, cropCoord);

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(cropCoord);
    assertTrue(cropEntityId.exists(), "Crop entity doesn't exist after planting");

    // Get growth time required for the crop
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Advance time beyond the growth period
    vm.warp(fullyGrownAt);
    vm.prank(alice);
    world.growSeed(cropCoord);

    // Check local energy pool before harvesting
    uint128 initialLocalEnergy = LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord());

    // Harvest the crop
    vm.prank(alice);
    world.mineUntilDestroyed(farmlandCoord + vec3(0, 1, 0));

    // Verify wheat and seeds were obtained
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 1);

    // Verify crop no longer exists
    assertEq(ObjectType.get(cropEntityId), ObjectTypes.Air, "Crop wasn't removed after harvesting");

    // Verify local energy pool hasn't changed (energy not returned since crop was fully grown)
    assertEq(
      LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord()),
      initialLocalEnergy + PLAYER_MINE_ENERGY_COST,
      "Local energy pool shouldn't change after harvesting mature crop"
    );
  }

  function testHarvestImmatureWheatCrop() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeeds, 1);

    Vec3 cropCoord = farmlandCoord + vec3(0, 1, 0);

    // Get initial energy
    uint128 seedEnergy = ObjectTypeMetadata.getEnergy(ObjectTypes.WheatSeeds);

    // Plant wheat seeds
    vm.prank(alice);
    world.build(ObjectTypes.WheatSeeds, cropCoord);

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(cropCoord);
    assertTrue(cropEntityId.exists(), "Crop entity doesn't exist after planting");

    // Get growth time required for the crop
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Advance time but not enough for full growth
    vm.warp(fullyGrownAt - 1); // 1 second before full growth

    // Update player's energy and transfer to pool
    world.activatePlayer(alice);

    // Check local energy pool before harvesting
    uint128 beforeHarvestEnergy = LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord());

    // Harvest the crop
    vm.prank(alice);
    world.mineUntilDestroyed(cropCoord);

    // Verify original seeds were returned (not wheat)
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 0);

    // Verify crop no longer exists
    assertEq(ObjectType.get(cropEntityId), ObjectTypes.Air, "Crop wasn't removed after harvesting");

    // Verify energy was returned to local pool
    assertEq(
      LocalEnergyPool.get(farmlandCoord.toLocalEnergyPoolShardCoord()),
      beforeHarvestEnergy + seedEnergy + PLAYER_MINE_ENERGY_COST,
      "Energy not correctly returned to local pool"
    );
  }

  function testMiningFescueGrassDropsWheatSeeds() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Create FescueGrass
    Vec3 grassCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(grassCoord, ObjectTypes.FescueGrass);

    // Verify no wheat seeds in inventory
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 0);

    // Harvest the FescueGrass
    vm.prank(alice);
    world.mineUntilDestroyed(grassCoord);

    // Verify wheat seeds were obtained
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 1);
  }

  function testCropGrowthLifecycle() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 farmlandCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(farmlandCoord, ObjectTypes.WetFarmland);

    // Add wheat seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.WheatSeeds, 1);

    Vec3 cropCoord = farmlandCoord + vec3(0, 1, 0);
    // Plant wheat seeds
    vm.prank(alice);
    world.build(ObjectTypes.WheatSeeds, cropCoord);

    // Verify seeds were planted
    EntityId cropEntityId = ReversePosition.get(cropCoord);
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Mid-growth - Try harvesting before fully grown
    vm.warp(fullyGrownAt - 1);

    vm.prank(alice);
    vm.expectRevert("Seed cannot be grown yet");
    world.growSeed(cropCoord);

    // Mine the crop
    vm.prank(alice);
    world.mineUntilDestroyed(cropCoord);

    // We get seeds back, not wheat
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 0);

    // Reset test by planting again
    vm.prank(alice);
    world.build(ObjectTypes.WheatSeeds, cropCoord);

    cropEntityId = ReversePosition.get(cropCoord);
    fullyGrownAt = SeedGrowth.getFullyGrownAt(cropEntityId);

    // Full growth - Warp past the full growth time
    vm.warp(fullyGrownAt + 1);
    vm.prank(alice);
    world.growSeed(cropCoord);

    // Mine the crop
    vm.prank(alice);
    world.mineUntilDestroyed(cropCoord);

    // Now we get wheat and seeds
    assertInventoryHasObject(aliceEntityId, ObjectTypes.WheatSeeds, 1);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Wheat, 1);
  }

  // Tree tests

  function testPlantTreeSeed() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(dirtCoord, ObjectTypes.Dirt);

    // Add oak seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Check initial local energy pool
    uint128 initialLocalEnergy = LocalEnergyPool.get(dirtCoord.toLocalEnergyPoolShardCoord());
    uint128 seedEnergy = ObjectTypeMetadata.getEnergy(ObjectTypes.OakSeed);

    // Plant oak seeds
    Vec3 seedCoord = dirtCoord + vec3(0, 1, 0);
    vm.prank(alice);
    startGasReport("plant tree seed");
    world.build(ObjectTypes.OakSeed, seedCoord);
    endGasReport();

    // Verify seeds were planted
    EntityId seedEntityId = ReversePosition.get(seedCoord);
    assertTrue(seedEntityId.exists(), "Seed entity doesn't exist after planting");
    assertEq(ObjectType.get(seedEntityId), ObjectTypes.OakSeed, "Oak seed was not planted correctly");

    // Verify energy was taken from local pool
    assertEq(
      LocalEnergyPool.get(dirtCoord.toLocalEnergyPoolShardCoord()),
      initialLocalEnergy + PLAYER_BUILD_ENERGY_COST - seedEnergy,
      "Energy not correctly taken from local pool"
    );

    // Verify growth time was set
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(seedEntityId);
    assertEq(fullyGrownAt, uint128(block.timestamp) + ObjectTypes.OakSeed.timeToGrow(), "Incorrect fullyGrownAt set");

    // Verify seeds were removed from inventory
    assertInventoryHasObject(aliceEntityId, ObjectTypes.OakSeed, 0);
  }

  function testPlantTreeSeedFailsIfNotOnDirtOrGrass() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Add oak seeds to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Try to plant on stone
    Vec3 stoneCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(stoneCoord, ObjectTypes.Stone);

    vm.prank(alice);
    vm.expectRevert("Tree seeds need dirt or grass");
    world.build(ObjectTypes.OakSeed, stoneCoord + vec3(0, 1, 0));

    // Try to plant on farmland
    Vec3 farmlandCoord = vec3(playerCoord.x() + 2, 0, playerCoord.z());
    setTerrainAtCoord(farmlandCoord, ObjectTypes.Farmland);

    vm.prank(alice);
    vm.expectRevert("Tree seeds need dirt or grass");
    world.build(ObjectTypes.OakSeed, farmlandCoord + vec3(0, 1, 0));
  }

  function testTreeGrowthWithSpace() public {
    (address alice, EntityId aliceEntityId, ) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(CHUNK_SIZE / 2, 0, CHUNK_SIZE / 3);
    Vec3 seedCoord = dirtCoord + vec3(0, 1, 0);
    setObjectAtCoord(dirtCoord, ObjectTypes.Dirt);

    // Add oak seed to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Plant oak seed
    vm.prank(alice);
    world.build(ObjectTypes.OakSeed, seedCoord);

    // Verify seed was planted
    EntityId seedEntityId = ReversePosition.get(seedCoord);
    assertTrue(seedEntityId.exists(), "Seed entity doesn't exist after planting");

    // Get full grown time
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(seedEntityId);

    // Advance time to when the tree can grow
    vm.warp(fullyGrownAt + 1);

    // Grow the tree
    vm.prank(alice);
    startGasReport("grow oak tree");
    world.growSeed(seedCoord);
    endGasReport();

    // Verify the seed is now a log
    assertEq(ObjectType.get(seedEntityId), ObjectTypes.OakLog, "Seed was not converted to log");

    // Get tree data to check trunkHeight
    TreeData memory treeData = ObjectTypes.OakSeed.getTreeData();
    int32 height = int32(uint32(treeData.trunkHeight));

    // Verify trunk exists
    for (int32 i = 0; i < height; i++) {
      Vec3 checkCoord = seedCoord + vec3(0, i, 0);
      EntityId logEntityId = ReversePosition.get(checkCoord);
      assertTrue(logEntityId.exists(), "Log entity doesn't exist");
      assertEq(ObjectType.get(logEntityId), ObjectTypes.OakLog, "Entity is not oak log");
    }

    // Verify leaves exist in canopy area (test a few sample points)
    int32 canopyStart = int32(treeData.canopyStart);

    // Check some expected leaf positions
    Vec3[] memory leafPositions = new Vec3[](5);
    leafPositions[0] = seedCoord + vec3(1, canopyStart + 1, 0);
    leafPositions[1] = seedCoord + vec3(-1, canopyStart + 1, 0);
    leafPositions[2] = seedCoord + vec3(0, canopyStart + 1, 1);
    leafPositions[3] = seedCoord + vec3(0, canopyStart + 1, -1);
    leafPositions[4] = seedCoord + vec3(0, height, 0); // Top leaf

    for (uint256 i = 0; i < leafPositions.length; i++) {
      EntityId leafEntityId = ReversePosition.get(leafPositions[i]);
      assertTrue(leafEntityId.exists(), "Leaf entity doesn't exist");
      assertEq(ObjectType.get(leafEntityId), ObjectTypes.OakLeaf, "Entity is not oak leaf");
    }
  }

  function testTreeGrowthWithoutSpace() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 dirtCoord = vec3(playerCoord.x() + 5, 0, playerCoord.z());
    setObjectAtCoord(dirtCoord, ObjectTypes.Dirt);

    // Create an obstruction above the seed location
    Vec3 seedCoord = dirtCoord + vec3(0, 1, 0);
    Vec3 obstructionCoord = seedCoord + vec3(0, 2, 0);
    setObjectAtCoord(obstructionCoord, ObjectTypes.Stone);

    // Add oak seed to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Plant oak seed
    vm.prank(alice);
    world.build(ObjectTypes.OakSeed, seedCoord);

    // Verify seed was planted
    EntityId seedEntityId = ReversePosition.get(seedCoord);
    assertTrue(seedEntityId.exists(), "Seed entity doesn't exist after planting");

    // Get full grown time
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(seedEntityId);

    // Advance time to when the tree can grow
    vm.warp(fullyGrownAt + 1);

    // Grow the tree
    vm.prank(alice);
    startGasReport("grow tree with obstruction");
    world.growSeed(seedCoord);
    endGasReport();

    // Verify the seed is converted to log but remains a sapling (no additional blocks)
    assertEq(ObjectType.get(seedEntityId), ObjectTypes.OakLog, "Seed was not converted to log");

    // Verify no other logs or leaves were created
    Vec3 aboveObstruction = obstructionCoord + vec3(0, 1, 0);
    EntityId aboveEntity = ReversePosition.get(aboveObstruction);
    assertFalse(
      aboveEntity.exists() && ObjectType.get(aboveEntity) == ObjectTypes.OakLog,
      "Tree grew beyond obstruction"
    );
  }

  function testHarvestMatureTree() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(dirtCoord, ObjectTypes.Dirt);

    // Add oak seed to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Plant oak seed
    Vec3 seedCoord = dirtCoord + vec3(0, 1, 0);
    vm.prank(alice);
    world.build(ObjectTypes.OakSeed, seedCoord);

    // Verify seed was planted
    EntityId seedEntityId = ReversePosition.get(seedCoord);
    assertTrue(seedEntityId.exists(), "Seed entity doesn't exist after planting");

    // Get full grown time
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(seedEntityId);

    // Advance time to when the tree can grow
    vm.warp(fullyGrownAt + 1);

    // Grow the tree
    vm.prank(alice);
    world.growSeed(seedCoord);

    // Verify the seed is now a log
    assertEq(ObjectType.get(seedEntityId), ObjectTypes.OakLog, "Seed was not converted to log");

    // Harvest the mature tree log
    vm.prank(alice);
    startGasReport("harvest mature tree log");
    world.mineUntilDestroyed(seedCoord);
    endGasReport();

    // Verify log was obtained
    assertInventoryHasObject(aliceEntityId, ObjectTypes.OakLog, 1);
  }

  function testHarvestImmatureTreeSeed() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setObjectAtCoord(dirtCoord, ObjectTypes.Dirt);

    // Add oak seed to inventory
    TestInventoryUtils.addToInventory(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Plant oak seed
    Vec3 seedCoord = dirtCoord + vec3(0, 1, 0);
    vm.prank(alice);
    world.build(ObjectTypes.OakSeed, seedCoord);

    // Verify seed was planted
    EntityId seedEntityId = ReversePosition.get(seedCoord);
    assertTrue(seedEntityId.exists(), "Seed entity doesn't exist after planting");

    // Get initial energy
    uint128 seedEnergy = ObjectTypeMetadata.getEnergy(ObjectTypes.OakSeed);

    // Get full grown time
    uint128 fullyGrownAt = SeedGrowth.getFullyGrownAt(seedEntityId);

    // Advance time but not enough for full growth
    vm.warp(fullyGrownAt - 1); // 1 second before full growth

    // Update player's energy and transfer to pool
    world.activatePlayer(alice);

    // Check local energy pool before harvesting
    uint128 beforeHarvestEnergy = LocalEnergyPool.get(dirtCoord.toLocalEnergyPoolShardCoord());

    // Harvest the immature tree seed
    vm.prank(alice);
    startGasReport("harvest immature tree seed");
    world.mineUntilDestroyed(seedCoord);
    endGasReport();

    // Verify original seed was returned
    assertInventoryHasObject(aliceEntityId, ObjectTypes.OakSeed, 1);

    // Verify seed no longer exists at location
    assertEq(ObjectType.get(seedEntityId), ObjectTypes.Air, "Seed wasn't removed after harvesting");

    // Verify energy was returned to local pool
    assertEq(
      LocalEnergyPool.get(dirtCoord.toLocalEnergyPoolShardCoord()),
      beforeHarvestEnergy + seedEnergy + PLAYER_MINE_ENERGY_COST,
      "Energy not correctly returned to local pool"
    );
  }

  function testMineTreeLeaves() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Create an oak leaf directly
    Vec3 leafCoord = vec3(playerCoord.x() + 1, playerCoord.y() + 1, playerCoord.z());
    setObjectAtCoord(leafCoord, ObjectTypes.OakLeaf);

    EntityId leafEntityId = ReversePosition.get(leafCoord);
    assertTrue(leafEntityId.exists(), "Leaf entity doesn't exist");

    // Harvest the leaf
    vm.prank(alice);
    startGasReport("harvest tree leaf");
    world.mineUntilDestroyed(leafCoord);
    endGasReport();

    // Verify leaf was obtained
    assertInventoryHasObject(aliceEntityId, ObjectTypes.OakLeaf, 1);

    // Verify leaf entity no longer exists
    assertEq(ObjectType.get(leafEntityId), ObjectTypes.Air, "Leaf wasn't removed after harvesting");
  }
}
