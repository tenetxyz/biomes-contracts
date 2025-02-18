// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";

import { TerrainLib, VERSION_PADDING } from "../src/systems/libraries/TerrainLib.sol";
import { AirObjectID, DirtObjectID, SpawnTileObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord, ChunkCoord } from "../src/Types.sol";
import { CHUNK_SIZE, SPAWN_ENERGY } from "../src/Constants.sol";

contract SpawnTest is BiomesTest {
  function randomEntityId() internal returns (EntityId) {
    return EntityId.wrap(bytes32(vm.randomUint()));
  }

  function testRandomSpawn() public {
    uint256 blockNumber = block.number - 5;
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = world.getRandomSpawnCoord(blockNumber, alice, 0);

    // Set the spawn coord to Air
    EntityId entityId = randomEntityId();
    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, entityId);
    ObjectType.set(entityId, AirObjectID);

    // Set below entity to dirt so gravity doesn't apply
    EntityId belowEntityId = randomEntityId();
    ReversePosition.set(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z, belowEntityId);
    ObjectType.set(belowEntityId, DirtObjectID);

    // Give energy for local shard
    VoxelCoord memory shardCoord = spawnCoord.toSpawnShardCoord();
    LocalEnergyPool.set(shardCoord.x, 0, shardCoord.z, SPAWN_ENERGY);

    vm.prank(alice);
    EntityId playerEntityId = world.randomSpawn(blockNumber, spawnCoord.y);
    assertTrue(playerEntityId.exists());
  }

  function testRandomSpawnInMaintainance() public {
    WorldStatus.setInMaintenance(true);
    vm.expectRevert("Biomes is in maintenance mode. Try again later");
    world.randomSpawn(block.number, 0);
  }

  function testRandomSpawnFailsDueToOldBlock() public {
    uint256 pastBlock = block.number - 11;
    int32 y = 1;
    vm.expectRevert("Can only choose past 10 blocks");
    world.randomSpawn(pastBlock, y);
  }

  function testSpawn() public {
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = VoxelCoord(0, 0, 0);
    VoxelCoord memory spawnTileCoord = VoxelCoord(0, spawnCoord.y - 1, 0);

    // Set the spawn coord to Air
    EntityId spawnEntityId = randomEntityId();
    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, spawnEntityId);
    ObjectType.set(spawnEntityId, AirObjectID);

    // Set forcefield
    EntityId forceFieldEntityId = randomEntityId();
    VoxelCoord memory shardCoord = spawnTileCoord.toForceFieldShardCoord();
    ForceField.set(shardCoord.x, shardCoord.y, shardCoord.z, forceFieldEntityId);
    Energy.set(forceFieldEntityId, EnergyData({ energy: SPAWN_ENERGY, lastUpdatedTime: uint128(block.timestamp) }));

    // Set below entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z);
    ReversePosition.set(spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, SpawnTileObjectID);

    vm.prank(alice);
    EntityId playerEntityId = world.spawn(spawnTileEntityId, spawnCoord, "");
    assertTrue(playerEntityId.exists());
  }

  function testSpawnFailsIfNoSpawnTile() public {
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = VoxelCoord(0, 0, 0);

    // Use a random entity for (non) spawn tile
    EntityId spawnTileEntityId = randomEntityId();

    vm.prank(alice);
    vm.expectRevert("Not a spawn tile");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNotInSpawnArea() public {
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = VoxelCoord(0, 0, 0);
    VoxelCoord memory spawnTileCoord = VoxelCoord(500, 0, 0);

    // Set the spawn coord to Air
    EntityId spawnEntityId = randomEntityId();
    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, spawnEntityId);
    ObjectType.set(spawnEntityId, AirObjectID);

    // Set forcefield
    EntityId forceFieldEntityId = randomEntityId();
    VoxelCoord memory shardCoord = spawnTileCoord.toForceFieldShardCoord();
    ForceField.set(shardCoord.x, shardCoord.y, shardCoord.z, forceFieldEntityId);
    Energy.set(forceFieldEntityId, EnergyData({ energy: SPAWN_ENERGY, lastUpdatedTime: uint128(block.timestamp) }));

    // Set Far away entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z);
    ReversePosition.set(spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, SpawnTileObjectID);

    vm.prank(alice);
    vm.expectRevert("Spawn tile is too far away");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNoForceField() public {}

  function testSpawnFailsIfNotEnoughForceFieldEnergy() public {}
}
