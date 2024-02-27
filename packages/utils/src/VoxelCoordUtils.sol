// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "./Types.sol";

function inSurroundingCube(
  VoxelCoord memory cubeCenter,
  int32 halfWidth,
  VoxelCoord memory checkCoord
) pure returns (bool) {
  // Check if `checkCoord` is within the cube in all three dimensions
  bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
  bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
  bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

  return isInX && isInY && isInZ;
}
