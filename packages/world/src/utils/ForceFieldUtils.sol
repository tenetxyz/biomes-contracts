// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceField, ForceFieldData } from "../codegen/tables/ForceField.sol";

import { getUniqueEntity } from "../Utils.sol";

import { ForceFieldShard, ForceFieldShardData } from "../utils/Vec3Storage.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";

function increaseForceFieldMass(Vec3 coord, uint128 mass) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
  } else {
    if (
      shardData.forcefieldId.exists() &&
      // TODO: what if a shard was added to the removed forcefield in the same block?
      shardData.lastAddedToForceField >= ForceField._getCreatedAt(shardData.forcefieldId)
    ) {
      ForceField._setTotalMassInside(
        shardData.forceFieldId,
        ForceField._getTotalMassInside(shardData.forceFieldId) + mass
      );
    }
  }

  shardData.totalMassInside += mass;

  ForceFieldShard._set(shardCoord, shardData);
}

function decreaseForceFieldMass(Vec3 coord, uint128 mass) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
  } else {
    if (
      shardData.forcefieldId.exists() &&
      // TODO: what if a shard was added to the removed forcefield in the same block?
      shardData.lastAddedToForceField >= ForceField._getCreatedAt(shardData.forcefieldId)
    ) {
      ForceField._setTotalMassInside(
        shardData.forceFieldId,
        ForceField._getTotalMassInside(shardData.forceFieldId) + mass
      );
    }
  }

  shardData.totalMassInside -= mass;

  ForceFieldShard._set(shardCoord, shardData);
}

function getOrCreateForceFieldShard(Vec3 coord) view returns (ForceFieldShardData memory) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);
  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
    ForceFieldShard._setEntityId(shardCoord, shardData.entityId);
  }

  return shardData;
}

function getForceFieldShard(Vec3 coord) view returns (ForceFieldShardData memory) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  return ForceFieldShard._get(shardCoord);
}

function getForceField(Vec3 coord) view returns (EntityId) {
  ForceFieldShardData memory shardData = getOrCreateForceFieldShard(coord);
  if (
    !shardData.forcefieldId.exists() ||
    shardData.lastAddedToForceField <= ForceField._getCreatedAt(shardData.forcefieldId)
  ) {
    return EntityId.wrap(0);
  }

  return shardData.forceFieldId;
}

function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  ForceFieldShardData memory shardData = getOrCreateForceFieldShard(coord);
  shardData.lastAddedToForceField = block.timestamp;
  shardData.forceFieldId = forceFieldEntityId;
  ForceFieldShard._set(coord, shardData);
  ForceField._set(
    forceFieldEntityId,
    ForceFieldData({ createdAt: block.timestamp, totalMassInside: shardData.totalMassInside })
  );
}

function destroyForceField(EntityId forceFieldEntityId) {
  ForceField._deleteRecord(forceFieldEntityId);
}
