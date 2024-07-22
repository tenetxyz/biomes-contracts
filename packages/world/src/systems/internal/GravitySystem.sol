// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Position, PositionData } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Health, HealthData } from "../../codegen/tables/Health.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";

import { GRAVITY_DAMAGE } from "../../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../../Utils.sol";
import { transferAllInventoryEntities } from "../../utils/InventoryUtils.sol";
import { regenHealth, despawnPlayer } from "../../utils/PlayerUtils.sol";

contract GravitySystem is System {
  function runGravity(bytes32 playerEntityId, VoxelCoord memory playerCoord) public returns (bool) {
    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(belowCoord);
      if (terrainObjectTypeId != AirObjectID && terrainObjectTypeId != WaterObjectID) {
        return false;
      }

      // Create new entity
      belowEntityId = getUniqueEntity();
      ObjectType._set(belowEntityId, AirObjectID);
    } else {
      if (ObjectType._get(belowEntityId) != AirObjectID) {
        return false;
      }

      // Transfer any dropped items
      transferAllInventoryEntities(belowEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, belowEntityId);
    Position._set(belowEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    Position._set(playerEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
    ReversePosition._set(belowCoord.x, belowCoord.y, belowCoord.z, playerEntityId);

    if (PlayerActivity._get(playerEntityId) != block.timestamp) {
      PlayerActivity._set(playerEntityId, block.timestamp);
    }

    uint16 currentHealth = regenHealth(playerEntityId);
    uint16 newHealth = currentHealth > GRAVITY_DAMAGE ? currentHealth - GRAVITY_DAMAGE : 0;
    Health._setHealth(playerEntityId, newHealth);

    if (newHealth == 0) {
      despawnPlayer(playerEntityId);
    }

    // Check if entity above player is another player, if so we need to apply gravity to that player
    bytes32 aboveEntityId = ReversePosition._get(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      runGravity(aboveEntityId, VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z));
    }

    if (newHealth > 0) {
      // Recursively apply gravity until the player is on the ground or dead
      runGravity(playerEntityId, belowCoord);
    }

    return true;
  }
}
