// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Chip } from "./codegen/tables/Chip.sol";
import { BaseEntity } from "./codegen/tables/BaseEntity.sol";

type EntityId is bytes32;

function baseEntityId(EntityId self) view returns (EntityId) {
  EntityId base = BaseEntity.get(self);
  return EntityId.unwrap(base) == bytes32(0) ? self : base;
}

function getChipAddress(EntityId entityId) view returns (address) {
  ResourceId chipSystemId = Chip.getChipSystemId(entityId);
  (address chipAddress, ) = Systems.get(chipSystemId);
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

using { baseEntityId, getChipAddress, exists, eq as ==, neq as != } for EntityId global;
