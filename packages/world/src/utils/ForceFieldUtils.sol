// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ShardFields } from "../codegen/tables/ShardFields.sol";
import { ForceField, ForceFieldData } from "../codegen/tables/ForceField.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { FORCE_FIELD_SHARD_DIM, FORCE_FIELD_DIM } from "../Constants.sol";

function getForceField(VoxelCoord memory coord) returns (bytes32) {
  VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(coord, FORCE_FIELD_SHARD_DIM);
  bytes32[] memory forceFieldEntityIds = ShardFields._get(shardCoord.x, shardCoord.z);
  for (uint i = 0; i < forceFieldEntityIds.length; i++) {
    ForceFieldData memory forceFieldData = ForceField._get(forceFieldEntityIds[i]);

    // Check if coord inside of force field
    if (
      coord.x >= forceFieldData.fieldLowX &&
      coord.x <= forceFieldData.fieldHighX &&
      coord.z >= forceFieldData.fieldLowZ &&
      coord.z <= forceFieldData.fieldHighZ
    ) {
      return forceFieldEntityIds[i];
    }
  }
  return bytes32(0);
}
