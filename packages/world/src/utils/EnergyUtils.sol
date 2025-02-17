// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { EntityId } from "../EntityId.sol";
import { MIN_PLAYER_ENERGY } from "../Constants.sol";

function massToEnergy(uint32 mass) pure returns (uint128) {
  return uint128(mass * 50);
}

function getLatestEnergyData(EntityId entityId, uint128 minEnergy) view returns (EnergyData memory) {
  EnergyData memory energyData = Energy._get(entityId);

  if (energyData.energy > minEnergy) {
    // Calculate how much time has passed since last update
    uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
    if (timeSinceLastUpdate == 0) {
      return energyData;
    }

    uint128 newEnergy = energyData.energy > timeSinceLastUpdate ? energyData.energy - timeSinceLastUpdate : 0;
    energyData.energy = newEnergy;
    energyData.lastUpdatedTime = uint128(block.timestamp);
  }

  return energyData;
}

function updateEnergyLevel(EntityId entityId, uint128 minEnergy) returns (EnergyData memory) {
  EnergyData memory energyData = getLatestEnergyData(entityId, minEnergy);
  Energy._set(entityId, energyData);
  return energyData;
}

function getPlayerEnergyLevel(EntityId entityId) view returns (EnergyData memory) {
  return getLatestEnergyData(entityId, MIN_PLAYER_ENERGY);
}

function updatePlayerEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  return updateEnergyLevel(entityId, MIN_PLAYER_ENERGY);
}

function getMachineEnergyLevel(EntityId entityId) view returns (EnergyData memory) {
  return getLatestEnergyData(entityId, 0);
}

function updateMachineEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  return updateEnergyLevel(entityId, 0);
}
