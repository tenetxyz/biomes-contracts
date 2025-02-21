// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
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
import { PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE } from "../src/Constants.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

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

    vm.stopPrank();
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

    vm.stopPrank();
  }

  function testMineNonTerrain() public {}

  function testMineMultiSize() public {}

  function testMineInForceField() public {}

  function testMineFailsIfForceField() public {}

  function testMineFailsIfInvalidBlock() public {}

  function testMineFailsIfInvalidCoord() public {}

  function testMineFailsIfNotEnoughEnergy() public {}

  function testMineFailsIfInventoryFull() public {}

  function testMineFailsIfLoggedOut() public {}

  function testMineFailsIfNoPlayer() public {}

  function testMineFailsIfHasEnergy() public {}
}
