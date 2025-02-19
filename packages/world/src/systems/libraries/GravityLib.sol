// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../../Types.sol";

import { PlayerPosition } from "../../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../../codegen/tables/ReversePlayerPosition.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";

import { ObjectTypeId, AirObjectID, WaterObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { inWorldBorder, getUniqueEntity } from "../../Utils.sol";
import { TerrainLib } from "./TerrainLib.sol";
import { EntityId } from "../../EntityId.sol";

library GravityLib {
  function runGravity(EntityId playerEntityId, VoxelCoord memory playerCoord) public returns (bool) {
    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    (EntityId belowEntityId, ObjectTypeId belowObjectTypeId) = belowCoord.getOrCreateEntity();
    if (belowObjectTypeId != AirObjectID && belowObjectTypeId != WaterObjectID) {
      return false;
    }
    if (belowCoord.getPlayer().exists()) {
      return false;
    }

    ReversePlayerPosition._deleteRecord(playerCoord.x, playerCoord.y, playerCoord.z);

    PlayerPosition._set(playerEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
    ReversePlayerPosition._set(belowCoord.x, belowCoord.y, belowCoord.z, playerEntityId);

    if (PlayerActivity._get(playerEntityId) != uint128(block.timestamp)) {
      PlayerActivity._set(playerEntityId, uint128(block.timestamp));
    }

    // TODO: apply some energy cost for gravity

    // Check if entity above player is another player, if so we need to apply gravity to that player
    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    EntityId aboveEntityId = aboveCoord.getPlayer();
    if (aboveEntityId.exists()) {
      runGravity(aboveEntityId, aboveCoord);
    }

    // TODO: check if player is dead
    // Recursively apply gravity until the player is on the ground or dead
    runGravity(playerEntityId, belowCoord);

    return true;
  }
}
