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
import { Inventory } from "../codegen/tables/Inventory.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { MIN_BLOCKS_TO_LOGOFF_AFTER_HIT, MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getTerrainObjectTypeId, callGravity } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "../Constants.sol";

contract LoginSystem is System {
  function loginPlayer(VoxelCoord memory respawnCoord) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "LoginSystem: player does not exist");
    require(PlayerMetadata.getIsLoggedOff(playerEntityId), "LoginSystem: player already logged in");

    VoxelCoord memory lastKnownCoord = lastKnownPositionDataToVoxelCoord(LastKnownPosition.get(playerEntityId));
    require(
      respawnCoord.x >= lastKnownCoord.x - MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.x <= lastKnownCoord.x + MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.z >= lastKnownCoord.z - MAX_PLAYER_RESPAWN_HALF_WIDTH &&
        respawnCoord.z <= lastKnownCoord.z + MAX_PLAYER_RESPAWN_HALF_WIDTH,
      "LoginSystem: respawn coord too far from last known position"
    );

    bytes32 respawnEntityId = ReversePosition.get(respawnCoord.x, respawnCoord.y, respawnCoord.z);
    if (respawnEntityId == bytes32(0)) {
      // Check terrain block type
      require(
        getTerrainObjectTypeId(AirObjectID, respawnCoord) == AirObjectID,
        "LoginSystem: cannot respawn on terrain non-air block"
      );
    } else {
      require(ObjectType.get(respawnEntityId) == AirObjectID, "LoginSystem: cannot respawn on non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(respawnEntityId, playerEntityId, PlayerObjectID);

      ObjectType.deleteRecord(respawnEntityId);
      Position.deleteRecord(respawnEntityId);
    }

    Position.set(playerEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition.set(respawnCoord.x, respawnCoord.y, respawnCoord.z, playerEntityId);
    LastKnownPosition.deleteRecord(playerEntityId);
    PlayerMetadata.setIsLoggedOff(playerEntityId, false);

    // Reset update blocks to current block
    Health.setLastUpdateBlock(playerEntityId, block.number);
    Stamina.setLastUpdateBlock(playerEntityId, block.number);

    // We let the user pick a y coord, so we need to apply gravity
    VoxelCoord memory belowCoord = VoxelCoord(respawnCoord.x, respawnCoord.y - 1, respawnCoord.z);
    bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType.get(belowEntityId) == AirObjectID) {
      require(!callGravity(playerEntityId, respawnCoord), "LoginSystem: cannot respawn player with gravity");
    }
  }
}
