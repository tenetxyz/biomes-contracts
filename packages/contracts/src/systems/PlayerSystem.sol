// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

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
import { Inventory } from "../codegen/tables/Inventory.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getTerrainObjectTypeId, callGravity } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "../Constants.sol";

contract PlayerSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (bytes32) {
    address newPlayer = _msgSender();
    require(Player._get(newPlayer) == bytes32(0), "PlayerSystem: player already exists");

    // Check spawn coord is within spawn area
    require(
      spawnCoord.x >= SPAWN_LOW_X &&
        spawnCoord.x <= SPAWN_HIGH_X &&
        spawnCoord.z >= SPAWN_LOW_Z &&
        spawnCoord.z <= SPAWN_HIGH_Z,
      "PlayerSystem: coord outside of spawn area"
    );

    bytes32 entityId = ReversePosition._get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    if (entityId == bytes32(0)) {
      require(
        getTerrainObjectTypeId(AirObjectID, spawnCoord) == AirObjectID,
        "PlayerSystem: cannot spawn on terrain non-air block"
      );

      // Create new entity
      entityId = getUniqueEntity();
      Position._set(entityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
      ReversePosition._set(spawnCoord.x, spawnCoord.y, spawnCoord.z, entityId);
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "PlayerSystem: spawn coord is not air");
    }

    // Set object type to player
    ObjectType._set(entityId, PlayerObjectID);
    Player._set(newPlayer, entityId);
    ReversePlayer._set(entityId, newPlayer);

    Health._set(entityId, block.timestamp, MAX_PLAYER_HEALTH);
    Stamina._set(entityId, block.timestamp, MAX_PLAYER_STAMINA);

    // We let the user pick a y coord, so we need to apply gravity
    VoxelCoord memory belowCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType._get(belowEntityId) == AirObjectID) {
      require(!callGravity(entityId, spawnCoord), "PlayerSystem: cannot spawn player with gravity");
    }

    return entityId;
  }

  // function changePlayerOwner(address newOwner) public {
  //   bytes32 playerEntityId = Player._get(_msgSender());
  //   require(playerEntityId != bytes32(0), "PlayerSystem: player does not exist");
  //   require(Player._get(newOwner) == bytes32(0), "PlayerSystem: new owner already has a player");
  //   Player._deleteRecord(_msgSender());
  //   Player._set(newOwner, playerEntityId);
  //   ReversePlayer._set(playerEntityId, newOwner);
  // }
}
