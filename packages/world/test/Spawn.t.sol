// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { EntityId } from "../src/EntityId.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { TerrainLib, VERSION_PADDING } from "../src/systems/libraries/TerrainLib.sol";
import { AirObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord, ChunkCoord } from "../src/Types.sol";
import { CHUNK_SIZE, SPAWN_ENERGY } from "../src/Constants.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract SpawnTest is MudTest, GasReporter {
  IWorld private world;

  function setUp() public override {
    super.setUp();

    world = IWorld(worldAddress);

    // Transfer root ownership to this test contract
    ResourceId rootNamespace = WorldResourceIdLib.encodeNamespace(bytes14(0));
    address owner = NamespaceOwner.get(rootNamespace);
    vm.prank(owner);
    world.transferOwnership(rootNamespace, address(this));
  }

  function testRandomSpawn() public {
    uint256 blockNumber = block.number - 5;
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = world.getRandomSpawnCoord(blockNumber, alice, 0);
    VoxelCoord memory shardCoord = spawnCoord.toSpawnShardCoord();
    LocalEnergyPool._set(shardCoord.x, 0, shardCoord.z, SPAWN_ENERGY);

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

  function testSpawn() public {}

  function testSpawnFailsIfNoSpawnTile() public {}

  function testSpawnFailsIfNotInSpawnArea() public {}

  function testSpawnFailsIfNoForceField() public {}

  function testSpawnFailsIfNotEnoughForceFieldEnergy() public {}
}
