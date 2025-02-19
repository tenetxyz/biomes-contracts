// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Chip } from "./codegen/tables/Chip.sol";
import { BaseEntity } from "./codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "./codegen/tables/Energy.sol";
type EntityId is bytes32;

function baseEntityId(EntityId self) view returns (EntityId) {
  EntityId base = BaseEntity._get(self);
  return EntityId.unwrap(base) == bytes32(0) ? self : base;
}

// TODO: Not sure if it should be included here or if it should be a standalone util
function getChipAddress(EntityId entityId) view returns (address) {
  ResourceId chipSystemId = Chip._getChipSystemId(entityId);
  (address chipAddress, ) = Systems._get(chipSystemId);
  return chipAddress;
}

function exists(EntityId self) pure returns (bool) {
  return EntityId.unwrap(self) != bytes32(0);
}

function eq(EntityId self, EntityId other) pure returns (bool) {
  return EntityId.unwrap(self) == EntityId.unwrap(other);
}

function neq(EntityId self, EntityId other) pure returns (bool) {
  return EntityId.unwrap(self) != EntityId.unwrap(other);
}

function decreaseEnergy(EntityId self, EnergyData memory currentEnergyData, uint128 amount) {
  uint128 currentEnergy = currentEnergyData.energy;
  require(currentEnergy >= amount, "Not enough energy");
  Energy._set(self, EnergyData({ energy: currentEnergy - amount, lastUpdatedTime: uint128(block.timestamp) }));
}

using { baseEntityId, getChipAddress, exists, eq as ==, neq as !=, decreaseEnergy } for EntityId global;
