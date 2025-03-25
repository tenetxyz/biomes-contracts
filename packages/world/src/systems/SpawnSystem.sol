// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { SurfaceChunkCount } from "../codegen/tables/SurfaceChunkCount.sol";

import { SurfaceChunkByIndex, ExploredChunk, Position, ReversePosition, MovablePosition, ReverseMovablePosition } from "../utils/Vec3Storage.sol";

import { MAX_PLAYER_ENERGY, PLAYER_ENERGY_DRAIN_RATE, SPAWN_BLOCK_RANGE, MAX_PLAYER_RESPAWN_HALF_WIDTH, CHUNK_SIZE } from "../Constants.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus } from "../Utils.sol";
import { notify, SpawnNotifData } from "../utils/NotifUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { removeEnergyFromLocalPool, updateMachineEnergy, updatePlayerEnergy } from "../utils/EnergyUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { ISpawnTileProgram } from "../prototypes/ISpawnTileProgram.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { getObjectTypeIdAt, getMovableEntityAt } from "../utils/EntityUtils.sol";

import { EntityId } from "../EntityId.sol";

contract SpawnSystem is System {
  using ObjectTypeLib for ObjectTypeId;
  using LibPRNG for LibPRNG.PRNG;

  function getAllRandomSpawnCoords(
    address sender
  ) public view returns (Vec3[] memory spawnCoords, uint256[] memory blockNumbers) {
    spawnCoords = new Vec3[](SPAWN_BLOCK_RANGE);
    blockNumbers = new uint256[](SPAWN_BLOCK_RANGE);
    for (uint256 i = 0; i < SPAWN_BLOCK_RANGE; i++) {
      uint256 blockNumber = block.number - (i + 1);
      spawnCoords[i] = getRandomSpawnCoord(blockNumber, sender);
      blockNumbers[i] = blockNumber;
    }
    return (spawnCoords, blockNumbers);
  }

  function getRandomSpawnCoord(uint256 blockNumber, address sender) public view returns (Vec3 spawnCoord) {
    uint256 exploredChunkCount = SurfaceChunkCount._get();
    require(exploredChunkCount > 0, "No surface chunks available");

    // Randomness used for the chunk index and relative coordinates
    LibPRNG.PRNG memory prng;
    prng.seed(uint256(keccak256(abi.encodePacked(blockhash(blockNumber), sender))));
    uint256 chunkIndex = prng.uniform(exploredChunkCount);
    Vec3 chunk = SurfaceChunkByIndex._get(chunkIndex);

    // Convert chunk coordinates to world coordinates and add random offset
    Vec3 coord = chunk.mul(CHUNK_SIZE);

    // Convert CHUNK_SIZE from int32 to uint256
    uint256 chunkSize = uint256(int256(CHUNK_SIZE));

    // Get random position within the chunk (0 to CHUNK_SIZE-1)
    int32 relativeX = int32(int256(prng.next() % chunkSize));
    int32 relativeZ = int32(int256(prng.next() % chunkSize));

    return coord + vec3(relativeX, 0, relativeZ);
  }

  function isValidSpawn(Vec3 spawnCoord) public view returns (bool) {
    Vec3 belowCoord = spawnCoord - vec3(0, 1, 0);
    Vec3 topCoord = spawnCoord + vec3(0, 1, 0);

    ObjectTypeId spawnObjectTypeId = getObjectTypeIdAt(spawnCoord);
    if (
      spawnObjectTypeId.isNull() ||
      !ObjectTypeMetadata._getCanPassThrough(spawnObjectTypeId) ||
      getMovableEntityAt(spawnCoord).exists()
    ) {
      return false;
    }

    ObjectTypeId topObjectTypeId = getObjectTypeIdAt(topCoord);
    if (
      topObjectTypeId.isNull() ||
      !ObjectTypeMetadata._getCanPassThrough(topObjectTypeId) ||
      getMovableEntityAt(topCoord).exists()
    ) {
      return false;
    }

    ObjectTypeId belowObjectTypeId = getObjectTypeIdAt(belowCoord);
    if (
      belowObjectTypeId.isNull() ||
      (belowObjectTypeId != ObjectTypes.Water &&
        ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId) &&
        !getMovableEntityAt(belowCoord).exists())
    ) {
      return false;
    }

    return true;
  }

  function getValidSpawnY(Vec3 spawnCoordCandidate) public view returns (Vec3 spawnCoord) {
    for (int32 i = CHUNK_SIZE - 1; i >= 0; i--) {
      spawnCoord = spawnCoordCandidate + vec3(0, i, 0);
      if (isValidSpawn(spawnCoord)) {
        return spawnCoord;
      }
    }

    revert("No valid spawn Y found in chunk");
  }

  function randomSpawn(uint256 blockNumber, int32 y) public returns (EntityId) {
    checkWorldStatus();
    require(
      blockNumber < block.number && blockNumber >= block.number - SPAWN_BLOCK_RANGE,
      "Can only choose past 10 blocks"
    );

    Vec3 spawnCoord = getRandomSpawnCoord(blockNumber, _msgSender());

    require(spawnCoord.y() <= y && y < spawnCoord.y() + CHUNK_SIZE, "y coordinate outside of spawn chunk");

    // Use the y coordinate given by the player
    spawnCoord = vec3(spawnCoord.x(), y, spawnCoord.z());

    (EntityId forceFieldEntityId, ) = getForceField(spawnCoord);
    require(!forceFieldEntityId.exists(), "Cannot spawn in force field");

    // Extract energy from local pool
    removeEnergyFromLocalPool(spawnCoord, MAX_PLAYER_ENERGY);

    return _spawnPlayer(spawnCoord);
  }

  function spawn(EntityId spawnTileEntityId, Vec3 spawnCoord, bytes memory extraData) public returns (EntityId) {
    checkWorldStatus();
    ObjectTypeId objectTypeId = ObjectType._get(spawnTileEntityId);
    require(objectTypeId == ObjectTypes.SpawnTile, "Not a spawn tile");

    Vec3 spawnTileCoord = Position._get(spawnTileEntityId);
    require(spawnTileCoord.inSurroundingCube(spawnCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH), "Spawn tile is too far away");

    (EntityId forceFieldEntityId, ) = getForceField(spawnTileCoord);
    require(forceFieldEntityId.exists(), "Spawn tile is not inside a forcefield");
    (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
    uint128 energyRequired = MAX_PLAYER_ENERGY;
    require(machineData.energy >= energyRequired, "Not enough energy in spawn tile forcefield");
    Energy._setEnergy(forceFieldEntityId, machineData.energy - energyRequired);

    EntityId playerEntityId = _spawnPlayer(spawnCoord);

    bytes memory onSpawnCall = abi.encodeCall(
      ISpawnTileProgram.onSpawn,
      (playerEntityId, spawnTileEntityId, extraData)
    );
    callProgramOrRevert(spawnTileEntityId.getProgram(), onSpawnCall);

    return playerEntityId;
  }

  function _spawnPlayer(Vec3 spawnCoord) internal returns (EntityId) {
    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    EntityId playerEntityId = PlayerUtils.getOrCreatePlayer();
    SpawnLib._requirePlayerDead(playerEntityId);

    // Position the player at the given coordinates
    PlayerUtils.addPlayerToGrid(playerEntityId, spawnCoord);

    Energy._set(
      playerEntityId,
      EnergyData({
        energy: MAX_PLAYER_ENERGY,
        lastUpdatedTime: uint128(block.timestamp),
        drainRate: PLAYER_ENERGY_DRAIN_RATE
      })
    );

    notify(playerEntityId, SpawnNotifData({ spawnCoord: spawnCoord }));

    return playerEntityId;
  }
}

library SpawnLib {
  function _requirePlayerDead(EntityId playerEntityId) public {
    require(updatePlayerEnergy(playerEntityId).energy == 0, "Player already spawned");
  }
}
