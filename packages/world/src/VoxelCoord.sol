// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { PositionData } from "./codegen/tables/Position.sol";
import { LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";
import { floorDiv, absInt32 } from "./utils/MathUtils.sol";
import { FORCE_FIELD_SHARD_DIM, SPAWN_SHARD_DIM } from "./Constants.sol";

struct VoxelCoord {
  int32 x;
  int32 y;
  int32 z;
}

// Define an enum representing all possible 3D movements in a Moore neighborhood
enum VoxelCoordDirection {
  PositiveX, // +1 in the x direction
  NegativeX, // -1 in the x direction
  PositiveY, // +1 in the y direction
  NegativeY, // -1 in the y direction
  PositiveZ, // +1 in the z direction
  NegativeZ, // -1 in the z direction
  PositiveXPositiveY, // +1 in x and +1 in y
  PositiveXNegativeY, // +1 in x and -1 in y
  PositiveXPositiveZ, // +1 in x and +1 in z
  PositiveXNegativeZ, // +1 in x and -1 in z
  NegativeXPositiveY, // -1 in x and +1 in y
  NegativeXNegativeY, // -1 in x and -1 in y
  NegativeXPositiveZ, // -1 in x and +1 in z
  NegativeXNegativeZ, // -1 in x and -1 in z
  PositiveYPositiveZ, // +1 in y and +1 in z
  PositiveYNegativeZ, // +1 in y and -1 in z
  NegativeYPositiveZ, // -1 in y and +1 in z
  NegativeYNegativeZ, // -1 in y and -1 in z
  PositiveXPositiveYPositiveZ, // +1 in x, +1 in y, +1 in z
  PositiveXPositiveYNegativeZ, // +1 in x, +1 in y, -1 in z
  PositiveXNegativeYPositiveZ, // +1 in x, -1 in y, +1 in z
  PositiveXNegativeYNegativeZ, // +1 in x, -1 in y, -1 in z
  NegativeXPositiveYPositiveZ, // -1 in x, +1 in y, +1 in z
  NegativeXPositiveYNegativeZ, // -1 in x, +1 in y, -1 in z
  NegativeXNegativeYPositiveZ, // -1 in x, -1 in y, +1 in z
  NegativeXNegativeYNegativeZ // -1 in x, -1 in y, -1 in z
}

// Define an enum representing all possible 3D movements in a Von Neumann neighborhood
enum VoxelCoordDirectionVonNeumann {
  PositiveX,
  NegativeX,
  PositiveY,
  NegativeY,
  PositiveZ,
  NegativeZ
}

library VoxelCoordLib {
  function equals(VoxelCoord memory c1, VoxelCoord memory c2) internal pure returns (bool) {
    return c1.x == c2.x && c1.y == c2.y && c1.z == c2.z;
  }

  function inSurroundingCube(
    VoxelCoord memory cubeCenter,
    int32 halfWidth,
    VoxelCoord memory checkCoord
  ) internal pure returns (bool) {
    // Check if checkCoord is within the cube in all three dimensions
    bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
    bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
    bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

    return isInX && isInY && isInZ;
  }

  function inSurroundingCubeIgnoreY(
    VoxelCoord memory cubeCenter,
    int32 halfWidth,
    VoxelCoord memory checkCoord
  ) internal pure returns (bool) {
    // Check if checkCoord is within the cube in all three dimensions
    bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
    bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

    return isInX && isInZ;
  }

  function toShardCoord(
    VoxelCoord memory coord,
    int32 shardDim,
    bool ignoreY
  ) internal pure returns (VoxelCoord memory) {
    return
      VoxelCoord({
        x: floorDiv(coord.x, shardDim),
        y: ignoreY ? int32(0) : floorDiv(coord.y, shardDim),
        z: floorDiv(coord.z, shardDim)
      });
  }

  function toForceFieldShardCoord(VoxelCoord memory coord) internal pure returns (VoxelCoord memory) {
    return toShardCoord(coord, FORCE_FIELD_SHARD_DIM, true);
  }

  function toSpawnShardCoord(VoxelCoord memory coord) internal pure returns (VoxelCoord memory) {
    return toShardCoord(coord, SPAWN_SHARD_DIM, false);
  }

  function fromShardCoord(VoxelCoord memory coord, int32 shardDim) internal pure returns (VoxelCoord memory) {
    return VoxelCoord({ x: coord.x * shardDim, y: coord.y * shardDim, z: coord.z * shardDim });
  }

  // Function to get the new VoxelCoord based on the direction
  function transform(
    VoxelCoord memory originalCoord,
    VoxelCoordDirection direction
  ) internal pure returns (VoxelCoord memory) {
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

  function transform(
    VoxelCoord memory originalCoord,
    VoxelCoordDirectionVonNeumann direction
  ) internal pure returns (VoxelCoord memory) {
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

  function inVonNeumannNeighborhood(
    VoxelCoord memory center,
    VoxelCoord memory checkCoord
  ) internal pure returns (bool) {
    // Calculate Manhattan distance for each dimension
    int32 dx = absInt32(center.x - checkCoord.x);
    int32 dy = absInt32(center.y - checkCoord.y);
    int32 dz = absInt32(center.z - checkCoord.z);

    // Sum of distances should be exactly 1 for von Neumann neighborhood
    // This means only one coordinate can differ by 1, others must be 0
    return (dx + dy + dz == 1);
  }

  function toVoxelCoord(PositionData memory self) internal pure returns (VoxelCoord memory) {
    return VoxelCoord(self.x, self.y, self.z);
  }

  function toVoxelCoord(LastKnownPositionData memory self) internal pure returns (VoxelCoord memory) {
    return VoxelCoord(self.x, self.y, self.z);
  }
}

using VoxelCoordLib for VoxelCoord global;
