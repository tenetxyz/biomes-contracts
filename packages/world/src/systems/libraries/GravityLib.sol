// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../../Types.sol";

import { ObjectTypeSchema, ObjectTypeSchemaData } from "../../codegen/tables/ObjectTypeSchema.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerPosition } from "../../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../../codegen/tables/ReversePlayerPosition.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";

import { ObjectTypeId, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { inWorldBorder } from "../../Utils.sol";
import { EntityId } from "../../EntityId.sol";

library GravityLib {
  function runGravity(EntityId playerEntityId, VoxelCoord memory playerCoord) public returns (bool) {
    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    (EntityId belowEntityId, ObjectTypeId belowObjectTypeId) = belowCoord.getOrCreateEntity();
    if (!ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId)) {
      return false;
    }
    if (belowCoord.getPlayer().exists()) {
      return false;
    }

    playerCoord.removePlayer();
    belowCoord.setPlayer(playerEntityId);

    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        playerCoord.x + schemaData.relativePositionsX[i],
        playerCoord.y + schemaData.relativePositionsY[i],
        playerCoord.z + schemaData.relativePositionsZ[i]
      );
      EntityId relativeEntityId = relativeCoord.getPlayer();
      relativeCoord.removePlayer();

      VoxelCoord memory newRelativeCoord = VoxelCoord(
        belowCoord.x + schemaData.relativePositionsX[i],
        belowCoord.y + schemaData.relativePositionsY[i],
        belowCoord.z + schemaData.relativePositionsZ[i]
      );
      newRelativeCoord.setPlayer(relativeEntityId);
    }

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
