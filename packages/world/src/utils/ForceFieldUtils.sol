// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceField } from "../codegen/tables/ForceField.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { getUniqueEntity } from "../Utils.sol";

import { ForceFieldShard, ForceFieldShardData } from "../utils/Vec3Storage.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";

/**
 * @notice Check if a shard is active in a forcefield
 * @param shardData The shard data to check
 * @param forceFieldId The forcefield ID to check against
 * @return True if the shard is active in the forcefield
 */
function _isShardActive(ForceFieldShardData memory shardData, EntityId forceFieldId) view returns (bool) {
  // Short-circuit to avoid unnecessary storage reads
  if (!forceFieldId.exists() || shardData.forceFieldId != forceFieldId) {
    return false;
  }

  // Only perform the storage read if the previous checks pass
  uint128 createdAt = ForceField._getCreatedAt(forceFieldId);
  return createdAt > 0 && shardData.lastAddedToForceField > createdAt;
}

/**
 * @notice Get the forcefield entity ID for a given coordinate
 * @param coord The coordinate to check
 * @return The forcefield entity ID, or 0 if no active forcefield exists
 */
function getForceField(Vec3 coord) view returns (EntityId) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  if (!_isShardActive(shardData, shardData.forceFieldId)) {
    return EntityId.wrap(0);
  }

  return shardData.forceFieldId;
}

/**
 * @notice Check if a shard belongs to a specific forcefield
 * @param forceFieldEntityId The forcefield entity ID to check
 * @param shardCoord The shard coordinate to check
 * @return True if the shard belongs to the forcefield
 */
function isForceFieldShard(EntityId forceFieldEntityId, Vec3 shardCoord) view returns (bool) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);
  return _isShardActive(shardData, forceFieldEntityId);
}

/**
 * @notice Set up a new forcefield with its initial shard
 * @param forceFieldEntityId The forcefield entity ID
 * @param coord The coordinate for the initial shard
 */
function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  // Check if a forcefield already exists for this shard
  if (_isShardActive(shardData, shardData.forceFieldId)) {
    revert("Forcefield already exists for this shard");
  }

  // Create a new shard entity if needed
  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
    ObjectType._set(shardData.entityId, ObjectTypes.ForceFieldShard);
  }

  // Set up the forcefield first
  ForceField._setCreatedAt(forceFieldEntityId, uint128(block.timestamp));

  // We add one to the timestamp to ensure it's greater than the forcefield creation time
  shardData.lastAddedToForceField = uint128(block.timestamp) + 1;
  shardData.forceFieldId = forceFieldEntityId;

  ForceFieldShard._set(shardCoord, shardData);
}

/**
 * @notice Add a shard to an existing forcefield
 * @param forceFieldEntityId The forcefield entity ID
 * @param shardCoord The shard coordinate to add
 * @return The shard entity ID
 */
function setupForceFieldShard(EntityId forceFieldEntityId, Vec3 shardCoord) returns (EntityId) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  // Check if a forcefield already exists for this shard
  if (_isShardActive(shardData, shardData.forceFieldId)) {
    revert("Shard already belongs to a forcefield");
  }

  // Create a new shard entity if needed
  if (!shardData.entityId.exists()) {
    shardData.entityId = getUniqueEntity();
    ObjectType._set(shardData.entityId, ObjectTypes.ForceFieldShard);
  }

  // Update the shard data to associate it with the forcefield
  shardData.lastAddedToForceField = uint128(block.timestamp);
  shardData.forceFieldId = forceFieldEntityId;

  ForceFieldShard._set(shardCoord, shardData);
  return shardData.entityId;
}

/**
 * @notice Remove a shard from a forcefield
 * @param forceFieldEntityId The forcefield entity ID
 * @param shardCoord The shard coordinate to remove
 * @return The shard entity ID
 */
function removeForceFieldShard(EntityId forceFieldEntityId, Vec3 shardCoord) returns (EntityId) {
  ForceFieldShardData memory shardData = ForceFieldShard._get(shardCoord);

  // Check if the shard belongs to the specified forcefield
  if (shardData.forceFieldId != forceFieldEntityId) {
    revert("Shard does not belong to the forcefield");
  }

  // Check if the shard is active in the forcefield
  if (!_isShardActive(shardData, forceFieldEntityId)) {
    revert("Shard does not belong to a forcefield");
  }

  // Disassociate the shard from the forcefield
  shardData.forceFieldId = EntityId.wrap(0);
  shardData.lastAddedToForceField = 0;

  ForceFieldShard._set(shardCoord, shardData);
  return shardData.entityId;
}

/**
 * @notice Destroy a forcefield
 * @param forceFieldEntityId The forcefield entity ID to destroy
 */
function destroyForceField(EntityId forceFieldEntityId) {
  ForceField._deleteRecord(forceFieldEntityId);
}
