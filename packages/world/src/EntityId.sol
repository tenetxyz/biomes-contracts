// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Chip } from "./codegen/tables/Chip.sol";
import { BaseEntity } from "./codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "./codegen/tables/Energy.sol";

type EntityId is bytes32;

library EntityIdLib {
  function isBaseEntity(EntityId self) internal view returns (bool) {
    return EntityId.unwrap(BaseEntity._get(self)) == bytes32(0);
  }

  function baseEntityId(EntityId self) internal view returns (EntityId) {
    EntityId base = BaseEntity._get(self);
    return EntityId.unwrap(base) == bytes32(0) ? self : base;
  }

  function getChipAddress(EntityId entityId) internal view returns (address) {
    ResourceId chipSystemId = entityId.getChip();
    (address chipAddress, ) = Systems._get(chipSystemId);
    return chipAddress;
  }

  function getChip(EntityId entityId) internal view returns (ResourceId) {
    return Chip._getChipSystemId(entityId);
  }

  function exists(EntityId self) internal pure returns (bool) {
    return EntityId.unwrap(self) != bytes32(0);
  }

  function unwrap(EntityId self) internal pure returns (bytes32) {
    return EntityId.unwrap(self);
  }
}

function eq(EntityId self, EntityId other) pure returns (bool) {
  return EntityId.unwrap(self) == EntityId.unwrap(other);
}

function neq(EntityId self, EntityId other) pure returns (bool) {
  return EntityId.unwrap(self) != EntityId.unwrap(other);
}

using EntityIdLib for EntityId global;
using { eq as ==, neq as != } for EntityId global;
