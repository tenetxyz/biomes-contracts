// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy } from "../../codegen/tables/Energy.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { ReverseMovablePosition } from "../../utils/Vec3Storage.sol";

import {
  MAX_PLAYER_GLIDES,
  MAX_PLAYER_JUMPS,
  MOVE_ENERGY_COST,
  PLAYER_FALL_DAMAGE_THRESHOLD,
  PLAYER_FALL_ENERGY_COST
} from "../../Constants.sol";
import { EntityId } from "../../EntityId.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypeLib } from "../../ObjectTypeLib.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";

import { Vec3, vec3 } from "../../Vec3.sol";
import { addEnergyToLocalPool, decreasePlayerEnergy, updatePlayerEnergy } from "../../utils/EnergyUtils.sol";
import { getMovableEntityAt, safeGetObjectTypeIdAt, setMovableEntityAt } from "../../utils/EntityUtils.sol";

library MoveLib {
  using ObjectTypeLib for ObjectTypeId;

  function _requireValidMove(Vec3 baseOldCoord, Vec3 baseNewCoord) internal view {
    require(baseOldCoord.inSurroundingCube(baseNewCoord, 1), "New coord is too far from old coord");

    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(baseNewCoord);

    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      Vec3 newCoord = newPlayerCoords[i];

      ObjectTypeId newObjectTypeId = safeGetObjectTypeIdAt(newCoord);
      require(ObjectTypeMetadata._getCanPassThrough(newObjectTypeId), "Cannot move through a non-passable block");

      require(!getMovableEntityAt(newCoord).exists(), "Cannot move through a player");
    }
  }

  function _getPlayers(EntityId basePlayer, Vec3[] memory playerCoords) internal view returns (EntityId[] memory) {
    EntityId[] memory players = new EntityId[](playerCoords.length);
    players[0] = basePlayer;
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < playerCoords.length; i++) {
      players[i] = getMovableEntityAt(playerCoords[i]);
    }
    return players;
  }

  function _gravityApplies(Vec3 playerCoord) internal view returns (bool) {
    Vec3 belowCoord = playerCoord - vec3(0, 1, 0);

    ObjectTypeId belowObjectTypeId = safeGetObjectTypeIdAt(belowCoord);
    // Players can swim in water so we don't want to apply gravity to them
    if (belowObjectTypeId == ObjectTypes.Water || !ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId)) {
      return false;
    }

    return !getMovableEntityAt(belowCoord).exists();
  }

  function _computeGravityResult(Vec3 coord, uint16 initialFallHeight) private view returns (Vec3, uint128) {
    uint16 currentFallHeight = 0;
    Vec3 current = coord;
    while (_gravityApplies(current)) {
      current = current - vec3(0, 1, 0);
      currentFallHeight++;
    }

    uint16 totalFallHeight = initialFallHeight + currentFallHeight;

    uint128 cost = 0;
    if (totalFallHeight >= PLAYER_FALL_DAMAGE_THRESHOLD) {
      // If the player was already over the threshold, apply cost for each new fall
      if (initialFallHeight >= PLAYER_FALL_DAMAGE_THRESHOLD) {
        cost = PLAYER_FALL_ENERGY_COST * currentFallHeight;
      } else {
        cost = PLAYER_FALL_ENERGY_COST * (totalFallHeight - PLAYER_FALL_DAMAGE_THRESHOLD + 1);
      }
    }

    return (current, cost);
  }

  /**
   * Calculate total energy cost and final path coordinate
   */
  function _computePathResult(Vec3 currentBaseCoord, Vec3[] memory newBaseCoords, uint128 currentEnergy)
    internal
    view
    returns (Vec3, uint128, uint16, bool)
  {
    uint128 totalCost = 0;
    uint16 numJumps = 0;
    uint16 numGlides = 0;
    uint16 currentFallHeight = 0;
    bool gravityApplies = false;

    Vec3 oldBaseCoord = currentBaseCoord;
    for (uint256 i = 0; i < newBaseCoords.length; i++) {
      Vec3 nextBaseCoord = newBaseCoords[i];
      _requireValidMove(oldBaseCoord, nextBaseCoord);

      uint128 stepCost = MOVE_ENERGY_COST;

      gravityApplies = _gravityApplies(nextBaseCoord);
      if (gravityApplies) {
        if (nextBaseCoord.y() > oldBaseCoord.y()) {
          numJumps++;
          require(numJumps <= MAX_PLAYER_JUMPS, "Cannot jump more than 3 blocks");
        } else if (nextBaseCoord.y() < oldBaseCoord.y()) {
          currentFallHeight++;
          if (currentFallHeight >= PLAYER_FALL_DAMAGE_THRESHOLD) {
            stepCost = PLAYER_FALL_ENERGY_COST;
          }
          numGlides = 0;
        } else {
          numGlides++;
          require(numGlides <= MAX_PLAYER_GLIDES, "Cannot glide more than 10 blocks");
        }
      } else {
        numJumps = 0;
        numGlides = 0;
        currentFallHeight = 0;
      }

      totalCost += stepCost;

      oldBaseCoord = nextBaseCoord;

      if (totalCost >= currentEnergy) {
        break;
      }
    }

    return (oldBaseCoord, totalCost, currentFallHeight, gravityApplies);
  }

  function moveWithoutGravity(EntityId player, Vec3 playerCoord, Vec3[] memory newBaseCoords) public {
    Vec3[] memory playerCoords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    EntityId[] memory players = _getPlayers(player, playerCoords);

    // Remove the current player from the grid
    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReverseMovablePosition._deleteRecord(playerCoords[i]);
    }

    uint128 currentEnergy = Energy._getEnergy(player);

    (Vec3 finalCoord, uint128 totalCost,,) = _computePathResult(playerCoord, newBaseCoords, currentEnergy);

    if (totalCost > currentEnergy) {
      totalCost = currentEnergy;
    }

    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(finalCoord);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      setMovableEntityAt(newPlayerCoords[i], players[i]);
    }

    if (totalCost > 0) {
      decreasePlayerEnergy(player, finalCoord, totalCost);
      addEnergyToLocalPool(finalCoord, totalCost);
    }
  }

  function move(EntityId player, Vec3 playerCoord, Vec3[] memory newBaseCoords) public {
    Vec3[] memory playerCoords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    EntityId[] memory players = _getPlayers(player, playerCoords);

    // Remove the current player from the grid
    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReverseMovablePosition._deleteRecord(playerCoords[i]);
    }

    uint128 currentEnergy = Energy._getEnergy(player);

    (Vec3 finalCoord, uint128 cost, uint16 currentFallHeight, bool gravityApplies) =
      _computePathResult(playerCoord, newBaseCoords, currentEnergy);

    uint128 totalCost = cost;
    if (gravityApplies) {
      (finalCoord, cost) = _computeGravityResult(finalCoord, currentFallHeight);
      totalCost += cost;
    }

    if (totalCost > currentEnergy) {
      totalCost = currentEnergy;
    }

    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(finalCoord);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      setMovableEntityAt(newPlayerCoords[i], players[i]);
    }

    if (totalCost > 0) {
      decreasePlayerEnergy(player, finalCoord, totalCost);
      addEnergyToLocalPool(finalCoord, totalCost);
    }

    Vec3 aboveCoord = playerCoord + vec3(0, 2, 0);
    EntityId above = getMovableEntityAt(aboveCoord);
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (above.exists()) {
      runGravity(above, aboveCoord);
    }
  }

  function runGravity(EntityId player, Vec3 playerCoord) public {
    if (!_gravityApplies(playerCoord)) {
      return;
    }

    Vec3[] memory playerCoords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    EntityId[] memory players = _getPlayers(player, playerCoords);

    // Remove the current player from the grid
    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReverseMovablePosition._deleteRecord(playerCoords[i]);
    }

    (Vec3 finalCoord, uint128 totalCost) = _computeGravityResult(playerCoord, 0);

    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(finalCoord);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      setMovableEntityAt(newPlayerCoords[i], players[i]);
    }

    uint128 currentEnergy = updatePlayerEnergy(player).energy;

    if (totalCost > currentEnergy) {
      totalCost = currentEnergy;
    }

    if (totalCost > 0) {
      decreasePlayerEnergy(player, finalCoord, totalCost);
      addEnergyToLocalPool(finalCoord, totalCost);
    }

    Vec3 aboveCoord = playerCoord + vec3(0, 2, 0);
    EntityId above = getMovableEntityAt(aboveCoord);
    // Note: currently it is not possible for the above player to not be the base entity,
    // but if we add other types of movable entities we should check that it is a base entity
    if (above.exists()) {
      runGravity(above, aboveCoord);
    }
  }
}
