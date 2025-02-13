// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../VoxelCoord.sol";

import { ForceField } from "../codegen/tables/ForceField.sol";

import { EntityId } from "../EntityId.sol";

function getForceField(VoxelCoord memory coord) view returns (EntityId) {
  VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
  return ForceField._get(shardCoord.x, shardCoord.y, shardCoord.z);
}

function setupForceField(EntityId forceFieldEntityId, VoxelCoord memory coord) {
  VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
  ForceField._set(shardCoord.x, shardCoord.y, shardCoord.z, forceFieldEntityId);
}

function destroyForceField(EntityId forceFieldEntityId, VoxelCoord memory coord) {
  VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
  ForceField._deleteRecord(shardCoord.x, shardCoord.y, shardCoord.z);
}
