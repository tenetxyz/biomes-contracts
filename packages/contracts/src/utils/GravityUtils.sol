// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { GRAVITY_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { getTerrainObjectTypeId } from "../Utils.sol";
import { transferAllInventoryEntities } from "./InventoryUtils.sol";
import { despawnPlayer } from "./PlayerUtils.sol";

// Note: Implemented in utils, so we can reuse it in other systems, without having to call another system
function applyGravity(bytes32 playerEntityId, VoxelCoord memory coord) returns (bool) {
  VoxelCoord memory newCoord = VoxelCoord(coord.x, coord.y - 1, coord.z);

  bytes32 newEntityId = ReversePosition.get(newCoord.x, newCoord.y, newCoord.z);
  if (newEntityId == bytes32(0)) {
    // Check terrain block type
    if (getTerrainObjectTypeId(AirObjectID, newCoord) != AirObjectID) {
      return false;
    }

    // Create new entity
    newEntityId = getUniqueEntity();
    ObjectType.set(newEntityId, AirObjectID);
  } else {
    if (ObjectType.get(newEntityId) != AirObjectID) {
      return false;
    }

    // Transfer any dropped items
    transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
  }

  // Swap entity ids
  ReversePosition.set(coord.x, coord.y, coord.z, newEntityId);
  Position.set(newEntityId, coord.x, coord.y, coord.z);

  Position.set(playerEntityId, newCoord.x, newCoord.y, newCoord.z);
  ReversePosition.set(newCoord.x, newCoord.y, newCoord.z, playerEntityId);

  uint16 currentHealth = Health.getHealth(playerEntityId);
  uint16 newHealth = currentHealth > GRAVITY_DAMAGE ? currentHealth - GRAVITY_DAMAGE : 0;
  Health.setHealth(playerEntityId, newHealth);

  if (newHealth == 0) {
    despawnPlayer(playerEntityId);
    return true;
  }

  // Recursively apply gravity until the player is on the ground or dead
  applyGravity(playerEntityId, newCoord);
  return true;
}
