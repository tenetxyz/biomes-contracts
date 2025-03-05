// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

import { BiomesTest, console } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";

import { ExploredChunk, ExploredChunkByIndex, LocalEnergyPool, ReversePosition, Position } from "../src/utils/Vec3Storage.sol";

import { ISpawnTileChip } from "../src/prototypes/ISpawnTileChip.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
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
  using ObjectTypeLib for ObjectTypeId;

  function spawnEnergy() internal view returns (uint128) {
    uint32 playerMass = ObjectTypeMetadata.getMass(ObjectTypes.Player);
    return MAX_PLAYER_ENERGY + massToEnergy(playerMass);
  }

  function testRandomSpawn() public {
    uint256 blockNumber = block.number - 5;
    address alice = vm.randomAddress();

    // Explore chunk at (0, 0, 0)
    setupAirChunk(vec3(0, 0, 0));

    Vec3 spawnCoord = world.getRandomSpawnCoord(blockNumber, alice, 0);

    // Set below entity to dirt so gravity doesn't apply
    EntityId belowEntityId = randomEntityId();
    Vec3 belowCoord = spawnCoord - vec3(0, 1, 0);
    ReversePosition.set(belowCoord, belowEntityId);
    ObjectType.set(belowEntityId, ObjectTypes.Dirt);

    // Give energy for local shard
    Vec3 shardCoord = spawnCoord.toLocalEnergyPoolShardCoord();
    LocalEnergyPool.set(shardCoord, spawnEnergy());

    vm.prank(alice);
    EntityId playerEntityId = world.randomSpawn(blockNumber, spawnCoord.y());
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
    Vec3 spawnCoord = vec3(0, 1, 0);
    Vec3 spawnTileCoord = spawnCoord - vec3(0, 1, 0);

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
    Position.set(spawnTileEntityId, spawnTileCoord);
    ReversePosition.set(spawnTileCoord, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, ObjectTypes.SpawnTile);

    TestSpawnChip chip = new TestSpawnChip();
    bytes14 namespace = "chipNamespace";
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId chipSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "chipName");
    world.registerNamespace(namespaceId);
    world.registerSystem(chipSystemId, chip, false);
    world.transferOwnership(namespaceId, address(0));

    // Attach chip with test player
    (address bob, ) = createTestPlayer(spawnTileCoord - vec3(1, 0, 0));
    vm.prank(bob);
    world.attachChip(spawnTileEntityId, chipSystemId);

    // Spawn alice
    vm.prank(alice);
    EntityId playerEntityId = world.spawn(spawnTileEntityId, spawnCoord, "");
    assertTrue(playerEntityId.exists());
  }

  function testSpawnFailsIfNoSpawnTile() public {
    address alice = vm.randomAddress();
    Vec3 spawnCoord = vec3(0, 0, 0);

    // Use a random entity for (non) spawn tile
    EntityId spawnTileEntityId = randomEntityId();

    vm.prank(alice);
    vm.expectRevert("Not a spawn tile");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNotInSpawnArea() public {
    address alice = vm.randomAddress();
    Vec3 spawnCoord = vec3(0, 0, 0);
    Vec3 spawnTileCoord = vec3(500, 0, 0);

    setupAirChunk(spawnCoord);

    // Set forcefield
    setupForceField(spawnTileCoord);

    // Set Far away entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord);
    ReversePosition.set(spawnTileCoord, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, ObjectTypes.SpawnTile);

    vm.prank(alice);
    vm.expectRevert("Spawn tile is too far away");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNoForceField() public {
    address alice = vm.randomAddress();
    Vec3 spawnCoord = vec3(0, 0, 0);
    Vec3 spawnTileCoord = spawnCoord - vec3(0, 1, 0);

    setupAirChunk(spawnCoord);

    // Set below entity to spawn tile (no forcefield)
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord);
    ReversePosition.set(spawnTileCoord, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, ObjectTypes.SpawnTile);

    vm.prank(alice);
    vm.expectRevert("Spawn tile is not inside a forcefield");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }

  function testSpawnFailsIfNotEnoughForceFieldEnergy() public {
    address alice = vm.randomAddress();
    Vec3 spawnCoord = vec3(0, 0, 0);
    Vec3 spawnTileCoord = spawnCoord - vec3(0, 1, 0);

    setupAirChunk(spawnCoord);

    // Set forcefield with no energy
    setupForceField(spawnTileCoord);

    // Set below entity to spawn tile
    EntityId spawnTileEntityId = randomEntityId();
    Position.set(spawnTileEntityId, spawnTileCoord);
    ReversePosition.set(spawnTileCoord, spawnTileEntityId);
    ObjectType.set(spawnTileEntityId, ObjectTypes.SpawnTile);

    vm.prank(alice);
    vm.expectRevert("Not enough energy in spawn tile forcefield");
    world.spawn(spawnTileEntityId, spawnCoord, "");
  }
}
