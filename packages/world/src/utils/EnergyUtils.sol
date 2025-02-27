// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";

import { VoxelCoord } from "../VoxelCoord.sol";
import { EntityId } from "../EntityId.sol";
import { MASS_TO_ENERGY_MULTIPLIER } from "../Constants.sol";
import { PLAYER_ENERGY_DRAIN_RATE, PLAYER_ENERGY_DRAIN_INTERVAL, MIN_PLAYER_ENERGY_THRESHOLD_TO_DRAIN } from "../Constants.sol";
import { MACHINE_ENERGY_DRAIN_RATE, MACHINE_ENERGY_DRAIN_INTERVAL, MIN_MACHINE_ENERGY_THRESHOLD_TO_DRAIN } from "../Constants.sol";

function massToEnergy(uint128 mass) pure returns (uint128) {
  return uint128(mass * MASS_TO_ENERGY_MULTIPLIER);
}

function energyToMass(uint128 energy) pure returns (uint128) {
  return uint128(energy / MASS_TO_ENERGY_MULTIPLIER);
}

function getLatestEnergyData(
  EntityId entityId,
  uint128 drainEnergyThreshold,
  uint128 drainInterval
) view returns (EnergyData memory) {
  EnergyData memory energyData = Energy._get(entityId);

  if (energyData.energy > drainEnergyThreshold) {
    // Calculate how much time has passed since last update
    uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
    if (timeSinceLastUpdate < drainInterval) {
      return energyData;
    }
    uint128 energyDrained = (timeSinceLastUpdate * energyData.drainRate) / drainInterval;
    uint128 newEnergy = energyData.energy > energyDrained ? energyData.energy - energyDrained : 0;

    // TODO: should we do this for both machines and players?
    // Update accumulated depleted time
    if (newEnergy == 0) {
      if (energyData.energy > 0) {
        // Entity just ran out of energy in this update
        // Calculate when it ran out by determining how much time it took to drain the energy
        uint128 timeToDeplete = (energyData.energy * drainInterval) / energyData.drainRate;
        // Add the remaining time after depletion to the accumulated depleted time
        energyData.accDepletedTime += (timeSinceLastUpdate - timeToDeplete);
      } else {
        // Entity was already out of energy, add the entire time since last update
        energyData.accDepletedTime += timeSinceLastUpdate;
      }
    }

    energyData.energy = newEnergy;
    energyData.lastUpdatedTime = uint128(block.timestamp);
  }

  return energyData;
}

function getPlayerEnergyLevel(EntityId entityId) view returns (EnergyData memory) {
  return getLatestEnergyData(entityId, MIN_PLAYER_ENERGY_THRESHOLD_TO_DRAIN, PLAYER_ENERGY_DRAIN_INTERVAL);
}

function updatePlayerEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  EnergyData memory energyData = getPlayerEnergyLevel(entityId);
  Energy._set(entityId, energyData);
  return energyData;
}

function getMachineEnergyLevel(EntityId entityId) view returns (EnergyData memory) {
  return getLatestEnergyData(entityId, MIN_MACHINE_ENERGY_THRESHOLD_TO_DRAIN, MACHINE_ENERGY_DRAIN_INTERVAL);
}

function updateMachineEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  EnergyData memory energyData = getMachineEnergyLevel(entityId);
  Energy._set(entityId, energyData);
  return energyData;
}

function transferEnergyFromPlayerToPool(
  EntityId playerEntityId,
  VoxelCoord memory playerCoord,
  EnergyData memory playerEnergyData,
  uint128 numToTransfer
) {
  playerEntityId.decreaseEnergy(playerEnergyData, numToTransfer);
  playerCoord.addEnergyToLocalPool(numToTransfer);
}

function updateSleepingPlayerEnergy(
  EntityId playerEntityId,
  EntityId bedEntityId,
  EnergyData memory machineData
) returns (EnergyData memory) {
  uint128 timeWithoutEnergy = machineData.accDepletedTime - BedPlayer._getLastAccDepletedTime(bedEntityId);
  EnergyData memory energyData = Energy._get(playerEntityId);
  if (timeWithoutEnergy > 0) {
    uint128 totalEnergyDepleted = timeWithoutEnergy * PLAYER_ENERGY_DRAIN_RATE;
    // No need to call updatePlayerEnergyLevel as drain rate is 0 if sleeping
    EnergyData memory currentEnergyData = Energy._get(playerEntityId);
    energyData.energy = totalEnergyDepleted < currentEnergyData.energy
      ? currentEnergyData.energy - totalEnergyDepleted
      : 0;
  }

  // Set last updated so next time updatePlayerEnergyLevel is called it will drain from here
  energyData.lastUpdatedTime = uint128(block.timestamp);

  Energy._set(playerEntityId, energyData);
  BedPlayer._setLastAccDepletedTime(bedEntityId, machineData.accDepletedTime);

  return energyData;
}
