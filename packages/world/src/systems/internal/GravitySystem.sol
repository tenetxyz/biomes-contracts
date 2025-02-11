// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../../Types.sol";

import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { inWorldBorder } from "../../Utils.sol";
import { transferAllInventoryEntities } from "../../utils/InventoryUtils.sol";

import { EntityId } from "../../EntityId.sol";

contract GravitySystem is System {
  function runGravity(EntityId playerEntityId, VoxelCoord memory playerCoord) public returns (bool) {
    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    EntityId belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    require(belowEntityId.exists(), "Attempted to apply gravity but encountered an unrevealed block");
    uint16 belowObjectTypeId = ObjectType._get(belowEntityId);
    // TODO: deal with florae
    if (belowObjectTypeId != AirObjectID && belowObjectTypeId != WaterObjectID) {
      return false;
    }

    // Transfer any dropped items
    transferAllInventoryEntities(belowEntityId, playerEntityId, PlayerObjectID);

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, belowEntityId);
    Position._set(belowEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    Position._set(playerEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
    ReversePosition._set(belowCoord.x, belowCoord.y, belowCoord.z, playerEntityId);

    if (PlayerActivity._get(playerEntityId) != uint128(block.timestamp)) {
      PlayerActivity._set(playerEntityId, uint128(block.timestamp));
    }

    // TODO: apply some energy cost for gravity

    // Check if entity above player is another player, if so we need to apply gravity to that player
    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    EntityId aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId.exists() && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      runGravity(aboveEntityId, aboveCoord);
    }

    // TODO: check if player is dead
    // Recursively apply gravity until the player is on the ground or dead
    runGravity(playerEntityId, belowCoord);

    return true;
  }
}
