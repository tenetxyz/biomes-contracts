// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EntityId } from "./EntityId.sol";

import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";
import { PositionData } from "./codegen/tables/Position.sol";
import { LocalEnergyPool } from "./codegen/tables/LocalEnergyPool.sol";
import { LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";
import { Position } from "./codegen/tables/Position.sol";
import { PlayerPosition, PlayerPositionData } from "./codegen/tables/PlayerPosition.sol";
import { ReversePosition } from "./codegen/tables/ReversePosition.sol";
import { ReversePlayerPosition } from "./codegen/tables/ReversePlayerPosition.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { Mass } from "./codegen/tables/Mass.sol";

import { ObjectTypeId } from "./ObjectTypeIds.sol";
import { TerrainLib } from "./systems/libraries/TerrainLib.sol";
import { getUniqueEntity } from "./Utils.sol";
import { floorDiv, absInt32 } from "./utils/MathUtils.sol";
import { FORCE_FIELD_SHARD_DIM, LOCAL_ENERGY_POOL_SHARD_DIM, CHUNK_SIZE } from "./Constants.sol";
import { ChunkCoord } from "./Types.sol";

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
    return toShardCoord(coord, FORCE_FIELD_SHARD_DIM, false);
  }

  // Note: Local Energy Pool shards are 2D for now, but the table supports 3D
  // Thats why the Y is ignored, and 0 in the util functions
  function toLocalEnergyPoolShardCoord(VoxelCoord memory coord) internal pure returns (VoxelCoord memory) {
    return toShardCoord(coord, LOCAL_ENERGY_POOL_SHARD_DIM, true);
  }

  function removeEnergyFromLocalPool(VoxelCoord memory coord, uint128 numToRemove) internal returns (uint128) {
    VoxelCoord memory shardCoord = coord.toLocalEnergyPoolShardCoord();
    uint128 localEnergy = LocalEnergyPool._get(shardCoord.x, 0, shardCoord.z);
    require(localEnergy >= numToRemove, "Not enough energy in local pool");
    uint128 newLocalEnergy = localEnergy - numToRemove;
    LocalEnergyPool._set(shardCoord.x, 0, shardCoord.z, newLocalEnergy);
    return newLocalEnergy;
  }

  function addEnergyToLocalPool(VoxelCoord memory coord, uint128 numToAdd) internal returns (uint128) {
    VoxelCoord memory shardCoord = coord.toLocalEnergyPoolShardCoord();
    uint128 newLocalEnergy = LocalEnergyPool._get(shardCoord.x, 0, shardCoord.z) + numToAdd;
    LocalEnergyPool._set(shardCoord.x, 0, shardCoord.z, newLocalEnergy);
    return newLocalEnergy;
  }

  function fromShardCoord(VoxelCoord memory coord, int32 shardDim) internal pure returns (VoxelCoord memory) {
    return VoxelCoord({ x: coord.x * shardDim, y: coord.y * shardDim, z: coord.z * shardDim });
  }

  function toChunkCoord(VoxelCoord memory coord) internal pure returns (ChunkCoord memory) {
    return
      ChunkCoord({
        x: floorDiv(coord.x, CHUNK_SIZE),
        y: floorDiv(coord.y, CHUNK_SIZE),
        z: floorDiv(coord.z, CHUNK_SIZE)
      });
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

  function toVoxelCoord(PlayerPositionData memory self) internal pure returns (VoxelCoord memory) {
    return VoxelCoord(self.x, self.y, self.z);
  }

  function toVoxelCoord(LastKnownPositionData memory self) internal pure returns (VoxelCoord memory) {
    return VoxelCoord(self.x, self.y, self.z);
  }

  function getEntity(VoxelCoord memory coord) internal view returns (EntityId, ObjectTypeId) {
    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (!entityId.exists()) {
      return (entityId, ObjectTypeId.wrap(TerrainLib._getBlockType(coord)));
    }
    return (entityId, ObjectType._get(entityId));
  }

  function getOrCreateEntity(VoxelCoord memory coord) internal returns (EntityId, ObjectTypeId) {
    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    ObjectTypeId objectTypeId;
    if (!entityId.exists()) {
      // TODO: move wrapping to TerrainLib?
      objectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(coord));

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
      ObjectType._set(entityId, objectTypeId);

      Mass._setMass(entityId, ObjectTypeMetadata._getMass(objectTypeId));
    } else {
      objectTypeId = ObjectType._get(entityId);
    }

    return (entityId, objectTypeId);
  }

  function getPlayer(VoxelCoord memory coord) internal view returns (EntityId) {
    return ReversePlayerPosition._get(coord.x, coord.y, coord.z);
  }

  function setPlayer(VoxelCoord memory coord, EntityId playerEntityId) internal {
    PlayerPosition._set(playerEntityId, coord.x, coord.y, coord.z);
    ReversePlayerPosition._set(coord.x, coord.y, coord.z, playerEntityId);
  }
}

using VoxelCoordLib for VoxelCoord global;
