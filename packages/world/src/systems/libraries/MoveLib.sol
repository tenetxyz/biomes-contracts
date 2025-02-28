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

import { ObjectType, AirObjectID, PlayerObjectID, WaterObjectID } from "../../ObjectType.sol";
import { inWorldBorder } from "../../Utils.sol";
import { PLAYER_MOVE_ENERGY_COST, PLAYER_FALL_ENERGY_COST, MAX_PLAYER_JUMPS, MAX_PLAYER_GLIDES } from "../../Constants.sol";
import { notify, MoveNotifData } from "../../utils/NotifUtils.sol";
import { TerrainLib } from "./TerrainLib.sol";
import { EntityId } from "../../EntityId.sol";
import { transferEnergyToPool } from "../../utils/EnergyUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";
import { getObjectTypeSchema } from "../../utils/ObjectTypeUtils.sol";

library MoveLib {
  function _requireValidMove(VoxelCoord memory baseOldCoord, VoxelCoord memory baseNewCoord) internal view {
    VoxelCoord[] memory oldPlayerCoords = baseOldCoord.getRelativeCoords(PlayerObjectID);
    VoxelCoord[] memory newPlayerCoords = baseNewCoord.getRelativeCoords(PlayerObjectID);

    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      VoxelCoord memory oldCoord = oldPlayerCoords[i];
      VoxelCoord memory newCoord = newPlayerCoords[i];

      require(inWorldBorder(newCoord), "Cannot move outside the world border");
      require(oldCoord.inSurroundingCube(1, newCoord), "New coord is too far from old coord");

      ObjectType newObjectType = newCoord.getObjectType();
      require(ObjectTypeMetadata._getCanPassThrough(newObjectType), "Cannot move through a non-passable block");

      EntityId playerEntityIdAtCoord = newCoord.getPlayer();
      require(!playerEntityIdAtCoord.exists(), "Cannot move through a player");
    }
  }

  function _requireValidPath(
    VoxelCoord[] memory playerCoords,
    VoxelCoord[] memory newBaseCoords
  ) internal view returns (bool, uint16) {
    bool gravityAppliesForMove = false;
    uint16 numJumps = 0;
    uint16 numFalls = 0;
    uint16 numGlides = 0;

    VoxelCoord memory oldBaseCoord = playerCoords[0];
    for (uint256 i = 0; i < newBaseCoords.length; i++) {
      VoxelCoord memory newBaseCoord = newBaseCoords[i];
      _requireValidMove(oldBaseCoord, newBaseCoord);

      gravityAppliesForMove = _gravityApplies(newBaseCoord);
      if (gravityAppliesForMove) {
        if (oldBaseCoord.y < newBaseCoord.y) {
          numJumps++;
          require(numJumps <= MAX_PLAYER_JUMPS, "Cannot jump more than 3 blocks");
        } else if (oldBaseCoord.y > newBaseCoord.y) {
          // then we are falling, so should be fine
          numFalls++;
          numGlides = 0;
        } else {
          // we are gliding
          numGlides++;
          require(numGlides <= MAX_PLAYER_GLIDES, "Cannot glide more than 10 blocks");
        }
      } else {
        numJumps = 0;
        numGlides = 0;
      }

      oldBaseCoord = newBaseCoord;
    }

    return (gravityAppliesForMove, numFalls);
  }

  function _getPlayerEntityIds(
    EntityId basePlayerEntityId,
    VoxelCoord[] memory playerCoords
  ) internal view returns (EntityId[] memory) {
    EntityId[] memory playerEntityIds = new EntityId[](playerCoords.length);
    playerEntityIds[0] = basePlayerEntityId;
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < playerCoords.length; i++) {
      playerEntityIds[i] = playerCoords[i].getPlayer();
    }
    return playerEntityIds;
  }

  function movePlayer(
    EntityId playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newBaseCoords
  ) public returns (bool) {
    VoxelCoord[] memory playerCoords = playerCoord.getRelativeCoords(PlayerObjectID);
    EntityId[] memory playerEntityIds = _getPlayerEntityIds(playerEntityId, playerCoords);

    // Remove the current player from the grid
    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReversePlayerPosition._deleteRecord(playerCoords[i].x, playerCoords[i].y, playerCoords[i].z);
    }

    (bool gravityAppliesForMove, uint16 numFalls) = _requireValidPath(playerCoords, newBaseCoords);

    VoxelCoord memory finalPlayerCoord = newBaseCoords[newBaseCoords.length - 1];
    VoxelCoord[] memory newPlayerCoords = finalPlayerCoord.getRelativeCoords(PlayerObjectID);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      newPlayerCoords[i].setPlayer(playerEntityIds[i]);
    }

    uint128 energyCost = (PLAYER_MOVE_ENERGY_COST * uint128(newBaseCoords.length - numFalls)) +
      (PLAYER_FALL_ENERGY_COST * numFalls);
    uint128 currentEnergy = Energy._getEnergy(playerEntityId);
    transferEnergyToPool(playerEntityId, playerCoord, energyCost > currentEnergy ? currentEnergy : energyCost);
    // TODO: drop inventory items

    return gravityAppliesForMove;
  }

  function movePlayerWithGravity(
    EntityId playerEntityId,
    VoxelCoord memory playerCoord,
    VoxelCoord[] memory newCoords
  ) public {
    bool gravityAppliesForMove = movePlayer(playerEntityId, playerCoord, newCoords);
    if (gravityAppliesForMove) {
      runGravity(playerEntityId, newCoords[newCoords.length - 1]);
    }

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 2, playerCoord.z);
    EntityId aboveEntityId = aboveCoord.getPlayer();
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (aboveEntityId.exists()) {
      runGravity(aboveEntityId, aboveCoord);
    }
  }

  function _gravityApplies(VoxelCoord memory playerCoord) internal view returns (bool) {
    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    // We don't want players to fall off the edge of the world
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    ObjectType belowObjectType = belowCoord.getObjectType();
    // Players can swim in water so we don't want to apply gravity to them
    if (belowObjectType == WaterObjectID || !ObjectTypeMetadata._getCanPassThrough(belowObjectType)) {
      return false;
    }
    if (belowCoord.getPlayer().exists()) {
      return false;
    }

    return true;
  }

  function runGravity(EntityId playerEntityId, VoxelCoord memory playerCoord) public {
    if (!_gravityApplies(playerCoord)) {
      return;
    }

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    movePlayerWithGravity(playerEntityId, playerCoord, newCoords);
  }
}
