// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { EntityId } from "../EntityId.sol";
import { PLAYER_ENERGY_DRAIN_RATE, PLAYER_ENERGY_DRAIN_INTERVAL, MIN_PLAYER_ENERGY_THRESHOLD_TO_DRAIN } from "../Constants.sol";
import { MACHINE_ENERGY_DRAIN_RATE, MACHINE_ENERGY_DRAIN_INTERVAL, MIN_MACHINE_ENERGY_THRESHOLD_TO_DRAIN } from "../Constants.sol";

function massToEnergy(uint128 mass) pure returns (uint128) {
  return uint128(mass * 50);
}

function energyToMass(uint128 energy) pure returns (uint128) {
  return uint128(energy / 50);
}

function getLatestEnergyData(
  EntityId entityId,
  uint128 drainEnergyThreshold,
  uint128 drainInterval,
  uint128 drainRate
) view returns (EnergyData memory) {
  EnergyData memory energyData = Energy._get(entityId);

  if (energyData.energy > drainEnergyThreshold) {
    // Calculate how much time has passed since last update
    uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
    if (timeSinceLastUpdate == 0) {
      return energyData;
    }
    if (timeSinceLastUpdate < drainInterval) {
      return energyData;
    }
    uint128 energyDrained = (timeSinceLastUpdate * drainRate) / drainInterval;
    uint128 newEnergy = energyData.energy > energyDrained ? energyData.energy - energyDrained : 0;
    energyData.energy = newEnergy;
    energyData.lastUpdatedTime = uint128(block.timestamp);
  }

  return energyData;
}

function getPlayerEnergyLevel(EntityId entityId) view returns (EnergyData memory) {
  return
    getLatestEnergyData(
      entityId,
      MIN_PLAYER_ENERGY_THRESHOLD_TO_DRAIN,
      PLAYER_ENERGY_DRAIN_INTERVAL,
      PLAYER_ENERGY_DRAIN_RATE
    );
}

function updatePlayerEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  EnergyData memory energyData = getPlayerEnergyLevel(entityId);
  Energy._set(entityId, energyData);
  return energyData;
}

function getMachineEnergyLevel(EntityId entityId) view returns (EnergyData memory) {
  return
    getLatestEnergyData(
      entityId,
      MIN_MACHINE_ENERGY_THRESHOLD_TO_DRAIN,
      MACHINE_ENERGY_DRAIN_INTERVAL,
      MACHINE_ENERGY_DRAIN_RATE
    );
}

function updateMachineEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  EnergyData memory energyData = getMachineEnergyLevel(entityId);
  Energy._set(entityId, energyData);
  return energyData;
}
