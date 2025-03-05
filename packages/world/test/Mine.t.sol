// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { MinedOrePosition, ExploredChunk, ExploredChunkByIndex, ForceField, LocalEnergyPool, ReversePosition, PlayerPosition, Position, OreCommitment } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectAmount } from "../src/ObjectTypeLib.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract MineTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function testMineTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine terrain with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineTerrainRequiresMultipleMines() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine terrain with hand, partially mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == mineObjectTypeId, "Mine entity is not mined object");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);

    beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.mine(mineCoord);

    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineRequiresMultipleMinesUntilDestroyed() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.mineUntilDestroyed(mineCoord);

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineOre() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());

    setTerrainAtCoord(mineCoord, ObjectTypes.AnyOre);
    uint8 o = TerrainLib.getBlockType(mineCoord);
    assertTrue(ObjectTypeId.wrap(uint16(o)) == ObjectTypes.AnyOre, "Didn't work");
    ObjectTypeMetadata.setMass(ObjectTypes.AnyOre, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(!mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, ObjectTypes.AnyOre, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    ObjectAmount[] memory oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Existing ores in inventory");
    assertEq(TotalMinedOreCount.get(), 0, "Mined ore count is not 0");

    vm.prank(alice);
    world.oreChunkCommit(mineCoord.toChunkCoord());

    vm.roll(vm.getBlockNumber() + 2);

    vm.prank(alice);
    startGasReport("mine Ore with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, ObjectTypes.AnyOre, 0);
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 1, "No ores in inventory");
    assertEq(oreAmounts[0].amount, 1, "Did not get exactly one ore");
    assertEq(MinedOreCount.get(oreAmounts[0].objectTypeId), 1, "Mined ore count was not updated");
    assertEq(TotalMinedOreCount.get(), 1, "Total mined ore count was not updated");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineOreMultipleMines() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());

    setTerrainAtCoord(mineCoord, ObjectTypes.AnyOre);
    uint8 o = TerrainLib.getBlockType(mineCoord);
    assertTrue(ObjectTypeId.wrap(uint16(o)) == ObjectTypes.AnyOre, "Didn't work");
    ObjectTypeMetadata.setMass(ObjectTypes.AnyOre, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(!mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, ObjectTypes.AnyOre, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    ObjectAmount[] memory oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Existing ores in inventory");
    assertEq(TotalMinedOreCount.get(), 0, "Mined ore count is not 0");

    vm.prank(alice);
    world.oreChunkCommit(mineCoord.toChunkCoord());

    vm.roll(vm.getBlockNumber() + 2);

    vm.prank(alice);
    startGasReport("mine Ore with hand, partially mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.AnyOre, "Mine entity is not any ore");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Got an ore in inventory");
    assertEq(TotalMinedOreCount.get(), 0, "Total mined ore count was increased");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
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
    world.mine(mineCoord);
    endGasReport();

    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
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
    assertTrue(ObjectType.get(mineEntityId) == mineObjectTypeId, "Mine entity is not mine object type");
    assertTrue(ObjectType.get(topEntityId) == mineObjectTypeId, "Top entity is not air");
    assertTrue(
      Mass.getMass(mineEntityId) == ObjectTypeMetadata.getMass(mineObjectTypeId),
      "Mine entity mass is not correct"
    );
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine multi-size with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
    assertTrue(ObjectType.get(topEntityId) == ObjectTypes.Air, "Top entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not correct");
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);

    // Mine again but with a non-base coord
    vm.prank(alice);
    world.build(ObjectTypes.TextSign, mineCoord);

    mineEntityId = ReversePosition.get(mineCoord);
    topEntityId = ReversePosition.get(topCoord);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    vm.prank(alice);
    world.mine(topCoord);

    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Mine entity is not air");
    assertTrue(ObjectType.get(topEntityId) == ObjectTypes.Air, "Top entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
  }

  function testMineFailsIfInvalidBlock() public {
    (address alice, , Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());
    ObjectTypeId mineObjectTypeId = ObjectTypes.Air;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Object is not mineable");
    world.mine(mineCoord);

    setObjectAtCoord(mineCoord, ObjectTypes.Water);

    vm.prank(alice);
    vm.expectRevert("Object is not mineable");
    world.mine(mineCoord);
  }

  function testMineFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.mine(mineCoord);

    mineCoord = vec3(WORLD_BORDER_LOW_X - 1, playerCoord.y(), playerCoord.z());
    setObjectAtCoord(mineCoord, ObjectTypes.Dirt);

    vm.prank(alice);
    vm.expectRevert("Cannot mine outside the world border");
    world.mine(mineCoord);

    mineCoord = playerCoord - vec3(1, 0, 0);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.mine(mineCoord);
  }

  function testMineFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    Energy.set(
      aliceEntityId,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1, drainRate: 0, accDepletedTime: 0 })
    );

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.mine(mineCoord);
  }

  function testMineFailsIfInventoryFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    TestUtils.addToInventoryCount(
      aliceEntityId,
      ObjectTypes.Player,
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
    world.mine(mineCoord);
  }

  function testMineFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.expectRevert("Player does not exist");
    world.mine(mineCoord);
  }

  function testMineFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.Dirt;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.mine(mineCoord);
  }

  function testMineFailsIfHasEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = playerCoord + vec3(1, 0, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypes.ForceField;
    EntityId mineEntityId = setObjectAtCoord(mineCoord, mineObjectTypeId);
    Energy.set(
      mineEntityId,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000, drainRate: 0, accDepletedTime: 0 })
    );

    vm.prank(alice);
    vm.expectRevert("Cannot mine a machine that has energy");
    world.mine(mineCoord);
  }
}
