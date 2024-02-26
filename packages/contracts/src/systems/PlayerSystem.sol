// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";

import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "../Types.sol";
import { AirObjectID, PlayerObjectID, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA } from "../Constants.sol";

int32 constant SPAWN_LOW_X = 200;
int32 constant SPAWN_HIGH_X = 300;
int32 constant SPAWN_LOW_Z = 200;
int32 constant SPAWN_HIGH_Z = 300;

contract PlayerSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public {
    address newPlayer = _msgSender();
    require(Player.get(newPlayer) == bytes32(0), "PlayerSystem: player already exists");

    // Check spawn coord is within spawn area
    require(spawnCoord.x >= SPAWN_LOW_X && spawnCoord.x <= SPAWN_HIGH_X, "PlayerSystem: x coord out of bounds");
    require(spawnCoord.z >= SPAWN_LOW_Z && spawnCoord.z <= SPAWN_HIGH_Z, "PlayerSystem: z coord out of bounds");
    require(spawnCoord.y == 0, "PlayerSystem: y coord out of bounds");

    bytes32 entityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    if (entityId == bytes32(0)) {
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

    PlayerMetadata.set(entityId, block.number, 0);
    Health.set(entityId, block.number, MAX_PLAYER_HEALTH);
    Stamina.set(entityId, block.number, MAX_PLAYER_STAMINA);
  }
}
