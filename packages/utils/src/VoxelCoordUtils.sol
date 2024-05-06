// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "./Types.sol";
import { floorDiv } from "./MathUtils.sol";

function voxelCoordsAreEqual(VoxelCoord memory c1, VoxelCoord memory c2) pure returns (bool) {
  return c1.x == c2.x && c1.y == c2.y && c1.z == c2.z;
}

function inSurroundingCube(
  VoxelCoord memory cubeCenter,
  int16 halfWidth,
  VoxelCoord memory checkCoord
) pure returns (bool) {
  // Check if checkCoord is within the cube in all three dimensions
  bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
  bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
  bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

  return isInX && isInY && isInZ;
}

function inSurroundingCubeIgnoreY(
  VoxelCoord memory cubeCenter,
  int16 halfWidth,
  VoxelCoord memory checkCoord
) pure returns (bool) {
  // Check if checkCoord is within the cube in all three dimensions
  bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
  bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

  return isInX && isInZ;
}

function coordToShardCoord(VoxelCoord memory coord, int16 shardDim) pure returns (VoxelCoord memory) {
  return VoxelCoord({ x: floorDiv(coord.x, shardDim), y: floorDiv(coord.y, shardDim), z: floorDiv(coord.z, shardDim) });
}

function coordToShardCoordIgnoreY(VoxelCoord memory coord, int16 shardDim) pure returns (VoxelCoord memory) {
  return VoxelCoord({ x: floorDiv(coord.x, shardDim), y: 0, z: floorDiv(coord.z, shardDim) });
}

function shardCoordToCoord(VoxelCoord memory coord, int16 shardDim) pure returns (VoxelCoord memory) {
  return VoxelCoord({ x: coord.x * shardDim, y: coord.y * shardDim, z: coord.z * shardDim });
}
