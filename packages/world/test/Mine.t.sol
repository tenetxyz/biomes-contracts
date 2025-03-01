// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ExploredChunk } from "../src/codegen/tables/ExploredChunk.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex } from "../src/codegen/tables/ExploredChunkByIndex.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerPosition } from "../src/codegen/tables/PlayerPosition.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, SmartChestObjectID, TextSignObjectID, AnyOreObjectID, ObjectAmount } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract MineTest is BiomesTest {
  using VoxelCoordLib for *;

  function testMineTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine terrain with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineTerrainRequiresMultipleMines() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine terrain with hand, partially mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == mineObjectTypeId, "Mine entity is not mined object");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");

    localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    aliceEnergyBefore = Energy.getEnergy(aliceEntityId);

    vm.prank(alice);
    world.mine(mineCoord);

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineOre() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );

    setTerrainAtCoord(mineCoord, AnyOreObjectID);
    uint8 o = TerrainLib.getBlockType(mineCoord);
    assertTrue(ObjectTypeId.wrap(uint16(o)) == AnyOreObjectID, "Didn't work");
    ObjectTypeMetadata.setMass(AnyOreObjectID, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(!mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, AnyOreObjectID), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    ObjectAmount[] memory oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Existing ores in inventory");
    assertEq(TotalMinedOreCount.get(), 0, "Mined ore count is not 0");

    vm.prank(alice);
    world.oreChunkCommit(mineCoord.toChunk());

    vm.roll(vm.getBlockNumber() + 2);

    vm.prank(alice);
    startGasReport("mine Ore with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, AnyOreObjectID), 0, "Did not get a specific ore");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 1, "No ores in inventory");
    assertEq(oreAmounts[0].amount, 1, "Did not get exactly one ore");
    assertEq(MinedOreCount.get(oreAmounts[0].objectTypeId), 1, "Mined ore count was not updated");
    assertEq(TotalMinedOreCount.get(), 1, "Total mined ore count was not updated");

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineOreMultipleMines() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );

    setTerrainAtCoord(mineCoord, AnyOreObjectID);
    uint8 o = TerrainLib.getBlockType(mineCoord);
    assertTrue(ObjectTypeId.wrap(uint16(o)) == AnyOreObjectID, "Didn't work");
    ObjectTypeMetadata.setMass(AnyOreObjectID, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(!mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, AnyOreObjectID), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    ObjectAmount[] memory oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Existing ores in inventory");
    assertEq(TotalMinedOreCount.get(), 0, "Mined ore count is not 0");

    vm.prank(alice);
    world.oreChunkCommit(mineCoord.toChunk());

    vm.roll(vm.getBlockNumber() + 2);

    vm.prank(alice);
    startGasReport("mine Ore with hand, partially mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AnyOreObjectID, "Mine entity is not any ore");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    oreAmounts = TestUtils.inventoryGetOreAmounts(aliceEntityId);
    assertEq(oreAmounts.length, 0, "Got an ore in inventory");
    assertEq(TotalMinedOreCount.get(), 0, "Total mined ore count was increased");

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = GrassObjectID;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine non-terrain with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineMultiSize() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = TextSignObjectID;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);
    Vec3 topCoord = vec3(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    EntityId topEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertTrue(ObjectType.get(mineEntityId) == mineObjectTypeId, "Mine entity is not mine object type");
    assertTrue(ObjectType.get(topEntityId) == mineObjectTypeId, "Top entity is not air");
    assertTrue(
      Mass.getMass(mineEntityId) == ObjectTypeMetadata.getMass(mineObjectTypeId),
      "Mine entity mass is not correct"
    );
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine multi-size with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertTrue(ObjectType.get(topEntityId) == AirObjectID, "Top entity is not air");
    assertEq(Mass.getMass(mineEntityId), 0, "Mine entity mass is not correct");
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");

    // Mine again but with a non-base coord
    vm.prank(alice);
    world.build(TextSignObjectID, mineCoord);

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    topEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    vm.prank(alice);
    world.mine(topCoord);

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertTrue(ObjectType.get(topEntityId) == AirObjectID, "Top entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
  }

  function testMineFailsIfInvalidBlock() public {
    (address alice, , Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = AirObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Object is not mineable");
    world.mine(mineCoord);

    setObjectAtCoord(mineCoord, WaterObjectID);

    vm.prank(alice);
    vm.expectRevert("Object is not mineable");
    world.mine(mineCoord);
  }

  function testMineFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x + MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, playerCoord.y, playerCoord.z);
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.mine(mineCoord);

    mineCoord = vec3(WORLD_BORDER_LOW_X - 1, playerCoord.y, playerCoord.z);
    setObjectAtCoord(mineCoord, DirtObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot mine outside the world border");
    world.mine(mineCoord);

    mineCoord = vec3(playerCoord.x - 1, playerCoord.y, playerCoord.z);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.mine(mineCoord);
  }

  function testMineFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
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

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    TestUtils.addToInventoryCount(
      aliceEntityId,
      PlayerObjectID,
      mineObjectTypeId,
      ObjectTypeMetadata.getMaxInventorySlots(PlayerObjectID) * ObjectTypeMetadata.getStackable(mineObjectTypeId)
    );
    assertEq(
      InventorySlots.get(aliceEntityId),
      ObjectTypeMetadata.getMaxInventorySlots(PlayerObjectID),
      "Inventory slots is not max"
    );

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.mine(mineCoord);
  }

  function testMineFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.expectRevert("Player does not exist");
    world.mine(mineCoord);
  }

  function testMineFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.mine(mineCoord);
  }

  function testMineFailsIfHasEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 mineCoord = vec3(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = ForceFieldObjectID;
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
