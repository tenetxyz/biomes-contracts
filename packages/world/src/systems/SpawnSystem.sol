// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

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

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, BasaltCarvedObjectID, StoneObjectID, DirtObjectID, GrassObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity, positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, gravityApplies, inWorldBorder, inSpawnArea, getTerrainObjectTypeId } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract SpawnSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (bytes32) {
    address newPlayer = _msgSender();
    require(Player._get(newPlayer) == bytes32(0), "SpawnSystem: player already exists");
    require(inWorldBorder(spawnCoord), "SpawnSystem: cannot spawn outside world border");
    require(inSpawnArea(spawnCoord), "SpawnSystem: cannot spawn outside spawn area");

    bytes32 existingEntityId = ReversePosition._get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    bytes32 playerEntityId = getUniqueEntity();
    if (existingEntityId == bytes32(0)) {
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(spawnCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "SpawnSystem: cannot spawn on terrain non-air block"
      );
    } else {
      require(ObjectType._get(existingEntityId) == AirObjectID, "SpawnSystem: spawn coord is not air");

      // Transfer any dropped items
      transferAllInventoryEntities(existingEntityId, playerEntityId, PlayerObjectID);

      Position._deleteRecord(existingEntityId);
    }
    // Create new entity
    Position._set(playerEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
    ReversePosition._set(spawnCoord.x, spawnCoord.y, spawnCoord.z, playerEntityId);

    // Set object type to player
    ObjectType._set(playerEntityId, PlayerObjectID);
    Player._set(newPlayer, playerEntityId);
    ReversePlayer._set(playerEntityId, newPlayer);

    Health._set(playerEntityId, block.timestamp, MAX_PLAYER_HEALTH);
    Stamina._set(playerEntityId, block.timestamp, MAX_PLAYER_STAMINA);

    // We let the user pick a y coord, so we need to apply gravity
    require(!gravityApplies(playerEntityId, spawnCoord), "SpawnSystem: cannot spawn player with gravity");

    return playerEntityId;
  }

  function initSpawnAreaTop() public {
    int16 midPointX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
    for (int16 x = SPAWN_LOW_X; x <= midPointX; x++) {
      for (int16 z = SPAWN_LOW_Z; z <= SPAWN_HIGH_Z; z++) {
        if (x == SPAWN_LOW_X || x == SPAWN_HIGH_X || z == SPAWN_LOW_Z || z == SPAWN_HIGH_Z) {
          setObjectAtCoord(BasaltCarvedObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
        } else {
          setObjectAtCoord(StoneObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
        }
      }
    }
  }

  function initSpawnAreaTopPart2() public {
    int16 midPointX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
    for (int16 x = midPointX + 1; x <= SPAWN_HIGH_X; x++) {
      for (int16 z = SPAWN_LOW_Z; z <= SPAWN_HIGH_Z; z++) {
        if (x == SPAWN_LOW_X || x == SPAWN_HIGH_X || z == SPAWN_LOW_Z || z == SPAWN_HIGH_Z) {
          setObjectAtCoord(BasaltCarvedObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
        } else {
          setObjectAtCoord(StoneObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
        }
      }
    }
  }

  function initSpawnAreaBottom() public {
    int16 midPointX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
    for (int16 x = SPAWN_LOW_X; x <= midPointX; x++) {
      for (int16 z = SPAWN_LOW_Z; z <= SPAWN_HIGH_Z; z++) {
        setObjectAtCoord(DirtObjectID, VoxelCoord(x, SPAWN_GROUND_Y - 1, z));
      }
    }
  }

  function initSpawnAreaBottomPart2() public {
    int16 midPointX = (SPAWN_LOW_X + SPAWN_HIGH_X) / 2;
    for (int16 x = midPointX + 1; x <= SPAWN_HIGH_X; x++) {
      for (int16 z = SPAWN_LOW_Z; z <= SPAWN_HIGH_Z; z++) {
        setObjectAtCoord(DirtObjectID, VoxelCoord(x, SPAWN_GROUND_Y - 1, z));
      }
    }
  }

  function initSpawnAreaBottomBorder() public {
    require(UniqueEntity._get() == 0, "SpawnSystem: spawn area already initialized");
    for (int16 x = SPAWN_LOW_X - 1; x <= SPAWN_HIGH_X + 1; x++) {
      for (int16 z = SPAWN_LOW_Z - 1; z <= SPAWN_HIGH_Z + 1; z++) {
        if (x == SPAWN_LOW_X - 1 || x == SPAWN_HIGH_X + 1 || z == SPAWN_LOW_Z - 1 || z == SPAWN_HIGH_Z + 1) {
          setObjectAtCoord(GrassObjectID, VoxelCoord(x, SPAWN_GROUND_Y - 1, z));
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
