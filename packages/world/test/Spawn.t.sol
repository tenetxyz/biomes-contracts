// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

import { BiomesTest, console } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ExploredChunk } from "../src/codegen/tables/ExploredChunk.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex } from "../src/codegen/tables/ExploredChunkByIndex.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";

import { ISpawnTileChip } from "../src/prototypes/ISpawnTileChip.sol";
import { ChunkCoord } from "../src/Types.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord } from "../src/VoxelCoord.sol";
import { CHUNK_SIZE, MAX_PLAYER_ENERGY, MACHINE_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract TestSpawnChip is ISpawnTileChip, System {
  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onSpawn(EntityId callerEntityId, EntityId spawnTileEntityId, bytes memory extraData) external payable {}

  function supportsInterface(bytes4 interfaceId) public pure override(IERC165, WorldContextConsumer) returns (bool) {
    return interfaceId == type(ISpawnTileChip).interfaceId || super.supportsInterface(interfaceId);
  }
}

contract SpawnTest is BiomesTest {
  function spawnEnergy() internal view returns (uint128) {
    uint32 playerMass = ObjectTypeMetadata.getMass(PlayerObjectID);
    return MAX_PLAYER_ENERGY + massToEnergy(playerMass);
  }

  function testRandomSpawn() public {
    uint256 blockNumber = block.number - 5;
    address alice = vm.randomAddress();

    // Explore chunk at (0, 0, 0)
    setupAirChunk(VoxelCoord(0, 0, 0));

    VoxelCoord memory spawnCoord = world.getRandomSpawnCoord(blockNumber, alice, 0);

    // Set below entity to dirt so gravity doesn't apply
    EntityId belowEntityId = randomEntityId();
    ReversePosition.set(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z, belowEntityId);
    ObjectType.set(belowEntityId, DirtObjectID);

    // Give energy for local shard
    VoxelCoord memory shardCoord = spawnCoord.toLocalEnergyPoolShardCoord();
    LocalEnergyPool.set(shardCoord.x, 0, shardCoord.z, spawnEnergy());

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

    setupAirChunk(spawnCoord);

    // Set forcefield
    EntityId forceFieldEntityId = setupForceField(spawnTileCoord);
    Energy.set(
      forceFieldEntityId,
      EnergyData({
        energy: spawnEnergy(),
        lastUpdatedTime: uint128(block.timestamp),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    // Set below entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z);
    ReversePosition.set(spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, SpawnTileObjectID);

    TestSpawnChip chip = new TestSpawnChip();
    bytes14 namespace = "chipNamespace";
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId chipSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "chipName");
    world.registerNamespace(namespaceId);
    world.registerSystem(chipSystemId, chip, false);
    world.transferOwnership(namespaceId, address(0));

    // Attach chip with test player
    (address bob, ) = createTestPlayer(VoxelCoord(spawnTileCoord.x - 1, spawnTileCoord.y, spawnTileCoord.z));
    vm.prank(bob);
    world.attachChip(spawnTileEntityId, chipSystemId);

    // Spawn alice
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

    setupAirChunk(spawnCoord);

    // Set forcefield
    setupForceField(spawnTileCoord);

    // Set Far away entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z);
    ReversePosition.set(spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, SpawnTileObjectID);

    vm.prank(alice);
    vm.expectRevert("Spawn tile is too far away");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNoForceField() public {
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = VoxelCoord(0, 0, 0);
    VoxelCoord memory spawnTileCoord = VoxelCoord(0, spawnCoord.y - 1, 0);

    setupAirChunk(spawnCoord);

    // Set below entity to spawn tile (no forcefield)
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z);
    ReversePosition.set(spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, SpawnTileObjectID);

    vm.prank(alice);
    vm.expectRevert("Spawn tile is not inside a forcefield");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNotEnoughForceFieldEnergy() public {
    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = VoxelCoord(0, 0, 0);
    VoxelCoord memory spawnTileCoord = VoxelCoord(0, spawnCoord.y - 1, 0);

    setupAirChunk(spawnCoord);

    // Set forcefield with no energy
    setupForceField(spawnTileCoord);

    // Set below entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z);
    ReversePosition.set(spawnTileCoord.x, spawnTileCoord.y, spawnTileCoord.z, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, SpawnTileObjectID);

    vm.prank(alice);
    vm.expectRevert("Not enough energy in spawn tile forcefield");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }
}
