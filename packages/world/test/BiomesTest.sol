// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { PlayerPosition } from "../src/codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../src/codegen/tables/ReversePlayerPosition.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerActivity } from "../src/codegen/tables/PlayerActivity.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../src/codegen/tables/ReverseInventoryEntity.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { EntityId } from "../src/EntityId.sol";
import { ChunkCoord } from "../src/Types.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { ObjectTypeId, PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, WaterObjectID, ForceFieldObjectID } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, PLAYER_MINE_ENERGY_COST, MAX_PLAYER_ENERGY, PLAYER_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { energyToMass } from "../src/utils/EnergyUtils.sol";
import { getObjectTypeSchema } from "../src/utils/ObjectTypeUtils.sol";
import { TestUtils } from "./utils/TestUtils.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

abstract contract BiomesTest is MudTest, GasReporter {
  struct EnergyDataSnapshot {
    uint128 playerEnergy;
    uint128 localPoolEnergy;
    uint128 forceFieldEnergy;
  }

  using VoxelCoordLib for *;

  IWorld internal world;
  int32 constant FLAT_CHUNK_GRASS_LEVEL = 4;
  uint128 playerHandMassReduction = energyToMass(PLAYER_MINE_ENERGY_COST);

  function setUp() public virtual override {
    super.setUp();

    world = IWorld(worldAddress);

    // Transfer root ownership to this test contract
    ResourceId rootNamespace = WorldResourceIdLib.encodeNamespace(bytes14(0));
    address owner = NamespaceOwner.get(rootNamespace);
    vm.prank(owner);
    world.transferOwnership(rootNamespace, address(this));
    TestUtils.init(address(TestUtils));
  }

  function randomEntityId() internal returns (EntityId) {
    return EntityId.wrap(bytes32(vm.randomUint()));
  }

  // Create a valid player that can perform actions
  function createTestPlayer(VoxelCoord memory coord) internal returns (address, EntityId) {
    address playerAddress = vm.randomAddress();
    EntityId playerEntityId = randomEntityId();
    ObjectType.set(playerEntityId, PlayerObjectID);
    PlayerPosition.set(playerEntityId, coord.x, coord.y, coord.z);
    ReversePlayerPosition.set(coord.x, coord.y, coord.z, playerEntityId);

    VoxelCoord[] memory relativePositions = getObjectTypeSchema(PlayerObjectID);
    for (uint256 i = 0; i < relativePositions.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        coord.x + relativePositions[i].x,
        coord.y + relativePositions[i].y,
        coord.z + relativePositions[i].z
      );
      EntityId relativePlayerEntityId = randomEntityId();
      ObjectType.set(relativePlayerEntityId, PlayerObjectID);
      PlayerPosition.set(relativePlayerEntityId, relativeCoord.x, relativeCoord.y, relativeCoord.z);
      ReversePlayerPosition.set(relativeCoord.x, relativeCoord.y, relativeCoord.z, relativePlayerEntityId);
      BaseEntity.set(relativePlayerEntityId, playerEntityId);
    }

    Player.set(playerAddress, playerEntityId);
    ReversePlayer.set(playerEntityId, playerAddress);

    Mass.set(playerEntityId, ObjectTypeMetadata.getMass(PlayerObjectID));
    Energy.set(
      playerEntityId,
      EnergyData({
        lastUpdatedTime: uint128(block.timestamp),
        energy: MAX_PLAYER_ENERGY,
        drainRate: PLAYER_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    PlayerActivity.set(playerEntityId, uint128(block.timestamp));

    return (playerAddress, playerEntityId);
  }

  function _getFlatChunk() internal pure returns (uint8[][][] memory chunk) {
    chunk = new uint8[][][](uint256(int256(CHUNK_SIZE)));
    for (uint256 x = 0; x < uint256(int256(CHUNK_SIZE)); x++) {
      chunk[x] = new uint8[][](uint256(int256(CHUNK_SIZE)));
      for (uint256 y = 0; y < uint256(int256(CHUNK_SIZE)); y++) {
        chunk[x][y] = new uint8[](uint256(int256(CHUNK_SIZE)));
        for (uint256 z = 0; z < uint256(int256(CHUNK_SIZE)); z++) {
          if (y < uint256(int256(FLAT_CHUNK_GRASS_LEVEL))) {
            chunk[x][y][z] = uint8(ObjectTypeId.unwrap(DirtObjectID));
          } else if (y == uint256(int256(FLAT_CHUNK_GRASS_LEVEL))) {
            chunk[x][y][z] = uint8(ObjectTypeId.unwrap(GrassObjectID));
          } else {
            chunk[x][y][z] = uint8(ObjectTypeId.unwrap(AirObjectID));
          }
        }
      }
    }
  }

  function setupFlatChunk(VoxelCoord memory coord) internal {
    uint8[][][] memory chunk = _getFlatChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    bytes32[] memory merkleProof = new bytes32[](0);

    world.exploreChunk(chunkCoord, encodedChunk, merkleProof);

    VoxelCoord memory shardCoord = coord.toLocalEnergyPoolShardCoord();
    LocalEnergyPool.set(shardCoord.x, 0, shardCoord.z, 1e18);
  }

  function setupFlatChunkWithPlayer() internal returns (address, EntityId, VoxelCoord memory) {
    setupFlatChunk(VoxelCoord(0, 0, 0));
    return randomSpawnPlayer(FLAT_CHUNK_GRASS_LEVEL + 1);
  }

  function randomSpawnPlayer(int32 y) internal returns (address, EntityId, VoxelCoord memory) {
    uint256 blockNumber = block.number - 5;

    address alice = vm.randomAddress();
    VoxelCoord memory spawnCoord = world.getRandomSpawnCoord(blockNumber, alice, y);

    vm.prank(alice);
    EntityId aliceEntityId = world.randomSpawn(blockNumber, spawnCoord.y);

    VoxelCoord memory playerCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();

    return (alice, aliceEntityId, playerCoord);
  }

  function _getChunk(ObjectTypeId objectTypeId) internal pure returns (uint8[][][] memory chunk) {
    chunk = new uint8[][][](uint256(int256(CHUNK_SIZE)));
    for (uint256 x = 0; x < uint256(int256(CHUNK_SIZE)); x++) {
      chunk[x] = new uint8[][](uint256(int256(CHUNK_SIZE)));
      for (uint256 y = 0; y < uint256(int256(CHUNK_SIZE)); y++) {
        chunk[x][y] = new uint8[](uint256(int256(CHUNK_SIZE)));
        for (uint256 z = 0; z < uint256(int256(CHUNK_SIZE)); z++) {
          chunk[x][y][z] = uint8(ObjectTypeId.unwrap(objectTypeId));
        }
      }
    }
  }

  function _getAirChunk() internal pure returns (uint8[][][] memory chunk) {
    chunk = _getChunk(AirObjectID);
  }

  function setupAirChunk(VoxelCoord memory coord) internal {
    uint8[][][] memory chunk = _getAirChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    bytes32[] memory merkleProof = new bytes32[](0);

    world.exploreChunk(chunkCoord, encodedChunk, merkleProof);

    VoxelCoord memory shardCoord = coord.toLocalEnergyPoolShardCoord();
    LocalEnergyPool.set(shardCoord.x, 0, shardCoord.z, 1e18);
  }

  function _getWaterChunk() internal pure returns (uint8[][][] memory chunk) {
    chunk = _getChunk(WaterObjectID);
  }

  function setupWaterChunk(VoxelCoord memory coord) internal {
    uint8[][][] memory chunk = _getWaterChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    bytes32[] memory merkleProof = new bytes32[](0);

    world.exploreChunk(chunkCoord, encodedChunk, merkleProof);

    VoxelCoord memory shardCoord = coord.toLocalEnergyPoolShardCoord();
    LocalEnergyPool.set(shardCoord.x, 0, shardCoord.z, 1e18);
  }

  function setTerrainAtCoord(VoxelCoord memory coord, ObjectTypeId objectTypeId) internal {
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    if (!TerrainLib._isChunkExplored(chunkCoord, worldAddress)) {
      setupAirChunk(coord);
    }
    address chunkPointer = TerrainLib._getChunkPointer(chunkCoord, worldAddress);
    uint256 blockIndex = TerrainLib._getBlockIndex(coord);

    bytes memory chunk = chunkPointer.code;
    // Add SSTORE2 offset
    chunk[blockIndex + 1] = bytes1(uint8(objectTypeId.unwrap()));

    vm.etch(chunkPointer, chunk);
  }

  function setObjectAtCoord(VoxelCoord memory coord, ObjectTypeId objectTypeId) internal returns (EntityId) {
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    if (!TerrainLib._isChunkExplored(chunkCoord, worldAddress)) {
      setupAirChunk(coord);
    }

    EntityId entityId = randomEntityId();
    ObjectType.set(entityId, objectTypeId);
    Position.set(entityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, entityId);
    Mass.set(entityId, ObjectTypeMetadata.getMass(objectTypeId));

    VoxelCoord[] memory coords = coord.getRelativeCoords(objectTypeId);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      VoxelCoord memory relativeCoord = coords[i];
      EntityId relativeEntityId = randomEntityId();
      ObjectType.set(relativeEntityId, objectTypeId);
      Position.set(relativeEntityId, relativeCoord.x, relativeCoord.y, relativeCoord.z);
      ReversePosition.set(relativeCoord.x, relativeCoord.y, relativeCoord.z, relativeEntityId);
      BaseEntity.set(relativeEntityId, entityId);
    }
    return entityId;
  }

  function addToolToInventory(EntityId ownerEntityId, ObjectTypeId toolObjectTypeId) internal returns (EntityId) {
    require(toolObjectTypeId.isTool(), "Object type is not a tool");
    EntityId toolEntityId = randomEntityId();
    ObjectType.set(toolEntityId, toolObjectTypeId);
    InventoryEntity.set(toolEntityId, ownerEntityId);
    ReverseInventoryEntity.push(ownerEntityId, EntityId.unwrap(toolEntityId));
    Mass.set(toolEntityId, ObjectTypeMetadata.getMass(toolObjectTypeId));

    TestUtils.addToInventoryCount(ownerEntityId, ObjectType.get(ownerEntityId), toolObjectTypeId, 1);
    return toolEntityId;
  }

  function setupAirChunkWithPlayer() internal returns (address, EntityId, VoxelCoord memory) {
    setupAirChunk(VoxelCoord(0, 0, 0));
    return spawnPlayerOnAirChunk(VoxelCoord(0, 1, 0));
  }

  function setupWaterChunkWithPlayer() internal returns (address, EntityId, VoxelCoord memory) {
    setupWaterChunk(VoxelCoord(0, 0, 0));
    return spawnPlayerOnAirChunk(VoxelCoord(0, 1, 0));
  }

  function spawnPlayerOnAirChunk(VoxelCoord memory spawnCoord) internal returns (address, EntityId, VoxelCoord memory) {
    VoxelCoord memory belowCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    setTerrainAtCoord(spawnCoord, AirObjectID);
    setTerrainAtCoord(VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z), AirObjectID);
    setTerrainAtCoord(belowCoord, DirtObjectID);

    (address alice, EntityId aliceEntityId) = createTestPlayer(spawnCoord);
    VoxelCoord memory playerCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();

    return (alice, aliceEntityId, playerCoord);
  }

  function setupForceField(VoxelCoord memory coord) internal returns (EntityId) {
    // Set forcefield with no energy
    EntityId forceFieldEntityId = setObjectAtCoord(coord, ForceFieldObjectID);
    VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
    ForceField.set(shardCoord.x, shardCoord.y, shardCoord.z, forceFieldEntityId);
    return forceFieldEntityId;
  }

  function setupForceField(VoxelCoord memory coord, EnergyData memory energyData) internal returns (EntityId) {
    // Set forcefield with no energy
    EntityId forceFieldEntityId = setupForceField(coord);
    Energy.set(forceFieldEntityId, energyData);
    return forceFieldEntityId;
  }

  function assertInventoryHasObject(EntityId entityId, ObjectTypeId objectTypeId, uint16 amount) internal view {
    assertEq(InventoryCount.get(entityId, objectTypeId), amount, "Inventory count is not correct");
    if (amount > 0) {
      assertTrue(
        TestUtils.inventoryObjectsHasObjectType(entityId, objectTypeId),
        "Inventory objects does not have object type"
      );
    } else {
      assertFalse(TestUtils.inventoryObjectsHasObjectType(entityId, objectTypeId), "Inventory objects has object type");
    }
  }

  function assertInventoryHasTool(EntityId entityId, EntityId toolEntityId, uint16 amount) internal view {
    assertInventoryHasObject(entityId, ObjectType.get(toolEntityId), amount);
    if (amount > 0) {
      assertTrue(InventoryEntity.get(toolEntityId) == entityId, "Inventory entity is not owned by entity");
      assertTrue(
        TestUtils.reverseInventoryEntityHasEntity(entityId, toolEntityId),
        "Inventory entity is not in reverse inventory entity"
      );
    } else {
      assertFalse(InventoryEntity.get(toolEntityId) == entityId, "Inventory entity is not owned by entity");
      assertFalse(
        TestUtils.reverseInventoryEntityHasEntity(entityId, toolEntityId),
        "Inventory entity is in reverse inventory entity"
      );
    }
  }

  function getEnergyDataSnapshot(
    EntityId playerEntityId,
    VoxelCoord memory snapshotCoord
  ) internal view returns (EnergyDataSnapshot memory) {
    EnergyDataSnapshot memory snapshot;
    snapshot.playerEnergy = Energy.getEnergy(playerEntityId);
    VoxelCoord memory shardCoord = snapshotCoord.toLocalEnergyPoolShardCoord();
    snapshot.localPoolEnergy = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    VoxelCoord memory forceFieldShardCoord = snapshotCoord.toForceFieldShardCoord();
    EntityId forceFieldEntityId = ForceField.get(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );
    snapshot.forceFieldEnergy = forceFieldEntityId.exists() ? Energy.getEnergy(forceFieldEntityId) : 0;
    return snapshot;
  }

  function assertEnergyFlowedFromPlayerToLocalPool(
    EnergyDataSnapshot memory beforeEnergyDataSnapshot,
    EnergyDataSnapshot memory afterEnergyDataSnapshot
  ) internal pure {
    uint128 playerEnergyLost = beforeEnergyDataSnapshot.playerEnergy - afterEnergyDataSnapshot.playerEnergy;
    assertTrue(playerEnergyLost > 0, "Player energy did not decrease");
    uint128 localPoolEnergyGained = afterEnergyDataSnapshot.localPoolEnergy - beforeEnergyDataSnapshot.localPoolEnergy;
    assertEq(localPoolEnergyGained, playerEnergyLost, "Local pool energy did not gain energy");
  }
}
