// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordLib } from "../../VoxelCoord.sol";

import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { PlayerPosition } from "../../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../../codegen/tables/ReversePlayerPosition.sol";
import { ActionType } from "../../codegen/common.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { gravityApplies, inWorldBorder } from "../../Utils.sol";
import { PLAYER_MOVE_ENERGY_COST } from "../../Constants.sol";
import { notify, MoveNotifData } from "../../utils/NotifUtils.sol";
import { TerrainLib } from "./TerrainLib.sol";
import { EntityId } from "../../EntityId.sol";
import { transferEnergyFromPlayerToPool } from "../../utils/EnergyUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";
import { getObjectTypeSchema } from "../../utils/ObjectTypeUtils.sol";

library MoveLib {
  function _requireValidMove(
    EntityId[] memory playerEntityIds,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal view returns (bool) {
    require(inWorldBorder(newCoord), "Cannot move outside the world border");
    require(oldCoord.inSurroundingCube(1, newCoord), "New coord is too far from old coord");

    (EntityId newEntityId, ObjectTypeId newObjectTypeId) = newCoord.getEntity();
    require(ObjectTypeMetadata._getCanPassThrough(newObjectTypeId), "Cannot move through a non-passable block");

    EntityId playerEntityIdAtCoord = newCoord.getPlayer();
    if (playerEntityIdAtCoord.exists()) {
      // If the entity we're moving into is this player, then it's fine as
      // the player will be moved from the old position to the new position
      bool isSelf = false;
      for (uint256 i = 0; i < playerEntityIds.length; i++) {
        if (playerEntityIds[i] == playerEntityIdAtCoord) {
          isSelf = true;
          break;
        }
      }
      require(isSelf, "Cannot move through a player");
    }

    return gravityApplies(newCoord);
  }

  function _requireValidPath(
    EntityId[] memory playerEntityIds,
    VoxelCoord[] memory playerCoords,
    VoxelCoord[] memory newCoords
  ) internal view returns (bool, VoxelCoord[] memory) {
    bool gravityAppliesForMove = false;
    VoxelCoord[] memory newPlayerCoords = new VoxelCoord[](playerCoords.length);

    uint256 numJumps = 0;
    uint256 numFalls = 0;
    uint256 numGlides = 0;

    VoxelCoord[] memory oldPlayerCoords = new VoxelCoord[](playerCoords.length);
    for (uint256 i = 0; i < playerCoords.length; i++) {
      oldPlayerCoords[i] = VoxelCoord(playerCoords[i].x, playerCoords[i].y, playerCoords[i].z);
    }
    for (uint256 i = 0; i < newCoords.length; i++) {
      newPlayerCoords = newCoords[i].getRelativeCoords(PlayerObjectID);
      for (uint256 j = 0; j < newPlayerCoords.length; j++) {
        bool gravityAppliesForNewCoord = _requireValidMove(playerEntityIds, oldPlayerCoords[j], newPlayerCoords[j]);
        // We only need to check gravity on the base coord as players are always 1 block high
        if (j == 0) {
          gravityAppliesForMove = gravityAppliesForNewCoord;
        }
      }

      if (gravityAppliesForMove) {
        if (oldPlayerCoords[0].y < newPlayerCoords[0].y) {
          numJumps++;
          require(numJumps <= 3, "Cannot jump more than 3 blocks");
        } else if (oldPlayerCoords[0].y > newPlayerCoords[0].y) {
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

      oldPlayerCoords = newPlayerCoords;
    }

    return (gravityAppliesForMove, newPlayerCoords);
  }

  function movePlayer(
    EntityId playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newCoords
  ) public returns (bool, VoxelCoord memory) {
    VoxelCoord[] memory playerCoords = playerCoord.getRelativeCoords(PlayerObjectID);
    EntityId[] memory playerEntityIds = new EntityId[](playerCoords.length);
    playerEntityIds[0] = playerEntityId;

    // Only iterate through relative schema coords
    for (uint256 i = 1; i < playerCoords.length; i++) {
      playerEntityIds[i] = playerCoords[i].getPlayer();
      // TODO: do we need this check?
      require(playerEntityIds[i].baseEntityId() == playerEntityId, "Base entity mismatch");
    }

    (bool gravityAppliesForMove, VoxelCoord[] memory newPlayerCoords) = _requireValidPath(
      playerEntityIds,
      playerCoords,
      newCoords
    );

    VoxelCoord memory finalPlayerCoord = newPlayerCoords[0];
    if (!VoxelCoordLib.equals(finalPlayerCoord, playerCoords[0])) {
      for (uint256 i = 0; i < playerCoords.length; i++) {
        ReversePlayerPosition._deleteRecord(playerCoords[i].x, playerCoords[i].y, playerCoords[i].z);
      }

      for (uint256 i = 0; i < newPlayerCoords.length; i++) {
        newPlayerCoords[i].setPlayer(playerEntityIds[i]);
      }
    }

    transferEnergyFromPlayerToPool(
      playerEntityId,
      playerCoord,
      Energy._get(playerEntityId),
      PLAYER_MOVE_ENERGY_COST * uint128(newCoords.length)
    );

    return (gravityAppliesForMove, finalPlayerCoord);
  }

  function movePlayerWithGravity(
    EntityId playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newCoords
  ) public {
    (bool gravityAppliesForCoord, VoxelCoord memory finalCoord) = movePlayer(playerEntityId, playerCoord, newCoords);

    if (gravityAppliesForCoord) {
      runGravity(playerEntityId, finalCoord);
    }

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    EntityId aboveEntityId = aboveCoord.getPlayer();
    if (aboveEntityId.exists() && aboveEntityId.isBaseEntity()) {
      runGravity(aboveEntityId, aboveCoord);
    }
  }

  function runGravity(EntityId playerEntityId, VoxelCoord memory playerCoord) public returns (bool) {
    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    (, ObjectTypeId belowObjectTypeId) = belowCoord.getEntity();
    if (!ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId)) {
      return false;
    }
    if (belowCoord.getPlayer().exists()) {
      return false;
    }

    // TODO: apply gravity cost

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = belowCoord;
    movePlayerWithGravity(playerEntityId, playerCoord, newCoords);

    return true;
  }
}
