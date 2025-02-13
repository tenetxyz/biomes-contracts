// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../../Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "../../utils/VoxelCoordUtils.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { ActionType } from "../../codegen/common.sol";

import { AirObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { gravityApplies, inWorldBorder } from "../../Utils.sol";
import { transferAllInventoryEntities } from "../../utils/InventoryUtils.sol";
import { notify, MoveNotifData } from "../../utils/NotifUtils.sol";
import { GravityLib } from "./GravityLib.sol";
import { TerrainLib } from "./TerrainLib.sol";
import { EntityId } from "../../EntityId.sol";

library MoveLib {
  function movePlayer(EntityId playerEntityId, VoxelCoord memory playerCoord, VoxelCoord[] memory newCoords) public {
    // no-ops
    if (newCoords.length == 0) {
      return;
    } else if (newCoords.length == 1 && voxelCoordsAreEqual(playerCoord, newCoords[0])) {
      return;
    }

    VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);

    EntityId finalEntityId;
    bool gravityAppliesForCoord = false;
    uint256 numJumps = 0;
    uint256 numFalls = 0;
    uint256 numGlides = 0;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      (finalEntityId, gravityAppliesForCoord) = move(playerEntityId, oldCoord, newCoord);
      if (gravityAppliesForCoord) {
        if (oldCoord.y < newCoord.y) {
          numJumps++;
          require(numJumps <= 3, "Cannot jump more than 3 blocks");
        } else if (oldCoord.y > newCoord.y) {
          // then we are falling, so should be fine
          numFalls++;
          numGlides = 0;
        } else {
          // we are gliding
          numGlides++;
          require(numGlides <= 10, "Cannot glide more than 10 blocks");
        }
      } else {
        numJumps = 0;
        numGlides = 0;
      }
      oldCoord = VoxelCoord(newCoord.x, newCoord.y, newCoord.z);
    }

    VoxelCoord memory finalCoord = newCoords[newCoords.length - 1];
    if (finalEntityId != playerEntityId) {
      transferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);

      // Swap entity ids
      ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, finalEntityId);
      Position._set(finalEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

      Position._set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
      ReversePosition._set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);
    }

    // TODO: apply energy cost to moving

    if (gravityAppliesForCoord) {
      GravityLib.runGravity(playerEntityId, finalCoord);
    }

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    EntityId aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId.exists() && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      GravityLib.runGravity(aboveEntityId, aboveCoord);
    }

    notify(playerEntityId, MoveNotifData({ moveCoords: newCoords }));
  }

  function move(
    EntityId playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal view returns (EntityId, bool) {
    require(inWorldBorder(newCoord), "Cannot move outside the world border");
    require(inSurroundingCube(oldCoord, 1, newCoord), "New coord is too far from old coord");

    EntityId newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    if (!newEntityId.exists()) {
      uint16 terrainObjectTypeId = TerrainLib._getBlockType(newCoord);
      require(terrainObjectTypeId == AirObjectID, "Cannot move through a non-air block");
    } else {
      // If the entity we're moving into is this player, then it's fine as
      // the player will be moved from the old position to the new position
      if (playerEntityId != newEntityId) {
        uint16 currentObjectTypeId = ObjectType._get(newEntityId);
        // TODO: check for water and florae
        require(currentObjectTypeId == AirObjectID, "Cannot move through a non-air block");
      }
    }

    return (newEntityId, gravityApplies(newCoord));
  }
}
