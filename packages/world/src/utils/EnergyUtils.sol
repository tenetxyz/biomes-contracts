// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { Position, PositionData } from "../codegen/tables/Position.sol";

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";
import { EntityId } from "../EntityId.sol";
import { MASS_TO_ENERGY_MULTIPLIER } from "../Constants.sol";
import { PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";

using VoxelCoordLib for PositionData;

function massToEnergy(uint128 mass) pure returns (uint128) {
  return uint128(mass * MASS_TO_ENERGY_MULTIPLIER);
}

function energyToMass(uint128 energy) pure returns (uint128) {
  return uint128(energy / MASS_TO_ENERGY_MULTIPLIER);
}

function getLatestEnergyData(EntityId entityId) view returns (EnergyData memory, uint128) {
  EnergyData memory energyData = Energy._get(entityId);
  uint128 energyDrained = 0;

  if (energyData.energy > 0) {
    // Calculate how much time has passed since last update
    uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
    if (timeSinceLastUpdate == 0) {
      return (energyData, energyDrained);
    }
    energyDrained = timeSinceLastUpdate * energyData.drainRate;
    energyDrained = energyDrained > energyData.energy ? energyData.energy : energyDrained;
    uint128 newEnergy = energyData.energy > energyDrained ? energyData.energy - energyDrained : 0;

    // TODO: should we do this for both machines and players?
    // Update accumulated depleted time
    if (newEnergy == 0) {
      if (energyData.energy > 0) {
        // Entity just ran out of energy in this update
        // Calculate when it ran out by determining how much time it took to drain the energy
        uint128 timeToDeplete = energyData.energy / energyData.drainRate;
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

  return (energyData, energyDrained);
}

function updatePlayerEnergyLevel(EntityId entityId) returns (EnergyData memory, uint128) {
  (EnergyData memory energyData, uint128 energyDrained) = getLatestEnergyData(entityId);
  Energy._set(entityId, energyData);
  return (energyData, energyDrained);
}

function updateMachineEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  (EnergyData memory energyData, uint128 energyDrained) = getLatestEnergyData(entityId);
  if (energyDrained > 0) {
    VoxelCoord memory machineCoord = Position._get(entityId).toVoxelCoord();
    machineCoord.addEnergyToLocalPool(energyDrained);
  }
  Energy._set(entityId, energyData);
  return energyData;
}

function transferEnergyToPool(EntityId from, VoxelCoord memory poolCoord, uint128 amount) {
  uint128 current = Energy._getEnergy(from);
  require(current >= amount, "Not enough energy");
  from.setEnergy(current - amount);
  poolCoord.addEnergyToLocalPool(amount);
}

function updateSleepingPlayerEnergy(
  EntityId playerEntityId,
  EntityId bedEntityId,
  EnergyData memory machineData,
  VoxelCoord memory bedCoord
) returns (EnergyData memory) {
  uint128 timeWithoutEnergy = machineData.accDepletedTime - BedPlayer._getLastAccDepletedTime(bedEntityId);
  EnergyData memory playerEnergyData = Energy._get(playerEntityId);
  if (timeWithoutEnergy > 0) {
    uint128 totalEnergyDepleted = timeWithoutEnergy * PLAYER_ENERGY_DRAIN_RATE;
    // No need to call updatePlayerEnergyLevel as drain rate is 0 if sleeping
    uint128 transferredToPool = playerEnergyData.energy > totalEnergyDepleted
      ? totalEnergyDepleted
      : playerEnergyData.energy;
    // transferEnergyToPool(playerEntityId, bedCoord, transferredToPool);
    playerEnergyData.energy -= transferredToPool;

    bedCoord.addEnergyToLocalPool(transferredToPool);
    // TODO: transfer the rest of the energy from forcefield to the pool
  }
  // Set last updated so next time updatePlayerEnergyLevel is called it will drain from here
  playerEnergyData.lastUpdatedTime = uint128(block.timestamp);
  Energy._set(playerEntityId, playerEnergyData);
  BedPlayer._setLastAccDepletedTime(bedEntityId, machineData.accDepletedTime);
  return playerEnergyData;
}
