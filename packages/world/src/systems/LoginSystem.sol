// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

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

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, callGravity, inWorldBorder } from "../Utils.sol";
import { getTerrainObjectTypeId } from "../utils/TerrainUtils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract LoginSystem is System {
  function loginPlayer(VoxelCoord memory respawnCoord) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "LoginSystem: player does not exist");
    require(PlayerMetadata._getIsLoggedOff(playerEntityId), "LoginSystem: player already logged in");

    VoxelCoord memory lastKnownCoord = lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(playerEntityId));
    require(inWorldBorder(respawnCoord), "LoginSystem: cannot respawn outside world border");
    require(
      respawnCoord.x >= lastKnownCoord.x - MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.x <= lastKnownCoord.x + MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.z >= lastKnownCoord.z - MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.z <= lastKnownCoord.z + MAX_PLAYER_RESPAWN_HALF_WIDTH,
      "LoginSystem: respawn coord too far from last known position"
    );

    bytes32 respawnEntityId = ReversePosition._get(respawnCoord.x, respawnCoord.y, respawnCoord.z);
    if (respawnEntityId == bytes32(0)) {
      // Check terrain block type
      require(
        getTerrainObjectTypeId(respawnCoord) == AirObjectID,
        "LoginSystem: cannot respawn on terrain non-air block"
      );
    } else {
      require(ObjectType._get(respawnEntityId) == AirObjectID, "LoginSystem: cannot respawn on non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(respawnEntityId, playerEntityId, PlayerObjectID);

      Position._deleteRecord(respawnEntityId);
    }

    Position._set(playerEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition._set(respawnCoord.x, respawnCoord.y, respawnCoord.z, playerEntityId);
    LastKnownPosition._deleteRecord(playerEntityId);
    PlayerMetadata._setIsLoggedOff(playerEntityId, false);

    // Reset update blocks to current block
    Health._setLastUpdatedTime(playerEntityId, block.timestamp);
    Stamina._setLastUpdatedTime(playerEntityId, block.timestamp);

    // We let the user pick a y coord, so we need to apply gravity
    VoxelCoord memory belowCoord = VoxelCoord(respawnCoord.x, respawnCoord.y - 1, respawnCoord.z);
    bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType._get(belowEntityId) == AirObjectID) {
      require(!callGravity(playerEntityId, respawnCoord), "LoginSystem: cannot respawn player with gravity");
    }
  }
}
