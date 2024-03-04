// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";

import { Position, PositionData } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Inventory, InventoryTableId } from "../codegen/tables/Inventory.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { GRAVITY_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { getTerrainObjectTypeId } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, transferAllInventoryEntities } from "./InventoryUtils.sol";
import { despawnPlayer } from "./PlayerUtils.sol";

function applyGravity(bytes32 playerEntityId, VoxelCoord memory coord) returns (bool) {
  VoxelCoord memory newCoord = VoxelCoord(coord.x, coord.y - 1, coord.z);

  bytes32 newEntityId = ReversePosition.get(newCoord.x, newCoord.y, newCoord.z);
  if (newEntityId == bytes32(0)) {
    // Check terrain block type
    if (getTerrainObjectTypeId(newCoord) != AirObjectID) {
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
