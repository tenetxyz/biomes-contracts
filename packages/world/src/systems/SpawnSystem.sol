// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity, gravityApplies, inWorldBorder, inSpawnArea, getTerrainObjectTypeId } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";

contract SpawnSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (bytes32) {
    require(inWorldBorder(spawnCoord), "SpawnSystem: cannot spawn outside world border");
    require(inSpawnArea(spawnCoord), "SpawnSystem: cannot spawn outside spawn area");

    address newPlayer = _msgSender();
    require(Player._get(newPlayer) == bytes32(0), "SpawnSystem: player already exists");

    bytes32 playerEntityId = getUniqueEntity();
    bytes32 existingEntityId = ReversePosition._get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
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

    PlayerActivity._set(playerEntityId, block.timestamp);
    PlayerMetadata._set(playerEntityId, false, 0);

    // We let the user pick a y coord, so we need to apply gravity
    require(!gravityApplies(spawnCoord), "SpawnSystem: cannot spawn player with gravity");

    return playerEntityId;
  }
}
