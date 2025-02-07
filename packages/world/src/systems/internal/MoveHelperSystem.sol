// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../../codegen/common.sol";

import { AirObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { callGravity, gravityApplies, inWorldBorder } from "../../Utils.sol";
import { transferAllInventoryEntities } from "../../utils/InventoryUtils.sol";

contract MoveHelperSystem is System {
  function movePlayer(bytes32 playerEntityId, VoxelCoord memory playerCoord, VoxelCoord[] memory newCoords) public {
    // no-ops
    if (newCoords.length == 0) {
      return;
    } else if (newCoords.length == 1 && voxelCoordsAreEqual(playerCoord, newCoords[0])) {
      return;
    }

    VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);

    bytes32 finalEntityId;
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
      callGravity(playerEntityId, finalCoord);
    }

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      callGravity(aboveEntityId, aboveCoord);
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Move,
        entityId: finalEntityId,
        objectTypeId: PlayerObjectID,
        coordX: finalCoord.x,
        coordY: finalCoord.y,
        coordZ: finalCoord.z,
        amount: newCoords.length
      })
    );
  }

  function move(
    bytes32 playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal returns (bytes32, bool) {
    require(inWorldBorder(newCoord), "Cannot move outside the world border");
    require(inSurroundingCube(oldCoord, 1, newCoord), "New coord is too far from old coord");

    bytes32 newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    require(newEntityId != bytes32(0), "Cannot move to an unrevealed block");

    // If the entity we're moving into is this player, then it's fine as
    // the player will be moved from the old position to the new position
    if (playerEntityId != newEntityId) {
      uint16 currentObjectTypeId = ObjectType._get(newEntityId);
      // TODO: check for water and florae
      require(currentObjectTypeId == AirObjectID, "Cannot move through a non-air block");
    }

    return (newEntityId, gravityApplies(newCoord));
  }
}
