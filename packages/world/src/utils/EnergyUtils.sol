// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { Machine } from "../codegen/tables/Machine.sol";

import { LocalEnergyPool, Position, PlayerPosition } from "../utils/Vec3Storage.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { getEntityAt } from "../utils/EntityUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { MASS_TO_ENERGY_MULTIPLIER, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";

function massToEnergy(uint128 mass) pure returns (uint128) {
  return uint128(mass * MASS_TO_ENERGY_MULTIPLIER);
}

function energyToMass(uint128 energy) pure returns (uint128) {
  return uint128(energy / MASS_TO_ENERGY_MULTIPLIER);
}

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

  uint128 accDepletedTime = Machine._getAccDepletedTime(entityId);
  if (depletedTime > 0) {
    accDepletedTime += depletedTime;
    Machine._setAccDepletedTime(entityId, accDepletedTime);
  }

  Energy._set(entityId, energyData);
  return (energyData, accDepletedTime);
}

function updatePlayerEnergy(EntityId entityId) returns (EnergyData memory) {
  (EnergyData memory energyData, uint128 energyDrained, ) = getLatestEnergyData(entityId);
  if (energyDrained > 0) {
    Vec3 coord = PlayerPosition._get(entityId);
    addEnergyToLocalPool(coord, energyDrained);

    // Player died
    if (energyData.energy == 0) {
      (EntityId toEntityId, ObjectTypeId objectTypeId) = getEntityAt(coord);
      transferAllInventoryEntities(entityId, toEntityId, objectTypeId);
      PlayerUtils.removePlayerFromGrid(entityId, coord);
    }
  }

  Energy._set(entityId, energyData);
  return energyData;
}

function addEnergyToLocalPool(Vec3 coord, uint128 numToAdd) returns (uint128) {
  Vec3 shardCoord = coord.toLocalEnergyPoolShardCoord();
  uint128 newLocalEnergy = LocalEnergyPool._get(shardCoord) + numToAdd;
  LocalEnergyPool._set(shardCoord, newLocalEnergy);
  return newLocalEnergy;
}

function removeEnergyFromLocalPool(Vec3 coord, uint128 numToRemove) returns (uint128) {
  Vec3 shardCoord = coord.toLocalEnergyPoolShardCoord();
  uint128 localEnergy = LocalEnergyPool._get(shardCoord);
  require(localEnergy >= numToRemove, "Not enough energy in local pool");
  uint128 newLocalEnergy = localEnergy - numToRemove;
  LocalEnergyPool._set(shardCoord, newLocalEnergy);
  return newLocalEnergy;
}

function transferEnergyToPool(EntityId from, Vec3 poolCoord, uint128 amount) {
  uint128 current = Energy._getEnergy(from);
  require(current >= amount, "Not enough energy");
  Energy._setEnergy(from, current - amount);
  addEnergyToLocalPool(poolCoord, amount);
}

function updateSleepingPlayerEnergy(
  EntityId playerEntityId,
  EntityId bedEntityId,
  uint128 accDepletedTime,
  Vec3 bedCoord
) returns (EnergyData memory) {
  uint128 timeWithoutEnergy = accDepletedTime - BedPlayer._getLastAccDepletedTime(bedEntityId);
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
  BedPlayer._setLastAccDepletedTime(bedEntityId, accDepletedTime);
  return playerEnergyData;
}
