// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ShardField } from "../codegen/tables/ShardField.sol";

import { FORCE_FIELD_SHARD_DIM } from "../Constants.sol";

function getForceField(VoxelCoord memory coord) view returns (bytes32) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  return ShardField._get(shardCoord.x, shardCoord.y, shardCoord.z);
}

function setupForceField(bytes32 forceFieldEntityId, VoxelCoord memory coord) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  ShardField._set(shardCoord.x, shardCoord.y, shardCoord.z, forceFieldEntityId);
}

function destroyForceField(bytes32 forceFieldEntityId, VoxelCoord memory coord) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  ShardField._deleteRecord(shardCoord.x, shardCoord.y, shardCoord.z);
}
