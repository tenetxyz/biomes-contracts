// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceField, ForceFieldData } from "../codegen/tables/ForceField.sol";

import { getUniqueEntity } from "../Utils.sol";

import { ForceFieldShard } from "../utils/Vec3Storage.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";

function getOrCreateForceFieldShard(Vec3 coord) view returns (ForceFieldShardData memory) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData shardData = ForceFieldShard._get(shardCoord);
  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
    ForceFieldShard._setEntityId(shardCoord, shardData.entityId);
  }

  return shardData;
}

function getForceField(Vec3 coord) view returns (EntityId) {
  ForceFieldShardData shardData = getOrCreateForceFieldShard(coord);
  if (
    !shardData.forcefieldId.exists() ||
    shardData.lastAddedToForceField <= ForceField._getCreatedAt(shardData.forcefieldId)
  ) {
    return EntityId.wrap(0);
  }

  return shardData.forceFieldId;
}

function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  ForceFieldShardData shardData = getOrCreateForceFieldShard(coord);
  ForceFieldShard._setLastAddedToForceField(block.timestamp);
  ForceField._set(
    forceFieldEntityId,
    ForceFieldData({ createdAt: block.timestamp, totalMassInside: shardData.totalMassInside })
  );
}

function destroyForceField(EntityId forceFieldEntityId) {
  ForceField._deleteRecord(forceFieldEntityId);
}
