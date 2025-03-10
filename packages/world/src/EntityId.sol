// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Chip } from "./codegen/tables/Chip.sol";
import { BaseEntity } from "./codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "./codegen/tables/Energy.sol";

type EntityId is bytes32;

enum EntityType {
  Player
}

function encodeEntityId(EntityType entityType, bytes31 data) pure returns (EntityId) {
  bytes32 result;
  uint8 t = uint8(entityType);

  /// @solidity memory-safe-assembly
  assembly {
    // Set the first byte to entity type
    result := or(result, shl(248, t))
    // Set the next 31 bytes as the data
    result := or(result, data)
  }
  return EntityId.wrap(result);
}

function decodeEntityId(EntityId entityId) pure returns (EntityType entityType, bytes31 data) {
  /// @solidity memory-safe-assembly
  assembly {
    entityType := shr(248, entityId)
    data := shr(8, shl(8, entityId))
  }
}

function encodePlayerEntityId(address playerAddress) pure returns (EntityId) {
  return encodeEntityId(EntityType.Player, bytes31(bytes20(playerAddress)));
}

function decodePlayerEntityId(EntityId entityId) pure returns (address) {
  (EntityType entityType, bytes31 data) = decodeEntityId(entityId);
  require(entityType == EntityType.Player, "Invalid entity type");

  return address(bytes20(data));
}

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

  function setEnergy(EntityId self, uint128 energy) internal {
    Energy._setLastUpdatedTime(self, uint128(block.timestamp));
    Energy._setEnergy(self, energy);
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
