// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory, InventoryTableId } from "../codegen/tables/Inventory.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { MIN_BLOCKS_TO_LOGOFF_AFTER_HIT, MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getTerrainObjectTypeId } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { applyGravity } from "../utils/GravityUtils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "../Constants.sol";

contract PlayerSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (bytes32) {
    address newPlayer = _msgSender();
    require(Player.get(newPlayer) == bytes32(0), "PlayerSystem: player already exists");

    // Check spawn coord is within spawn area
    require(
      spawnCoord.x >= SPAWN_LOW_X &&
        spawnCoord.x <= SPAWN_HIGH_X &&
        spawnCoord.z >= SPAWN_LOW_Z &&
        spawnCoord.z <= SPAWN_HIGH_Z,
      "PlayerSystem: coord outside of spawn area"
    );

    bytes32 entityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    if (entityId == bytes32(0)) {
      require(
        getTerrainObjectTypeId(AirObjectID, spawnCoord) == AirObjectID,
        "PlayerSystem: cannot spawn on terrain non-air block"
      );

      // Create new entity
      entityId = getUniqueEntity();
      Position.set(entityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
      ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, entityId);
    } else {
      require(ObjectType.get(entityId) == AirObjectID, "PlayerSystem: spawn coord is not air");
    }

    // Set object type to player
    ObjectType.set(entityId, PlayerObjectID);
    Player.set(newPlayer, entityId);
    ReversePlayer.set(entityId, newPlayer);

    Health.set(entityId, block.number, MAX_PLAYER_HEALTH);
    Stamina.set(entityId, block.number, MAX_PLAYER_STAMINA);

    // We let the user pick a y coord, so we need to apply gravity
    VoxelCoord memory belowCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType.get(belowEntityId) == AirObjectID) {
      require(!applyGravity(entityId, spawnCoord), "PlayerSystem: cannot spawn player with gravity");
    }

    return entityId;
  }

  function loginPlayer(VoxelCoord memory respawnCoord) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "PlayerSystem: player does not exist");

    VoxelCoord memory coord = positionDataToVoxelCoord(Position.get(playerEntityId));
    require(ReversePosition.get(coord.x, coord.y, coord.z) != playerEntityId, "PlayerSystem: player already logged in");

    VoxelCoord memory lastKnownCoord = lastKnownPositionDataToVoxelCoord(LastKnownPosition.get(playerEntityId));
    require(
      respawnCoord.x >= lastKnownCoord.x - MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.x <= lastKnownCoord.x + MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.z >= lastKnownCoord.z - MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.z <= lastKnownCoord.z + MAX_PLAYER_RESPAWN_HALF_WIDTH,
      "PlayerSystem: respawn coord too far from last known position"
    );

    bytes32 respawnEntityId = ReversePosition.get(respawnCoord.x, respawnCoord.y, respawnCoord.z);
    if (respawnEntityId == bytes32(0)) {
      // Check terrain block type
      require(
        getTerrainObjectTypeId(AirObjectID, respawnCoord) == AirObjectID,
        "PlayerSystem: cannot respawn on terrain non-air block"
      );
    } else {
      require(ObjectType.get(respawnEntityId) == AirObjectID, "PlayerSystem: cannot respawn on non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(respawnEntityId, playerEntityId, PlayerObjectID);

      ObjectType.deleteRecord(respawnEntityId);
      Position.deleteRecord(respawnEntityId);
    }

    Position.set(playerEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition.set(respawnCoord.x, respawnCoord.y, respawnCoord.z, playerEntityId);
    LastKnownPosition.deleteRecord(playerEntityId);

    // Reset update blocks to current block
    Health.setLastUpdateBlock(playerEntityId, block.number);
    Stamina.setLastUpdateBlock(playerEntityId, block.number);

    // We let the user pick a y coord, so we need to apply gravity
    VoxelCoord memory belowCoord = VoxelCoord(respawnCoord.x, respawnCoord.y - 1, respawnCoord.z);
    bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType.get(belowEntityId) == AirObjectID) {
      require(!applyGravity(playerEntityId, respawnCoord), "PlayerSystem: cannot respawn player with gravity");
    }
  }

  function logoffPlayer() public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "PlayerSystem: player does not exist");
    uint256 lastHitBlock = PlayerMetadata.getLastHitBlock(playerEntityId);
    require(
      block.number - lastHitBlock > MIN_BLOCKS_TO_LOGOFF_AFTER_HIT,
      "PlayerSystem: player needs to wait before logging off as they were recently hit"
    );

    VoxelCoord memory coord = positionDataToVoxelCoord(Position.get(playerEntityId));
    require(ReversePosition.get(coord.x, coord.y, coord.z) == playerEntityId, "PlayerSystem: player isn't logged in");

    LastKnownPosition.set(playerEntityId, coord.x, coord.y, coord.z);
    Position.deleteRecord(playerEntityId);

    // Create air entity at this position
    bytes32 airEntityId = getUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, airEntityId);
  }

  function activatePlayer(bytes32 playerEntityId) public {
    regenHealth(playerEntityId);
    regenStamina(playerEntityId);
  }
}
