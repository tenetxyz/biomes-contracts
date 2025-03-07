// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceField } from "../codegen/tables/ForceField.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Chip } from "../codegen/tables/Chip.sol";

import { getUniqueEntity } from "../Utils.sol";

import { Position, ForceFieldFragment, ForceFieldFragmentData, ForceFieldFragmentPosition } from "../utils/Vec3Storage.sol";

import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";

/**
 * @dev Check if a fragment is active in a specific forcefield
 */
function _isFragmentActive(ForceFieldFragmentData memory fragmentData, EntityId forceFieldId) view returns (bool) {
  // Short-circuit to avoid unnecessary storage reads
  if (!forceFieldId.exists() || fragmentData.forceFieldId != forceFieldId) {
    return false;
  }

  // Only perform the storage read if the previous checks pass
  return fragmentData.forceFieldCreatedAt == ForceField._getCreatedAt(forceFieldId);
}

/**
 * @dev Get the forcefield and fragment entity IDs for a given coordinate
 */
function getForceField(Vec3 coord) view returns (EntityId, EntityId) {
  Vec3 fragmentCoord = coord.toForceFieldFragmentCoord();
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);

  if (!_isFragmentActive(fragmentData, fragmentData.forceFieldId)) {
    return (EntityId.wrap(0), fragmentData.entityId);
  }

  return (fragmentData.forceFieldId, fragmentData.entityId);
}

/**
 * @dev Check if the fragment at coord belongs to a forcefield
 */
function isForceFieldFragment(EntityId forceFieldEntityId, Vec3 fragmentCoord) view returns (bool) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);
  return _isFragmentActive(fragmentData, forceFieldEntityId);
}

/**
 * @dev Check if the fragment at coord is active and belongs to any forcefield
 */
function isForceFieldFragmentActive(Vec3 fragmentCoord) view returns (bool) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);
  return _isFragmentActive(fragmentData, fragmentData.forceFieldId);
}

/**
 * @dev Check if the is active and belongs to any forcefield
 */
function isForceFieldFragmentActive(EntityId fragmentEntityId) view returns (bool) {
  Vec3 fragmentCoord = ForceFieldFragmentPosition._get(fragmentEntityId);
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);
  return _isFragmentActive(fragmentData, fragmentData.forceFieldId);
}

/**
 * @dev Check if the forcefield is active (exists and hasn't been destroyed
 */
function isForceFieldActive(EntityId forceFieldEntityId) view returns (bool) {
  return forceFieldEntityId.exists() && ForceField._getCreatedAt(forceFieldEntityId) > 0;
}

/**
 * @dev Set up a new forcefield with its initial fragment
 */
function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  // Set up the forcefield first
  ForceField._setCreatedAt(forceFieldEntityId, uint128(block.timestamp));

  Vec3 fragmentCoord = coord.toForceFieldFragmentCoord();
  setupForceFieldFragment(forceFieldEntityId, fragmentCoord);
}

/**
 * @dev Add a fragment to an existing forcefield
 */
function setupForceFieldFragment(EntityId forceFieldEntityId, Vec3 fragmentCoord) returns (EntityId) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);

  // Create a new fragment entity if needed
  if (!fragmentData.entityId.exists()) {
    fragmentData.entityId = getUniqueEntity();
    ForceFieldFragmentPosition._set(fragmentData.entityId, fragmentCoord);
    ObjectType._set(fragmentData.entityId, ObjectTypes.ForceFieldFragment);
  }

  // Update the fragment data to associate it with the forcefield
  fragmentData.forceFieldId = forceFieldEntityId;
  fragmentData.forceFieldCreatedAt = ForceField._getCreatedAt(forceFieldEntityId);

  Chip._deleteRecord(fragmentData.entityId);

  ForceFieldFragment._set(fragmentCoord, fragmentData);
  return fragmentData.entityId;
}

/**
 * @dev Remove a fragment from a forcefield
 */
function removeForceFieldFragment(Vec3 fragmentCoord) returns (EntityId) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);

  Chip._deleteRecord(fragmentData.entityId);

  // Disassociate the fragment from the forcefield
  ForceFieldFragment._deleteRecord(fragmentCoord);
  return fragmentData.entityId;
}

/**
 * @dev Destroy a forcefield
 */
function destroyForceField(EntityId forceFieldEntityId) {
  Chip._deleteRecord(forceFieldEntityId);
  ForceField._deleteRecord(forceFieldEntityId);
}
