// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/world/src/VoxelCoord.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ForceField } from "@biomesaw/world/src/codegen/tables/ForceField.sol";

import { getPosition } from "./EntityUtils.sol";

function getForceField(EntityId entityId) view returns (EntityId) {
  VoxelCoord memory coord = getPosition(entityId);
  VoxelCoord memory shardCoord = coord.toForceFieldShardCoord();
  return ForceField.get(shardCoord.x, shardCoord.y, shardCoord.z);
}
