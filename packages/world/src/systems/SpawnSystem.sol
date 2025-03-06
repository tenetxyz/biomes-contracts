// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ExploredChunkCount } from "../codegen/tables/ExploredChunkCount.sol";

import { ExploredChunkByIndex, ExploredChunk, Position, ReversePosition, PlayerPosition, ReversePlayerPosition } from "../utils/Vec3Storage.sol";

import { MAX_PLAYER_ENERGY, PLAYER_ENERGY_DRAIN_RATE, SPAWN_BLOCK_RANGE, MAX_PLAYER_RESPAWN_HALF_WIDTH, CHUNK_SIZE } from "../Constants.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus, getUniqueEntity, inWorldBorder } from "../Utils.sol";
import { notify, SpawnNotifData } from "../utils/NotifUtils.sol";
import { mod } from "../utils/MathUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { removeEnergyFromLocalPool, updateEnergyLevel, massToEnergy } from "../utils/EnergyUtils.sol";
import { ISpawnTileChip } from "../prototypes/ISpawnTileChip.sol";
import { createPlayer } from "../utils/PlayerUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { getObjectTypeIdAt } from "../utils/EntityUtils.sol";

import { EntityId } from "../EntityId.sol";

contract SpawnSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function getEnergyCostToSpawn(uint32 playerMass) internal pure returns (uint128) {
    uint128 energyRequired = MAX_PLAYER_ENERGY + massToEnergy(playerMass);
    return energyRequired;
  }

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

  // TODO: do we want to use something like solady's prng?
  function getRandomSpawnCoord(uint256 blockNumber, address sender) public view returns (Vec3 spawnCoord) {
    uint256 exploredChunkCount = ExploredChunkCount._get();
    require(exploredChunkCount > 0, "No explored chunks available");

    // Randomness used for the chunk index and relative coordinates
    uint256 rand = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), sender)));
    uint256 chunkIndex = rand % exploredChunkCount;
    Vec3 chunk = ExploredChunkByIndex._get(chunkIndex);

    // Convert chunk coordinates to world coordinates and add random offset
    int32 chunkWorldX = chunk.x() * CHUNK_SIZE;
    int32 chunkWorldY = chunk.y() * CHUNK_SIZE;
    int32 chunkWorldZ = chunk.z() * CHUNK_SIZE;

    // Convert CHUNK_SIZE from int32 to uint256
    uint256 chunkSize = uint256(int256(CHUNK_SIZE));

    // Get random position within the chunk (0 to CHUNK_SIZE-1)
    uint256 posRand = uint256(keccak256(abi.encodePacked(rand)));
    int32 relativeX = int32(int256(posRand % chunkSize));
    int32 relativeZ = int32(int256((posRand / chunkSize) % chunkSize));

    return vec3(chunkWorldX + relativeX, chunkWorldY, chunkWorldZ + relativeZ);
  }

  function isValidSpawn(Vec3 spawnCoord) public view returns (bool) {
    Vec3 belowCoord = spawnCoord - vec3(0, 1, 0);
    ObjectTypeId spawnObjectTypeId = getObjectTypeIdAt(spawnCoord);
    ObjectTypeId belowObjectTypeId = getObjectTypeIdAt(belowCoord);
    return
      !spawnObjectTypeId.isNull() &&
      !belowObjectTypeId.isNull() &&
      ObjectTypeMetadata._getCanPassThrough(spawnObjectTypeId) &&
      !ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId);
  }

  function getValidSpawnY(Vec3 spawnCoordCandidate) public view returns (Vec3 spawnCoord) {
    for (int32 i = 0; i < CHUNK_SIZE; i++) {
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
    // Use the y coordinate given by the player
    spawnCoord = vec3(spawnCoord.x(), y, spawnCoord.z());

    EntityId forceFieldEntityId = getForceField(spawnCoord);
    require(!forceFieldEntityId.exists(), "Cannot spawn in force field");

    // Extract energy from local pool
    uint32 playerMass = ObjectTypeMetadata._getMass(ObjectTypes.Player);
    uint128 energyRequired = getEnergyCostToSpawn(playerMass);
    removeEnergyFromLocalPool(spawnCoord, energyRequired);

    return _spawnPlayer(playerMass, spawnCoord);
  }

  function spawn(EntityId spawnTileEntityId, Vec3 spawnCoord, bytes memory extraData) public returns (EntityId) {
    checkWorldStatus();
    ObjectTypeId objectTypeId = ObjectType._get(spawnTileEntityId);
    require(objectTypeId == ObjectTypes.SpawnTile, "Not a spawn tile");

    Vec3 spawnTileCoord = Position._get(spawnTileEntityId);
    require(spawnTileCoord.inSurroundingCube(spawnCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH), "Spawn tile is too far away");

    EntityId forceFieldEntityId = getForceField(spawnTileCoord);
    require(forceFieldEntityId.exists(), "Spawn tile is not inside a forcefield");
    uint32 playerMass = ObjectTypeMetadata._getMass(ObjectTypes.Player);
    uint128 energyRequired = getEnergyCostToSpawn(playerMass);
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);
    require(machineData.energy >= energyRequired, "Not enough energy in spawn tile forcefield");
    forceFieldEntityId.setEnergy(machineData.energy - energyRequired);

    EntityId playerEntityId = _spawnPlayer(playerMass, spawnCoord);

    address chipAddress = spawnTileEntityId.getChipAddress();
    // TODO: should we do this check at the callChip level?
    require(chipAddress != address(0), "Spawn tile has no chip");

    bytes memory onSpawnCall = abi.encodeCall(ISpawnTileChip.onSpawn, (playerEntityId, spawnTileEntityId, extraData));
    callChipOrRevert(chipAddress, onSpawnCall);

    return playerEntityId;
  }

  function _spawnPlayer(uint32 playerMass, Vec3 spawnCoord) internal returns (EntityId) {
    require(inWorldBorder(spawnCoord), "Cannot spawn outside the world border");
    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    address playerAddress = _msgSender();
    require(!Player._get(playerAddress).exists(), "Player already spawned");

    EntityId basePlayerEntityId = getUniqueEntity();
    createPlayer(basePlayerEntityId, spawnCoord);

    Player._set(playerAddress, basePlayerEntityId);
    ReversePlayer._set(basePlayerEntityId, playerAddress);

    Mass._set(basePlayerEntityId, playerMass);
    Energy._set(
      basePlayerEntityId,
      EnergyData({
        energy: MAX_PLAYER_ENERGY,
        lastUpdatedTime: uint128(block.timestamp),
        drainRate: PLAYER_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    PlayerActivity._set(basePlayerEntityId, uint128(block.timestamp));

    notify(basePlayerEntityId, SpawnNotifData({ playerAddress: playerAddress, spawnCoord: spawnCoord }));

    return basePlayerEntityId;
  }
}
