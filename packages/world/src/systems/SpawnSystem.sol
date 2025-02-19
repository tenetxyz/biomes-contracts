// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ExploredChunkByIndex, ExploredChunkByIndexData } from "../codegen/tables/ExploredChunkByIndex.sol";
import { ExploredChunkCount } from "../codegen/tables/ExploredChunkCount.sol";
import { ExploredChunk } from "../codegen/tables/ExploredChunk.sol";

import { MAX_PLAYER_ENERGY, SPAWN_AREA_HALF_WIDTH, CHUNK_SIZE } from "../Constants.sol";
import { ObjectTypeId, AirObjectID, PlayerObjectID, SpawnTileObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, getUniqueEntity, gravityApplies, inWorldBorder } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { notify, SpawnNotifData } from "../utils/NotifUtils.sol";
import { mod } from "../utils/MathUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { updateMachineEnergyLevel, massToEnergy } from "../utils/EnergyUtils.sol";
import { ISpawnTileChip } from "../prototypes/ISpawnTileChip.sol";

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { EntityId } from "../EntityId.sol";

contract SpawnSystem is System {
  using VoxelCoordLib for *;

  function getEnergyCostToSpawn(uint32 playerMass) internal pure returns (uint128) {
    uint128 energyRequired = MAX_PLAYER_ENERGY + massToEnergy(playerMass);
    return energyRequired;
  }

  function getRandomSpawnCoord(
    uint256 blockNumber,
    address sender,
    int32 y
  ) public view returns (VoxelCoord memory spawnCoord) {
    spawnCoord.y = y;

    uint256 exploredChunkCount = ExploredChunkCount._get();
    require(exploredChunkCount > 0, "No explored chunks available");

    // Randomness used for the chunk index and relative coordinates
    uint256 rand = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), sender)));
    uint256 chunkIndex = rand % exploredChunkCount;
    ExploredChunkByIndexData memory chunk = ExploredChunkByIndex._get(chunkIndex);

    // Convert chunk coordinates to world coordinates and add random offset
    int32 chunkWorldX = chunk.x * CHUNK_SIZE;
    int32 chunkWorldZ = chunk.z * CHUNK_SIZE;

    // Convert CHUNK_SIZE from int32 to uint256
    uint256 chunkSize = uint256(int256(CHUNK_SIZE));

    // Get random position within the chunk (0 to CHUNK_SIZE-1)
    uint256 posRand = uint256(keccak256(abi.encodePacked(rand)));
    int32 relativeX = int32(int256(posRand % chunkSize));
    int32 relativeZ = int32(int256((posRand / chunkSize) % chunkSize));

    spawnCoord.x = chunkWorldX + relativeX;
    spawnCoord.z = chunkWorldZ + relativeZ;
  }

  function randomSpawn(uint256 blockNumber, int32 y) public returns (EntityId) {
    checkWorldStatus();
    // TODO: use constant
    require(blockNumber >= block.number - 10, "Can only choose past 10 blocks");

    VoxelCoord memory spawnCoord = getRandomSpawnCoord(blockNumber, _msgSender(), y);

    EntityId forceFieldEntityId = getForceField(spawnCoord);
    require(!forceFieldEntityId.exists(), "Cannot spawn in force field");

    // Extract energy from local pool
    uint32 playerMass = ObjectTypeMetadata._getMass(PlayerObjectID);
    uint128 energyRequired = getEnergyCostToSpawn(playerMass);
    spawnCoord.removeEnergyFromLocalPool(energyRequired);

    return _spawnPlayer(playerMass, spawnCoord);
  }

  function spawn(
    EntityId spawnTileEntityId,
    VoxelCoord memory spawnCoord,
    bytes memory extraData
  ) public returns (EntityId) {
    checkWorldStatus();
    ObjectTypeId objectTypeId = ObjectType._get(spawnTileEntityId);
    require(objectTypeId == SpawnTileObjectID, "Not a spawn tile");

    VoxelCoord memory spawnTileCoord = Position._get(spawnTileEntityId).toVoxelCoord();
    require(spawnTileCoord.inSurroundingCube(SPAWN_AREA_HALF_WIDTH, spawnCoord), "Spawn tile is too far away");

    EntityId forceFieldEntityId = getForceField(spawnTileCoord);
    require(forceFieldEntityId.exists(), "Spawn tile is not inside a forcefield");
    uint32 playerMass = ObjectTypeMetadata._getMass(PlayerObjectID);
    uint128 energyRequired = getEnergyCostToSpawn(playerMass);
    EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
    require(machineData.energy >= energyRequired, "Not enough energy in spawn tile forcefield");
    forceFieldEntityId.decreaseEnergy(machineData, energyRequired);

    EntityId playerEntityId = _spawnPlayer(playerMass, spawnCoord);

    address chipAddress = spawnTileEntityId.getChipAddress();
    // TODO: should we do this check at the callChip level?
    require(chipAddress != address(0), "Spawn tile has no chip");

    bytes memory onSpawnCall = abi.encodeCall(ISpawnTileChip.onSpawn, (playerEntityId, spawnTileEntityId, extraData));
    callChipOrRevert(chipAddress, onSpawnCall);

    return playerEntityId;
  }

  function _spawnPlayer(uint32 playerMass, VoxelCoord memory spawnCoord) internal returns (EntityId) {
    require(inWorldBorder(spawnCoord), "Cannot spawn outside the world border");

    require(!gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    address playerAddress = _msgSender();
    require(!Player._get(playerAddress).exists(), "Player already spawned");

    EntityId playerEntityId = getUniqueEntity();

    EntityId existingEntityId = ReversePosition._get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    if (!existingEntityId.exists()) {
      ObjectTypeId terrainObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(spawnCoord));
      require(terrainObjectTypeId == AirObjectID, "Cannot spawn on a non-air block");
    } else {
      require(ObjectType._get(existingEntityId) == AirObjectID, "Cannot spawn on a non-air block");
      // Transfer any dropped items
      transferAllInventoryEntities(existingEntityId, playerEntityId, PlayerObjectID);

      Position._deleteRecord(existingEntityId);
    }

    // Create new entity
    Position._set(playerEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
    ReversePosition._set(spawnCoord.x, spawnCoord.y, spawnCoord.z, playerEntityId);

    // Set object type to player
    ObjectType._set(playerEntityId, PlayerObjectID);
    Player._set(playerAddress, playerEntityId);
    ReversePlayer._set(playerEntityId, playerAddress);

    Mass._set(playerEntityId, playerMass);
    Energy._set(playerEntityId, EnergyData({ energy: MAX_PLAYER_ENERGY, lastUpdatedTime: uint128(block.timestamp) }));

    PlayerActivity._set(playerEntityId, uint128(block.timestamp));

    notify(playerEntityId, SpawnNotifData({ playerAddress: playerAddress, spawnCoord: spawnCoord }));

    return playerEntityId;
  }
}
