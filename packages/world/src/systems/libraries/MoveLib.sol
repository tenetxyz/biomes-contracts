// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { ActionType } from "../../codegen/common.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { Position, ReversePosition, PlayerPosition, ReversePlayerPosition } from "../../utils/Vec3Storage.sol";

import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { ObjectTypeLib } from "../../ObjectTypeLib.sol";
import { inWorldBorder } from "../../Utils.sol";
import { PLAYER_MOVE_ENERGY_COST, PLAYER_FALL_ENERGY_COST, MAX_PLAYER_JUMPS, MAX_PLAYER_GLIDES } from "../../Constants.sol";
import { notify, MoveNotifData } from "../../utils/NotifUtils.sol";
import { TerrainLib } from "./TerrainLib.sol";
import { EntityId } from "../../EntityId.sol";
import { Vec3, vec3 } from "../../Vec3.sol";
import { transferEnergyToPool } from "../../utils/EnergyUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";
import { safeGetObjectTypeIdAt, getPlayer, setPlayer } from "../../utils/EntityUtils.sol";

library MoveLib {
  using ObjectTypeLib for ObjectTypeId;

  function _requireValidMove(Vec3 baseOldCoord, Vec3 baseNewCoord) internal view {
    Vec3[] memory oldPlayerCoords = ObjectTypes.Player.getRelativeCoords(baseOldCoord);
    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(baseNewCoord);

    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      Vec3 oldCoord = oldPlayerCoords[i];
      Vec3 newCoord = newPlayerCoords[i];

      require(inWorldBorder(newCoord), "Cannot move outside the world border");
      require(oldCoord.inSurroundingCube(newCoord, 1), "New coord is too far from old coord");

      ObjectTypeId newObjectTypeId = safeGetObjectTypeIdAt(newCoord);
      require(ObjectTypeMetadata._getCanPassThrough(newObjectTypeId), "Cannot move through a non-passable block");

      EntityId playerEntityIdAtCoord = getPlayer(newCoord);
      require(!playerEntityIdAtCoord.exists(), "Cannot move through a player");
    }
  }

  function _requireValidPath(
    Vec3[] memory playerCoords,
    Vec3[] memory newBaseCoords
  ) internal view returns (bool, uint16) {
    bool gravityAppliesForMove = false;
    uint16 numJumps = 0;
    uint16 numFalls = 0;
    uint16 numGlides = 0;

    Vec3 oldBaseCoord = playerCoords[0];
    for (uint256 i = 0; i < newBaseCoords.length; i++) {
      Vec3 newBaseCoord = newBaseCoords[i];
      _requireValidMove(oldBaseCoord, newBaseCoord);

      gravityAppliesForMove = _gravityApplies(newBaseCoord);
      if (gravityAppliesForMove) {
        if (oldBaseCoord.y() < newBaseCoord.y()) {
          numJumps++;
          require(numJumps <= MAX_PLAYER_JUMPS, "Cannot jump more than 3 blocks");
        } else if (oldBaseCoord.y() > newBaseCoord.y()) {
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
    Vec3[] memory playerCoords
  ) internal view returns (EntityId[] memory) {
    EntityId[] memory playerEntityIds = new EntityId[](playerCoords.length);
    playerEntityIds[0] = basePlayerEntityId;
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < playerCoords.length; i++) {
      playerEntityIds[i] = getPlayer(playerCoords[i]);
    }
    return playerEntityIds;
  }

  function movePlayer(EntityId playerEntityId, Vec3 playerCoord, Vec3[] memory newBaseCoords) public returns (bool) {
    Vec3[] memory playerCoords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    EntityId[] memory playerEntityIds = _getPlayerEntityIds(playerEntityId, playerCoords);

    // Remove the current player from the grid
    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReversePlayerPosition._deleteRecord(playerCoords[i]);
    }

    (bool gravityAppliesForMove, uint16 numFalls) = _requireValidPath(playerCoords, newBaseCoords);

    Vec3 finalPlayerCoord = newBaseCoords[newBaseCoords.length - 1];
    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(finalPlayerCoord);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      setPlayer(newPlayerCoords[i], playerEntityIds[i]);
    }

    uint128 energyCost = (PLAYER_MOVE_ENERGY_COST * uint128(newBaseCoords.length - numFalls)) +
      (PLAYER_FALL_ENERGY_COST * numFalls);
    uint128 currentEnergy = Energy._getEnergy(playerEntityId);
    transferEnergyToPool(playerEntityId, playerCoord, energyCost > currentEnergy ? currentEnergy : energyCost);
    // TODO: drop inventory items

    return gravityAppliesForMove;
  }

  function movePlayerWithGravity(EntityId playerEntityId, Vec3 playerCoord, Vec3[] memory newCoords) public {
    bool gravityAppliesForMove = movePlayer(playerEntityId, playerCoord, newCoords);
    if (gravityAppliesForMove) {
      runGravity(playerEntityId, newCoords[newCoords.length - 1]);
    }

    Vec3 aboveCoord = playerCoord + vec3(0, 2, 0);
    EntityId aboveEntityId = getPlayer(aboveCoord);
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (aboveEntityId.exists()) {
      runGravity(aboveEntityId, aboveCoord);
    }
  }

  function _gravityApplies(Vec3 playerCoord) internal view returns (bool) {
    Vec3 belowCoord = playerCoord - vec3(0, 1, 0);
    // We don't want players to fall off the edge of the world
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    ObjectTypeId belowObjectTypeId = safeGetObjectTypeIdAt(belowCoord);
    // Players can swim in water so we don't want to apply gravity to them
    if (belowObjectTypeId == ObjectTypes.Water || !ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId)) {
      return false;
    }
    if (getPlayer(belowCoord).exists()) {
      return false;
    }

    return true;
  }

  function runGravity(EntityId playerEntityId, Vec3 playerCoord) public {
    if (!_gravityApplies(playerCoord)) {
      return;
    }

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord - vec3(0, 1, 0);
    movePlayerWithGravity(playerEntityId, playerCoord, newCoords);
  }
}
