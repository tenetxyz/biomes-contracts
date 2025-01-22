// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordDirection, VoxelCoordDirectionVonNeumann } from "./Types.sol";
import { floorDiv, absInt16 } from "./MathUtils.sol";

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

// Function to get the new VoxelCoord based on the direction
function transformVoxelCoord(
  VoxelCoord memory originalCoord,
  VoxelCoordDirection direction
) pure returns (VoxelCoord memory) {
  VoxelCoord memory newCoord = VoxelCoord({ x: originalCoord.x, y: originalCoord.y, z: originalCoord.z });

  // Update newCoord based on the direction
  if (direction == VoxelCoordDirection.PositiveX) {
    newCoord.x += 1;
  } else if (direction == VoxelCoordDirection.NegativeX) {
    newCoord.x -= 1;
  } else if (direction == VoxelCoordDirection.PositiveY) {
    newCoord.y += 1;
  } else if (direction == VoxelCoordDirection.NegativeY) {
    newCoord.y -= 1;
  } else if (direction == VoxelCoordDirection.PositiveZ) {
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.NegativeZ) {
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.PositiveXPositiveY) {
    newCoord.x += 1;
    newCoord.y += 1;
  } else if (direction == VoxelCoordDirection.PositiveXNegativeY) {
    newCoord.x += 1;
    newCoord.y -= 1;
  } else if (direction == VoxelCoordDirection.PositiveXPositiveZ) {
    newCoord.x += 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.PositiveXNegativeZ) {
    newCoord.x += 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.NegativeXPositiveY) {
    newCoord.x -= 1;
    newCoord.y += 1;
  } else if (direction == VoxelCoordDirection.NegativeXNegativeY) {
    newCoord.x -= 1;
    newCoord.y -= 1;
  } else if (direction == VoxelCoordDirection.NegativeXPositiveZ) {
    newCoord.x -= 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.NegativeXNegativeZ) {
    newCoord.x -= 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.PositiveYPositiveZ) {
    newCoord.y += 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.PositiveYNegativeZ) {
    newCoord.y += 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.NegativeYPositiveZ) {
    newCoord.y -= 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.NegativeYNegativeZ) {
    newCoord.y -= 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.PositiveXPositiveYPositiveZ) {
    newCoord.x += 1;
    newCoord.y += 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.PositiveXPositiveYNegativeZ) {
    newCoord.x += 1;
    newCoord.y += 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.PositiveXNegativeYPositiveZ) {
    newCoord.x += 1;
    newCoord.y -= 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.PositiveXNegativeYNegativeZ) {
    newCoord.x += 1;
    newCoord.y -= 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.NegativeXPositiveYPositiveZ) {
    newCoord.x -= 1;
    newCoord.y += 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.NegativeXPositiveYNegativeZ) {
    newCoord.x -= 1;
    newCoord.y += 1;
    newCoord.z -= 1;
  } else if (direction == VoxelCoordDirection.NegativeXNegativeYPositiveZ) {
    newCoord.x -= 1;
    newCoord.y -= 1;
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirection.NegativeXNegativeYNegativeZ) {
    newCoord.x -= 1;
    newCoord.y -= 1;
    newCoord.z -= 1;
  }

  return newCoord; // Return the updated coordinates
}

function transformVoxelCoordVonNeumann(
  VoxelCoord memory originalCoord,
  VoxelCoordDirectionVonNeumann direction
) pure returns (VoxelCoord memory) {
  VoxelCoord memory newCoord = VoxelCoord({ x: originalCoord.x, y: originalCoord.y, z: originalCoord.z });

  if (direction == VoxelCoordDirectionVonNeumann.PositiveX) {
    newCoord.x += 1;
  } else if (direction == VoxelCoordDirectionVonNeumann.NegativeX) {
    newCoord.x -= 1;
  } else if (direction == VoxelCoordDirectionVonNeumann.PositiveY) {
    newCoord.y += 1;
  } else if (direction == VoxelCoordDirectionVonNeumann.NegativeY) {
    newCoord.y -= 1;
  } else if (direction == VoxelCoordDirectionVonNeumann.PositiveZ) {
    newCoord.z += 1;
  } else if (direction == VoxelCoordDirectionVonNeumann.NegativeZ) {
    newCoord.z -= 1;
  }

  return newCoord;
}

function inVonNeumannNeighborhood(VoxelCoord memory center, VoxelCoord memory checkCoord) pure returns (bool) {
  // Calculate Manhattan distance for each dimension
  int16 dx = absInt16(center.x - checkCoord.x);
  int16 dy = absInt16(center.y - checkCoord.y);
  int16 dz = absInt16(center.z - checkCoord.z);

  // Sum of distances should be exactly 1 for von Neumann neighborhood
  // This means only one coordinate can differ by 1, others must be 0
  return (dx + dy + dz == 1);
}
