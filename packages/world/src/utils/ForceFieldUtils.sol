// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../Types.sol";
import { coordToShardCoord } from "./VoxelCoordUtils.sol";

import { ForceField } from "../codegen/tables/ForceField.sol";

import { FORCE_FIELD_SHARD_DIM } from "../Constants.sol";

function getForceField(VoxelCoord memory coord) view returns (bytes32) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  return ForceField._get(shardCoord.x, shardCoord.y, shardCoord.z);
}

function setupForceField(bytes32 forceFieldEntityId, VoxelCoord memory coord) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  ForceField._set(shardCoord.x, shardCoord.y, shardCoord.z, forceFieldEntityId);
}

function destroyForceField(bytes32 forceFieldEntityId, VoxelCoord memory coord) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  ForceField._deleteRecord(shardCoord.x, shardCoord.y, shardCoord.z);
}
