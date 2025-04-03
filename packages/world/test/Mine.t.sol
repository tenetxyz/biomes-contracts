// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";

import { EntityId } from "../src/EntityId.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";

import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { ResourceCount } from "../src/codegen/tables/ResourceCount.sol";

import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { ResourceCount } from "../src/codegen/tables/ResourceCount.sol";
import { BurnedResourceCount } from "../src/codegen/tables/BurnedResourceCount.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { DustTest } from "./DustTest.sol";

import {
  ChunkCommitment,
  LocalEnergyPool,
  MovablePosition,
  Position,
  ResourcePosition,
  ReverseMovablePosition,
  ReversePosition
} from "../src/utils/Vec3Storage.sol";

import { CHUNK_SIZE, MAX_ENTITY_INFLUENCE_HALF_WIDTH, MINE_ENERGY_COST } from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectAmount } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract MineTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testMineTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine terrain with hand, entirely mined");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineTerrainRequiresMultipleMines() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine terrain with hand, partially mined");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), mineObjectTypeId, "Mine entity is not mined object");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);

    beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.mine(aliceEntityId, mineCoord, "");

    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineRequiresMultipleMinesUntilDestroyed() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.mineUntilDestroyed(aliceEntityId, mineCoord, "");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineResource() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());

    setTerrainAtCoord(mineCoord, ObjectTypes.AnyOre);
    ObjectTypeId o = TerrainLib.getBlockType(mineCoord);
    assertEq(o, ObjectTypes.AnyOre, "Didn't work");
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, ObjectTypes.AnyOre, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    ObjectAmount[] memory oreAmounts = inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Existing ores in inventory");
    assertEq(ResourceCount.get(ObjectTypes.AnyOre), 0, "Mined resource count is not 0");

    vm.prank(alice);
    world.chunkCommit(aliceEntityId, mineCoord.toChunkCoord());

    vm.roll(vm.getBlockNumber() + 2);

    vm.prank(alice);
    startGasReport("mine Ore with hand, entirely mined");
    world.mineUntilDestroyed(aliceEntityId, mineCoord, "");
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Entity should be air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertInventoryHasObject(aliceEntityId, ObjectTypes.AnyOre, 0);
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    oreAmounts = inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 1, "No ores in inventory");
    assertEq(oreAmounts[0].amount, 1, "Did not get exactly one ore");
    assertEq(ResourceCount.get(oreAmounts[0].objectTypeId), 1, "Resource count was not updated");
    assertEq(ResourceCount.get(ObjectTypes.AnyOre), 1, "Total resource count was not updated");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineResourceTypeIsFixedAfterPartialMine() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());

    setTerrainAtCoord(mineCoord, ObjectTypes.AnyOre);
    ObjectTypeId o = TerrainLib.getBlockType(mineCoord);
    assertEq(o, ObjectTypes.AnyOre, "Didn't work");
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");

    vm.prank(alice);
    world.chunkCommit(aliceEntityId, mineCoord.toChunkCoord());

    vm.roll(vm.getBlockNumber() + 2);

    // First mining attempt - partially mines the ore
    vm.prank(alice);
    startGasReport("mine Ore with hand, partially mined");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    // Check that the type has been set to specific resource
    mineEntityId = ReversePosition.get(mineCoord);
    ObjectTypeId resourceType = ObjectType.get(mineEntityId);
    assertNeq(resourceType, ObjectTypes.AnyOre, "Resource type should have been set to a specific resource");

    // Verify mass has been set to the resource's
    uint128 mass = Mass.getMass(mineEntityId);
    uint128 expectedMass = ObjectTypeMetadata.getMass(resourceType) - MINE_ENERGY_COST;
    assertEq(mass, expectedMass, "Mass was not set correctly");

    // Roll forward many blocks to ensure the commitment expires
    vm.roll(vm.getBlockNumber() + 1000);

    // Try to mine again after commitment expired
    vm.prank(alice);
    world.mine(aliceEntityId, mineCoord, "");

    // Verify the resource type hasn't changed even though commitment expired
    mineEntityId = ReversePosition.get(mineCoord);
    resourceType = ObjectType.get(mineEntityId);
    assertNeq(resourceType, ObjectTypes.AnyOre, "Resource type should remain consistent after commitment expired");

    // Verify mass has been set to the resource's
    mass = Mass.getMass(mineEntityId);
    expectedMass -= MINE_ENERGY_COST;
    assertEq(mass, expectedMass, "Mass should decrease after another mining attempt");
  }

  function testMineNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine non-terrain with hand, entirely mined");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineMultiSize() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypes.TextSign;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);
    Vec3 topCoord = mineCoord + vec3(0, 1, 0);
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    EntityId topEntityId = ReversePosition.get(topCoord);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertEq(ObjectType.get(mineEntityId), mineObjectTypeId, "Mine entity is not mine object type");
    assertEq(ObjectType.get(topEntityId), mineObjectTypeId, "Top entity is not air");
    assertEq(
      Mass.getMass(mineEntityId), ObjectTypeMetadata.getMass(mineObjectTypeId), "Mine entity mass is not correct"
    );
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine multi-size with hand, entirely mined");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertEq(ObjectType.get(topEntityId), ObjectTypes.Air, "Top entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not correct");
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);

    // Mine again but with a non-base coord
    vm.prank(alice);
    world.build(aliceEntityId, ObjectTypes.TextSign, mineCoord, "");

    mineEntityId = ReversePosition.get(mineCoord);
    topEntityId = ReversePosition.get(topCoord);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    vm.prank(alice);
    world.mine(aliceEntityId, topCoord, "");

    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not 0");
    assertEq(ObjectType.get(topEntityId), ObjectTypes.Air, "Top entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
  }

  function testMineFailsIfInvalidBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypes.Air;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Object is not mineable");
    world.mine(aliceEntityId, mineCoord, "");

    setObjectAtCoord(mineCoord, ObjectTypes.Water);

    vm.prank(alice);
    vm.expectRevert("Object is not mineable");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.mine(aliceEntityId, mineCoord, "");

    mineCoord = playerCoord - vec3(CHUNK_SIZE / 2 + 1, 0, 0);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    Energy.set(aliceEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1, drainRate: 0 }));

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFatal() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Set player energy to exactly enough for one mine operation
    uint128 exactEnergy = MINE_ENERGY_COST;
    Energy.set(
      aliceEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: exactEnergy, drainRate: 0 })
    );

    vm.prank(alice);
    world.mine(aliceEntityId, mineCoord, "");

    // Check energy is zero
    assertEq(Energy.getEnergy(aliceEntityId), 0, "Player energy is not 0");

    // Verify the player entity is still registered to the address, but removed from the grid
    assertEq(Player.get(alice), aliceEntityId, "Player entity was deleted");
    assertEq(MovablePosition.get(aliceEntityId), vec3(0, 0, 0), "Player position was not deleted");
    assertEq(ReverseMovablePosition.get(playerCoord), EntityId.wrap(0), "Player reverse position was not deleted");
    assertEq(
      ReverseMovablePosition.get(playerCoord + vec3(0, 1, 0)),
      EntityId.wrap(0),
      "Player reverse position at head was not deleted"
    );
  }

  function testMineFailsIfInventoryFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    TestInventoryUtils.addToInventory(
      aliceEntityId,
      mineObjectTypeId,
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player) * ObjectTypeMetadata.getStackable(mineObjectTypeId)
    );
    assertEq(
      InventorySlots.get(aliceEntityId),
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player),
      "Inventory slots is not max"
    );

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.expectRevert("Caller not allowed");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFailsIfHasEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.ForceField;
    EntityId mineEntityId = setObjectAtCoord(mineCoord, mineObjectTypeId);
    Energy.set(mineEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000, drainRate: 0 }));

    vm.prank(alice);
    vm.expectRevert("Cannot mine a machine that has energy");
    world.mine(aliceEntityId, mineCoord, "");
  }
}
