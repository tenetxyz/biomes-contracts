// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Position, PositionData } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { GRAVITY_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { getTerrainObjectTypeId } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { despawnPlayer } from "../utils/PlayerUtils.sol";

contract GravitySystem is System {
  function runGravity(bytes32 playerEntityId, VoxelCoord memory coord) public returns (bool) {
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
    }

    // Check if entity above player is another player, if so we need to apply gravity to that player
    bytes32 aboveEntityId = ReversePosition.get(coord.x, coord.y + 1, coord.z);
    if (aboveEntityId != bytes32(0) && ObjectType.get(aboveEntityId) == PlayerObjectID) {
      runGravity(aboveEntityId, VoxelCoord(coord.x, coord.y + 1, coord.z));
    }

    if (newHealth > 0) {
      // Recursively apply gravity until the player is on the ground or dead
      runGravity(playerEntityId, newCoord);
    }

    return true;
  }
}
