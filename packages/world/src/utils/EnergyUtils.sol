// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { Position, PositionData } from "../codegen/tables/Position.sol";

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";
import { EntityId } from "../EntityId.sol";
import { MASS_TO_ENERGY_MULTIPLIER } from "../Constants.sol";
import { PLAYER_ENERGY_DRAIN_RATE, PLAYER_ENERGY_DRAIN_INTERVAL } from "../Constants.sol";
import { MACHINE_ENERGY_DRAIN_RATE, MACHINE_ENERGY_DRAIN_INTERVAL } from "../Constants.sol";

using VoxelCoordLib for PositionData;

function massToEnergy(uint128 mass) pure returns (uint128) {
  return uint128(mass * MASS_TO_ENERGY_MULTIPLIER);
}

function energyToMass(uint128 energy) pure returns (uint128) {
  return uint128(energy / MASS_TO_ENERGY_MULTIPLIER);
}

function getLatestEnergyData(
  EntityId entityId,
  uint128 drainInterval,
  uint128 drainRate
) view returns (EnergyData memory, uint128) {
  EnergyData memory energyData = Energy._get(entityId);
  uint128 energyDrained = 0;

  if (energyData.energy > 0) {
    // Calculate how much time has passed since last update
    uint128 timeSinceLastUpdate = uint128(block.timestamp) - energyData.lastUpdatedTime;
    if (timeSinceLastUpdate == 0) {
      return (energyData, energyDrained);
    }
    if (timeSinceLastUpdate < drainInterval) {
      return (energyData, energyDrained);
    }
    energyDrained = (timeSinceLastUpdate * drainRate) / drainInterval;
    energyDrained = energyDrained > energyData.energy ? energyData.energy : energyDrained;
    energyData.energy = energyData.energy - energyDrained;
    energyData.lastUpdatedTime = uint128(block.timestamp);
  }

  return (energyData, energyDrained);
}

function getPlayerEnergyLevel(EntityId entityId) view returns (EnergyData memory, uint128) {
  return getLatestEnergyData(entityId, PLAYER_ENERGY_DRAIN_INTERVAL, PLAYER_ENERGY_DRAIN_RATE);
}

function updatePlayerEnergyLevel(EntityId entityId) returns (EnergyData memory, uint128) {
  (EnergyData memory energyData, uint128 energyDrained) = getPlayerEnergyLevel(entityId);
  Energy._set(entityId, energyData);
  return (energyData, energyDrained);
}

function getMachineEnergyLevel(EntityId entityId) view returns (EnergyData memory, uint128) {
  return getLatestEnergyData(entityId, MACHINE_ENERGY_DRAIN_INTERVAL, MACHINE_ENERGY_DRAIN_RATE);
}

function updateMachineEnergyLevel(EntityId entityId) returns (EnergyData memory) {
  (EnergyData memory energyData, uint128 energyDrained) = getMachineEnergyLevel(entityId);
  if (energyDrained > 0) {
    VoxelCoord memory machineCoord = Position._get(entityId).toVoxelCoord();
    machineCoord.addEnergyToLocalPool(energyDrained);
  }
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
