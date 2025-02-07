// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

function updateMachineEnergyLevel(bytes32 entityId) returns (EnergyData memory) {
  EnergyData memory energyData = Energy._get(entityId);

  if (energyData.energy > 0) {
    // TODO: check if its a machine

    // Calculate how much time has passed since last update
    uint256 timeSinceLastUpdate = block.timestamp - energyData.lastUpdatedTime;
    if (timeSinceLastUpdate == 0) {
      return energyData;
    }

    uint256 newEnergy = energyData.energy > timeSinceLastUpdate ? energyData.energy - timeSinceLastUpdate : 0;
    energyData.energy = newEnergy;
    energyData.lastUpdatedTime = block.timestamp;
    Energy._set(entityId, energyData);
  }

  return energyData;
}
