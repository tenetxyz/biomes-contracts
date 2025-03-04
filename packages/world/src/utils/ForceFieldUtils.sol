// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceFieldMetadata, ForceFieldMetadataData } from "../codegen/tables/ForceFieldMetadata.sol";
import { ForceFieldShard } from "../utils/Vec3Storage.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";

function getOrCreateForceFieldShard(Vec3 coord) view returns (EntityId) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  EntityId shardEntityId = ForceFieldShard._get(shardCoord);
  if (!shardEntityId.exists()) {
    shardEntityId = getUniqueEntity();
    ForceFieldShard._set(shardCoord, shardEntityId);
  }

  return shardEntityId;
}

function getForceField(Vec3 coord) view returns (EntityId) {
  EntityId shardEntityId = getOrCreateForceFieldShard(coord);
  // TODO: should actually use baseentity table directly
  EntityId forcefieldEntityId = shardEntityId.baseEntityId();
  if (
    !forcefieldEntityId.exists() ||
    ForceFieldShardMetadata._getCreatedAt(shardEntityId) < ForceFieldMetadata._getCreatedAt(forcefieldEntityId)
  ) {
    return EntityId.wrap(0);
  }

  return forceFieldEntityId;
}

function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  EntityId shardEntityId = getOrCreateForceFieldShard(coord);
  BaseEntity._set(shardEntityId, forceFieldEntityId);
  ForceFieldMetadata._set(forceFieldEntityId, ForceFieldMetadataData({ destroyedAt: 0, totalMassInside: 0 }));
}

function destroyForceField(EntityId forceFieldEntityId, Vec3 coord) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceField._deleteRecord(shardCoord);
}
