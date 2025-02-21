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
import { Position } from "../src/codegen/tables/Position.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
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
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, SmartChestObjectID, TextSignObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { testInventoryObjectsHasObjectType, testAddToInventoryCount } from "./utils/TestUtils.sol";

contract MineTest is BiomesTest {
  using VoxelCoordLib for *;

  function testMineTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnFlatChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(!mineEntityId.exists(), "Mine entity already exists");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine terrain with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 1, "Inventory count is not 1");
    assertTrue(InventorySlots.get(aliceEntityId) == 1, "Inventory slots is not 1");
    assertTrue(
      testInventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertTrue(Energy.getEnergy(aliceEntityId) == aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineTerrainRequiresMultipleMines() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnFlatChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction * 2));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(!mineEntityId.exists(), "Mine entity already exists");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine terrain with hand, partially mined");
    world.mine(mineCoord);
    endGasReport();

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == mineObjectTypeId, "Mine entity is not air");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 0, "Inventory count is not 0");
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertTrue(Energy.getEnergy(aliceEntityId) == aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");

    localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    aliceEnergyBefore = Energy.getEnergy(aliceEntityId);

    vm.prank(alice);
    world.mine(mineCoord);

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 1, "Inventory count is not 1");
    assertTrue(InventorySlots.get(aliceEntityId) == 1, "Inventory slots is not 1");
    assertTrue(
      testInventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertTrue(Energy.getEnergy(aliceEntityId) == aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = GrassObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine non-terrain with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 1, "Inventory count is not 1");
    assertTrue(InventorySlots.get(aliceEntityId) == 1, "Inventory slots is not 1");
    assertTrue(
      testInventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertTrue(Energy.getEnergy(aliceEntityId) == aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineMultiSize() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = TextSignObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    VoxelCoord memory topCoord = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    EntityId topEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    assertTrue(mineEntityId.exists(), "Mine entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine multi-size with hand, entirely mined");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertTrue(ObjectType.get(topEntityId) == AirObjectID, "Top entity is not air");
    assertTrue(InventoryCount.get(aliceEntityId, mineObjectTypeId) == 1, "Inventory count is not 1");
    assertTrue(InventorySlots.get(aliceEntityId) == 1, "Inventory slots is not 1");
    assertTrue(
      testInventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertTrue(Energy.getEnergy(aliceEntityId) == aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineFailsIfInvalidBlock() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
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
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x + MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1,
      playerCoord.y,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.mine(mineCoord);

    mineCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, playerCoord.y, playerCoord.z);
    setObjectAtCoord(mineCoord, DirtObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot mine outside the world border");
    world.mine(mineCoord);
  }

  function testMineFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    Energy.set(aliceEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0 }));

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.mine(mineCoord);
  }

  function testMineFailsIfInventoryFull() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    testAddToInventoryCount(
      aliceEntityId,
      PlayerObjectID,
      mineObjectTypeId,
      ObjectTypeMetadata.getMaxInventorySlots(PlayerObjectID) * ObjectTypeMetadata.getStackable(mineObjectTypeId)
    );
    assertTrue(
      InventorySlots.get(aliceEntityId) == ObjectTypeMetadata.getMaxInventorySlots(PlayerObjectID),
      "Inventory slots is not max"
    );

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.mine(mineCoord);
  }

  function testMineFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.expectRevert("Player does not exist");
    world.mine(mineCoord);
  }

  function testMineFailsIfLoggedOut() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = DirtObjectID;
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    vm.prank(alice);
    world.logoffPlayer();

    vm.prank(alice);
    vm.expectRevert("Player isn't logged in");
    world.mine(mineCoord);
  }

  function testMineFailsIfHasEnergy() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = spawnPlayerOnAirChunk();

    VoxelCoord memory mineCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL,
      playerCoord.z
    );
    ObjectTypeId mineObjectTypeId = ForceFieldObjectID;
    EntityId mineEntityId = setObjectAtCoord(mineCoord, mineObjectTypeId);
    Energy.set(mineEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000 }));

    vm.prank(alice);
    vm.expectRevert("Cannot mine a machine that has energy");
    world.mine(mineCoord);
  }
}
