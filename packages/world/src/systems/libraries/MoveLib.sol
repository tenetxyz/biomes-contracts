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
  function movePlayer(
    EntityId playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newCoords
  ) public returns (bool, VoxelCoord memory) {
    VoxelCoord[] memory relativePositions = getObjectTypeSchema(PlayerObjectID);
    EntityId[] memory playerEntityIds = new EntityId[](relativePositions.length + 1);
    playerEntityIds[0] = playerEntityId;

    VoxelCoord[] memory relativeCoords = new VoxelCoord[](relativePositions.length);
    for (uint256 i = 0; i < relativePositions.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        playerCoord.x + relativePositions[i].x,
        playerCoord.y + relativePositions[i].y,
        playerCoord.z + relativePositions[i].z
      );
      playerEntityIds[i + 1] = relativeCoord.getPlayer();
      relativeCoords[i] = relativeCoord;
      // TODO: do we need this check?
      require(playerEntityIds[i + 1].baseEntityId() == playerEntityId, "Base entity mismatch");
    }

    bool gravityAppliesForCoord = false;
    {
      uint256 numJumps = 0;
      uint256 numFalls = 0;
      uint256 numGlides = 0;
      VoxelCoord memory oldCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);
      for (uint256 i = 0; i < newCoords.length; i++) {
        VoxelCoord memory newCoord = newCoords[i];
        (, gravityAppliesForCoord) = move(playerEntityIds, oldCoord, newCoord);

        for (uint256 j = 0; j < relativePositions.length; j++) {
          VoxelCoord memory oldRelativeCoord = VoxelCoord(
            oldCoord.x + relativePositions[j].x,
            oldCoord.y + relativePositions[j].y,
            oldCoord.z + relativePositions[j].z
          );
          VoxelCoord memory newRelativeCoord = VoxelCoord(
            newCoord.x + relativePositions[j].x,
            newCoord.y + relativePositions[j].y,
            newCoord.z + relativePositions[j].z
          );
          move(playerEntityIds, oldRelativeCoord, newRelativeCoord);
        }

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
    }

    VoxelCoord memory finalCoord = newCoords[newCoords.length - 1];
    if (!VoxelCoordLib.equals(finalCoord, playerCoord)) {
      ReversePlayerPosition._deleteRecord(playerCoord.x, playerCoord.y, playerCoord.z);
      finalCoord.setPlayer(playerEntityId);

      for (uint256 i = 0; i < relativePositions.length; i++) {
        ReversePlayerPosition._deleteRecord(relativeCoords[i].x, relativeCoords[i].y, relativeCoords[i].z);
        VoxelCoord memory newRelativeCoord = VoxelCoord(
          finalCoord.x + relativePositions[i].x,
          finalCoord.y + relativePositions[i].y,
          finalCoord.z + relativePositions[i].z
        );
        newRelativeCoord.setPlayer(playerEntityIds[i + 1]);
      }
    }

    transferEnergyFromPlayerToPool(
      playerEntityId,
      playerCoord,
      Energy._get(playerEntityId),
      PLAYER_MOVE_ENERGY_COST * uint128(newCoords.length)
    );

    return (gravityAppliesForCoord, finalCoord);
  }

  function move(
    EntityId[] memory playerEntityIds,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal view returns (EntityId, bool) {
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

    return (newEntityId, gravityApplies(newCoord));
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
