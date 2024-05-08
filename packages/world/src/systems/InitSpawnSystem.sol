// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { UniqueEntity } from "../codegen/tables/UniqueEntity.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { Spawn, SpawnData } from "../codegen/tables/Spawn.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { SPAWN_SHARD_DIM, MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, BasaltCarvedObjectID, StoneObjectID, DirtObjectID, GrassObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity, positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, gravityApplies, inWorldBorder, inSpawnArea, getTerrainObjectTypeId } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube, coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract InitSpawnSystem is System {
  function addSpawn(VoxelCoord memory lowerSouthwestCorner, VoxelCoord memory size) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    require(inWorldBorder(lowerSouthwestCorner), "InitSpawnSystem: cannot place spawn outside world border");
    VoxelCoord memory spawnCoord = coordToShardCoordIgnoreY(lowerSouthwestCorner, SPAWN_SHARD_DIM);
    require(
      !Spawn._get(spawnCoord.x, spawnCoord.z).initialized,
      "InitSpawnSystem: spawn already exists for this shard"
    );
    require(size.x > 0 && size.z > 0, "InitSpawnSystem: size must be positive");

    Spawn._set(
      spawnCoord.x,
      spawnCoord.z,
      SpawnData({
        initialized: true,
        spawnLowX: lowerSouthwestCorner.x,
        spawnLowZ: lowerSouthwestCorner.z,
        spawnHighX: lowerSouthwestCorner.x + size.x - 1,
        spawnHighZ: lowerSouthwestCorner.z + size.z - 1
      })
    );
  }

  function initSpawnAreaTop(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");

    int16 midPointX = (spawnData.spawnLowX + spawnData.spawnHighX) / 2;
    for (int16 x = spawnData.spawnLowX; x <= midPointX; x++) {
      for (int16 z = spawnData.spawnLowZ; z <= spawnData.spawnHighZ; z++) {
        if (
          x == spawnData.spawnLowX || x == spawnData.spawnHighX || z == spawnData.spawnLowZ || z == spawnData.spawnHighZ
        ) {
          setObjectAtCoord(BasaltCarvedObjectID, VoxelCoord(x, spawnCoord.y, z));
        } else {
          setObjectAtCoord(StoneObjectID, VoxelCoord(x, spawnCoord.y, z));
        }
      }
    }
  }

  function initSpawnAreaTopPart2(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");

    int16 midPointX = (spawnData.spawnLowX + spawnData.spawnHighX) / 2;
    for (int16 x = midPointX + 1; x <= spawnData.spawnHighX; x++) {
      for (int16 z = spawnData.spawnLowZ; z <= spawnData.spawnHighZ; z++) {
        if (
          x == spawnData.spawnLowX || x == spawnData.spawnHighX || z == spawnData.spawnLowZ || z == spawnData.spawnHighZ
        ) {
          setObjectAtCoord(BasaltCarvedObjectID, VoxelCoord(x, spawnCoord.y, z));
        } else {
          setObjectAtCoord(StoneObjectID, VoxelCoord(x, spawnCoord.y, z));
        }
      }
    }
  }

  function initSpawnAreaTopAir(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");

    int16 midPointX = (spawnData.spawnLowX + spawnData.spawnHighX) / 2;
    for (int16 x = spawnData.spawnLowX; x <= midPointX; x++) {
      for (int16 z = spawnData.spawnLowZ; z <= spawnData.spawnHighZ; z++) {
        setObjectAtCoord(AirObjectID, VoxelCoord(x, spawnCoord.y + 1, z));
      }
    }
  }

  function initSpawnAreaTopAirPart2(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");

    int16 midPointX = (spawnData.spawnLowX + spawnData.spawnHighX) / 2;
    for (int16 x = midPointX + 1; x <= spawnData.spawnHighX; x++) {
      for (int16 z = spawnData.spawnLowZ; z <= spawnData.spawnHighZ; z++) {
        setObjectAtCoord(AirObjectID, VoxelCoord(x, spawnCoord.y + 1, z));
      }
    }
  }

  function initSpawnAreaBottom(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");

    int16 midPointX = (spawnData.spawnLowX + spawnData.spawnHighX) / 2;
    for (int16 x = spawnData.spawnLowX; x <= midPointX; x++) {
      for (int16 z = spawnData.spawnLowZ; z <= spawnData.spawnHighZ; z++) {
        setObjectAtCoord(DirtObjectID, VoxelCoord(x, spawnCoord.y - 1, z));
      }
    }
  }

  function initSpawnAreaBottomPart2(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");

    int16 midPointX = (spawnData.spawnLowX + spawnData.spawnHighX) / 2;
    for (int16 x = midPointX + 1; x <= spawnData.spawnHighX; x++) {
      for (int16 z = spawnData.spawnLowZ; z <= spawnData.spawnHighZ; z++) {
        setObjectAtCoord(DirtObjectID, VoxelCoord(x, spawnCoord.y - 1, z));
      }
    }
  }

  function initSpawnAreaBottomBorder(VoxelCoord memory spawnCoord) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, msg.sender);

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
    require(spawnData.initialized, "InitSpawnSystem: spawn does not exist for this shard");
    for (int16 x = spawnData.spawnLowX - 1; x <= spawnData.spawnHighX + 1; x++) {
      for (int16 z = spawnData.spawnLowZ - 1; z <= spawnData.spawnHighZ + 1; z++) {
        if (
          x == spawnData.spawnLowX - 1 ||
          x == spawnData.spawnHighX + 1 ||
          z == spawnData.spawnLowZ - 1 ||
          z == spawnData.spawnHighZ + 1
        ) {
          setObjectAtCoord(GrassObjectID, VoxelCoord(x, spawnCoord.y - 1, z));
        }
      }
    }
  }

  function setObjectAtCoord(uint8 objectTypeId, VoxelCoord memory coord) internal {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      entityId = getUniqueEntity();
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      if (ObjectType._get(entityId) == objectTypeId) {
        // no-op
        return;
      }
    }
    ObjectType._set(entityId, objectTypeId);
    Position._set(entityId, coord.x, coord.y, coord.z);
  }
}
