// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";

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

function transferEnergyFromPlayerToPool(
  EntityId playerEntityId,
  VoxelCoord memory playerCoord,
  EnergyData memory playerEnergyData,
  uint128 numToTransfer
) {
  playerEntityId.decreaseEnergy(playerEnergyData, numToTransfer);
  addEnergyToLocalPool(playerCoord, numToTransfer);
}

function addEnergyToLocalPool(VoxelCoord memory coord, uint128 numToAdd) {
  VoxelCoord memory shardCoord = coord.toLocalEnergyPoolShardCoord();
  LocalEnergyPool._set(shardCoord.x, 0, shardCoord.z, LocalEnergyPool._get(shardCoord.x, 0, shardCoord.z) + numToAdd);
}
