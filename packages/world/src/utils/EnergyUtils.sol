// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Machine } from "../codegen/tables/Machine.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";

import { LocalEnergyPool, Position, MovablePosition } from "../utils/Vec3Storage.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { getEntityAt } from "../utils/EntityUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";

function getLatestEnergyData(EntityId entityId) view returns (EnergyData memory, uint128, uint128) {
  EnergyData memory energyData = Energy._get(entityId);

  // Calculate how much time has passed since last update
  uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
  if (timeSinceLastUpdate == 0) {
    return (energyData, 0, 0);
  }

  // Update timestamp for all cases
  energyData.lastUpdatedTime = uint128(block.timestamp);

  if (energyData.energy == 0) {
    return (energyData, 0, timeSinceLastUpdate);
  }

  // Calculate energy drain
  uint128 energyDrained = timeSinceLastUpdate * energyData.drainRate;

  uint128 depletedTime = 0;
  // Update accumulated depleted time if it ran out of energy on this update
  if (energyDrained >= energyData.energy) {
    // Calculate when it ran out by determining how much time it took to drain the energy
    uint128 timeToDeplete = energyData.energy / energyData.drainRate;
    // Add the remaining time after depletion to the accumulated depleted time
    depletedTime = timeSinceLastUpdate - timeToDeplete;
    energyDrained = energyData.energy;
    energyData.energy = 0;
  } else {
    energyData.energy -= energyDrained;
  }

  return (energyData, energyDrained, depletedTime);
}

function updateMachineEnergy(EntityId entityId) returns (EnergyData memory, uint128) {
  (EnergyData memory energyData, uint128 energyDrained, uint128 depletedTime) = getLatestEnergyData(entityId);
  if (energyDrained > 0) {
    Vec3 coord = Position._get(entityId);
    addEnergyToLocalPool(coord, energyDrained);
  }

  uint128 currentDepletedTime = Machine._getDepletedTime(entityId);
  if (depletedTime > 0) {
    currentDepletedTime += depletedTime;
    Machine._setDepletedTime(entityId, currentDepletedTime);
  }

  Energy._set(entityId, energyData);
  return (energyData, currentDepletedTime);
}

/// @dev Used within systems before performing an action
function updatePlayerEnergy(EntityId playerEntityId) returns (EnergyData memory) {
  (EnergyData memory energyData, uint128 energyDrained, ) = getLatestEnergyData(playerEntityId);

  Vec3 coord = MovablePosition._get(playerEntityId);

  if (energyDrained > 0) {
    addEnergyToLocalPool(coord, energyDrained);
  }

  if (energyData.energy == 0) {
    PlayerUtils.killPlayer(playerEntityId, coord);
  }

  Energy._set(playerEntityId, energyData);

  return energyData;
}

function decreaseMachineEnergy(EntityId machineEntityId, uint128 amount) {
  require(amount > 0, "Cannot decrease 0 energy");
  uint128 current = Energy._getEnergy(machineEntityId);
  require(current >= amount, "Not enough energy");

  // Set the energy data
  Energy._setEnergy(machineEntityId, current - amount);
}

function decreasePlayerEnergy(EntityId playerEntityId, Vec3 playerCoord, uint128 amount) {
  require(amount > 0, "Cannot decrease 0 energy");
  uint128 current = Energy._getEnergy(playerEntityId);
  require(current >= amount, "Not enough energy");

  uint128 newEnergy = current - amount;

  // Set the energy data
  Energy._setEnergy(playerEntityId, newEnergy);

  // Check if player is dead (zero energy)
  if (newEnergy == 0) {
    PlayerUtils.killPlayer(playerEntityId, playerCoord);
  }
}

function decreaseEnergy(EntityId entityId, uint128 amount) {
  if (ObjectType._get(entityId) == ObjectTypes.Player) {
    decreasePlayerEnergy(entityId, MovablePosition._get(entityId), amount);
  } else {
    decreaseMachineEnergy(entityId, amount);
  }
}

function addEnergyToLocalPool(Vec3 coord, uint128 numToAdd) returns (uint128) {
  Vec3 shardCoord = coord.toLocalEnergyPoolShardCoord();
  uint128 newLocalEnergy = LocalEnergyPool._get(shardCoord) + numToAdd;
  LocalEnergyPool._set(shardCoord, newLocalEnergy);
  return newLocalEnergy;
}

function transferEnergyToPool(EntityId entityId, uint128 amount) {
  Vec3 coord = entityId.getPosition();
  if (ObjectType._get(entityId) == ObjectTypes.Player) {
    decreasePlayerEnergy(entityId, coord, amount);
  } else {
    decreaseMachineEnergy(entityId, amount);
  }

  addEnergyToLocalPool(coord, amount);
}

function removeEnergyFromLocalPool(Vec3 coord, uint128 numToRemove) returns (uint128) {
  Vec3 shardCoord = coord.toLocalEnergyPoolShardCoord();
  uint128 localEnergy = LocalEnergyPool._get(shardCoord);
  require(localEnergy >= numToRemove, "Not enough energy in local pool");
  uint128 newLocalEnergy = localEnergy - numToRemove;
  LocalEnergyPool._set(shardCoord, newLocalEnergy);
  return newLocalEnergy;
}

function updateSleepingPlayerEnergy(
  EntityId playerEntityId,
  EntityId bedEntityId,
  uint128 depletedTime,
  Vec3 bedCoord
) returns (EnergyData memory) {
  uint128 timeWithoutEnergy = depletedTime - BedPlayer._getLastDepletedTime(bedEntityId);
  EnergyData memory playerEnergyData = Energy._get(playerEntityId);

  if (timeWithoutEnergy > 0) {
    uint128 totalEnergyDepleted = timeWithoutEnergy * PLAYER_ENERGY_DRAIN_RATE;
    // No need to call updatePlayerEnergyLevel as drain rate is 0 if sleeping
    uint128 transferredToPool = playerEnergyData.energy > totalEnergyDepleted
      ? totalEnergyDepleted
      : playerEnergyData.energy;

    playerEnergyData.energy -= transferredToPool;
    addEnergyToLocalPool(bedCoord, transferredToPool);
  }

  // Set last updated so next time updatePlayerEnergyLevel is called it will drain from here
  playerEnergyData.lastUpdatedTime = uint128(block.timestamp);
  Energy._set(playerEntityId, playerEnergyData);
  BedPlayer._setLastDepletedTime(bedEntityId, depletedTime);

  return playerEnergyData;
}
