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
function isFragmentActive(ForceFieldFragmentData memory fragmentData, EntityId forceFieldId) view returns (bool) {
  // Short-circuit to avoid unnecessary storage reads
  if (!forceFieldId.exists() || fragmentData.forceFieldId != forceFieldId) {
    return false;
  }

  // Only perform the storage read if the previous checks pass
  return fragmentData.forceFieldCreatedAt == ForceField._getCreatedAt(forceFieldId);
}

/**
 * @dev Check if the fragment at coord is active and belongs to the specified forcefield
 */
function isFragmentActive(Vec3 fragmentCoord, EntityId forceFieldEntityId) view returns (bool) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);
  return isFragmentActive(fragmentData, forceFieldEntityId);
}

/**
 * @dev Check if the fragment at coord is active and belongs to any forcefield
 */
function isFragmentActive(Vec3 fragmentCoord) view returns (bool) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);
  return isFragmentActive(fragmentData, fragmentData.forceFieldId);
}

/**
 * @dev Check if the fragment is active and belongs to any forcefield
 */
function isFragmentActive(EntityId fragmentEntityId) view returns (bool) {
  Vec3 fragmentCoord = ForceFieldFragmentPosition._get(fragmentEntityId);
  return isFragmentActive(fragmentCoord);
}

/**
 * @dev Get the forcefield and fragment entity IDs for a given coordinate
 */
function getForceField(Vec3 coord) view returns (EntityId, EntityId) {
  Vec3 fragmentCoord = coord.toForceFieldFragmentCoord();
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);

  if (!isFragmentActive(fragmentData, fragmentData.forceFieldId)) {
    return (EntityId.wrap(0), fragmentData.entityId);
  }

  return (fragmentData.forceFieldId, fragmentData.entityId);
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
 * TODO: make argument order consistent?
 */
function setupForceFieldFragment(EntityId forceFieldEntityId, Vec3 fragmentCoord) returns (EntityId) {
  ForceFieldFragmentData memory fragmentData = ForceFieldFragment._get(fragmentCoord);
  // Create a new fragment entity if needed
  if (!fragmentData.entityId.exists()) {
    fragmentData.entityId = getUniqueEntity();
    ForceFieldFragmentPosition._set(fragmentData.entityId, fragmentCoord);
    ObjectType._set(fragmentData.entityId, ObjectTypes.ForceFieldFragment);
  }

  require(fragmentData.entityId.getChip().unwrap() == 0, "Can't expand into a fragment with a chip");

  // Update the fragment data to associate it with the forcefield
  fragmentData.forceFieldId = forceFieldEntityId;
  fragmentData.forceFieldCreatedAt = ForceField._getCreatedAt(forceFieldEntityId);

  ForceFieldFragment._set(fragmentCoord, fragmentData);
  return fragmentData.entityId;
}

/**
 * @dev Remove a fragment from a forcefield
 */
function removeForceFieldFragment(EntityId fragmentEntityId, Vec3 fragmentCoord) {
  require(fragmentEntityId.getChip().unwrap() == 0, "Can't remove a fragment with a chip");

  // Disassociate the fragment from the forcefield
  ForceFieldFragment._deleteRecord(fragmentCoord);
}

/**
 * @dev Destroys a forcefield, without cleaning up its shards
 */
function destroyForceField(EntityId forceFieldEntityId) {
  Chip._deleteRecord(forceFieldEntityId);
  ForceField._deleteRecord(forceFieldEntityId);
}
