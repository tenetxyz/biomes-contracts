// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { Position } from "../codegen/tables/Position.sol";

import { EntityId } from "../EntityId.sol";
import { MASS_TO_ENERGY_MULTIPLIER } from "../Constants.sol";
import { PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";

import { Vec3 } from "../Vec3.sol";

function massToEnergy(uint128 mass) pure returns (uint128) {
  return uint128(mass * MASS_TO_ENERGY_MULTIPLIER);
}

function energyToMass(uint128 energy) pure returns (uint128) {
  return uint128(energy / MASS_TO_ENERGY_MULTIPLIER);
}

function getLatestEnergyData(EntityId entityId) view returns (EnergyData memory, uint128) {
  EnergyData memory energyData = Energy._get(entityId);

  // Calculate how much time has passed since last update
  uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
  if (timeSinceLastUpdate == 0) {
    return (energyData, 0);
  }

  // Update timestamp for all cases
  energyData.lastUpdatedTime = uint128(block.timestamp);

  if (energyData.energy == 0) {
    energyData.accDepletedTime += timeSinceLastUpdate;
    return (energyData, 0);
  }

  // Calculate energy drain
  uint128 energyDrained = timeSinceLastUpdate * energyData.drainRate;

  // Update accumulated depleted time if it ran out of energy on this update
  if (energyDrained >= energyData.energy) {
    // Calculate when it ran out by determining how much time it took to drain the energy
    uint128 timeToDeplete = energyData.energy / energyData.drainRate;
    // Add the remaining time after depletion to the accumulated depleted time
    energyData.accDepletedTime += (timeSinceLastUpdate - timeToDeplete);
    energyDrained = energyData.energy;
    energyData.energy = 0;
  } else {
    energyData.energy -= energyDrained;
  }

  return (energyData, energyDrained);
}

function updateEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  (EnergyData memory energyData, uint128 energyDrained) = getLatestEnergyData(entityId);
  if (energyDrained > 0) {
    Vec3 coord = Position._get(entityId);
    coord.addEnergyToLocalPool(energyDrained);
  }
  Energy._set(entityId, energyData);
  return energyData;
}

function transferEnergyToPool(EntityId from, Vec3 poolCoord, uint128 amount) {
  uint128 current = Energy._getEnergy(from);
  require(current >= amount, "Not enough energy");
  from.setEnergy(current - amount);
  poolCoord.addEnergyToLocalPool(amount);
}

function updateSleepingPlayerEnergy(
  EntityId playerEntityId,
  EntityId bedEntityId,
  EnergyData memory machineData,
  Vec3 bedCoord
) returns (EnergyData memory) {
  uint128 timeWithoutEnergy = machineData.accDepletedTime - BedPlayer._getLastAccDepletedTime(bedEntityId);
  EnergyData memory playerEnergyData = Energy._get(playerEntityId);

  if (timeWithoutEnergy > 0) {
    uint128 totalEnergyDepleted = timeWithoutEnergy * PLAYER_ENERGY_DRAIN_RATE;
    // No need to call updatePlayerEnergyLevel as drain rate is 0 if sleeping
    uint128 transferredToPool = playerEnergyData.energy > totalEnergyDepleted
      ? totalEnergyDepleted
      : playerEnergyData.energy;

    playerEnergyData.energy -= transferredToPool;
    bedCoord.addEnergyToLocalPool(transferredToPool);
  }

  // Set last updated so next time updatePlayerEnergyLevel is called it will drain from here
  playerEnergyData.lastUpdatedTime = uint128(block.timestamp);
  Energy._set(playerEntityId, playerEnergyData);
  BedPlayer._setLastAccDepletedTime(bedEntityId, machineData.accDepletedTime);
  return playerEnergyData;
}
