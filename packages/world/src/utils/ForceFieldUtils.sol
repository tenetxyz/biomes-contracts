// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceField } from "../codegen/tables/ForceField.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Chip } from "../codegen/tables/Chip.sol";

import { getUniqueEntity } from "../Utils.sol";

import { Position, ForceFieldShard, ForceFieldShardData, ForceFieldShardPosition } from "../utils/Vec3Storage.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";

/**
 * @dev Check if a shard is active in a specific forcefield
 */
function _isShardActive(ForceFieldShardData memory shardData, EntityId forceFieldId) view returns (bool) {
  // Short-circuit to avoid unnecessary storage reads
  if (!forceFieldId.exists() || shardData.forceFieldId != forceFieldId) {
    return false;
  }

  // Only perform the storage read if the previous checks pass
  return shardData.forceFieldCreatedAt == ForceField._getCreatedAt(forceFieldId);
}

/**
 * @dev Get the forcefield and shard entity IDs for a given coordinate
 */
function getForceField(Vec3 coord) view returns (EntityId, EntityId) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  if (!_isShardActive(shardData, shardData.forceFieldId)) {
    return (EntityId.wrap(0), shardData.entityId);
  }

  return (shardData.forceFieldId, shardData.entityId);
}

/**
 * @dev Check if the shard at coord belongs to a forcefield
 */
function isForceFieldShard(EntityId forceFieldEntityId, Vec3 shardCoord) view returns (bool) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);
  return _isShardActive(shardData, forceFieldEntityId);
}

/**
 * @dev Check if the shard at coord is active and belongs to any forcefield
 */
function isForceFieldShardActive(Vec3 shardCoord) view returns (bool) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);
  return _isShardActive(shardData, shardData.forceFieldId);
}

/**
 * @dev Check if the is active and belongs to any forcefield
 */
function isForceFieldShardActive(EntityId shardEntityId) view returns (bool) {
  Vec3 shardCoord = ForceFieldShardPosition._get(shardEntityId);
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);
  return _isShardActive(shardData, shardData.forceFieldId);
}

/**
 * @dev Check if the forcefield is active (exists and hasn't been destroyed
 */
function isForceFieldActive(EntityId forceFieldEntityId) view returns (bool) {
  return forceFieldEntityId.exists() && ForceField._getCreatedAt(forceFieldEntityId) > 0;
}

/**
 * @dev Set up a new forcefield with its initial shard
 */
function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  // Set up the forcefield first
  ForceField._setCreatedAt(forceFieldEntityId, uint128(block.timestamp));

  Vec3 shardCoord = coord.toForceFieldShardCoord();
  setupForceFieldShard(forceFieldEntityId, shardCoord);
}

/**
 * @dev Add a shard to an existing forcefield
 */
function setupForceFieldShard(EntityId forceFieldEntityId, Vec3 shardCoord) returns (EntityId) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  // Create a new shard entity if needed
  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
    ForceFieldShardPosition._set(shardData.entityId, shardCoord);
    ObjectType._set(shardData.entityId, ObjectTypes.ForceFieldShard);
  }

  // Update the shard data to associate it with the forcefield
  shardData.forceFieldId = forceFieldEntityId;
  shardData.forceFieldCreatedAt = ForceField._getCreatedAt(forceFieldEntityId);

  Chip._deleteRecord(shardData.entityId);

  ForceFieldShard._set(shardCoord, shardData);
  return shardData.entityId;
}

/**
 * @dev Remove a shard from a forcefield
 */
function removeForceFieldShard(Vec3 shardCoord) returns (EntityId) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  Chip._deleteRecord(shardData.entityId);

  // Disassociate the shard from the forcefield
  ForceFieldShard._deleteRecord(shardCoord);
  return shardData.entityId;
}

/**
 * @dev Destroy a forcefield
 */
function destroyForceField(EntityId forceFieldEntityId) {
  Chip._deleteRecord(forceFieldEntityId);
  ForceField._deleteRecord(forceFieldEntityId);
}
