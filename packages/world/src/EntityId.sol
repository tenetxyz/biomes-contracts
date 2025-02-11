// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BaseEntity } from "./codegen/tables/BaseEntity.sol";

type EntityId is bytes32;

function baseEntityId(EntityId self) view returns (EntityId) {
  EntityId base = BaseEntity._get(self);
  return EntityId.unwrap(base) == bytes32(0) ? self : base;
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

using { baseEntityId, exists, eq as ==, neq as != } for EntityId global;
