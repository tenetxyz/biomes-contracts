// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ForceField } from "../codegen/tables/ForceField.sol";

import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel } from "../utils/EnergyUtils.sol";
import { getUniqueEntity } from "../Utils.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { notify, ExpandForceFieldNotifData, ContractForceFieldNotifData } from "../utils/NotifUtils.sol";
import { isForceFieldShard, isForceFieldShardActive, setupForceFieldShard, removeForceFieldShard } from "../utils/ForceFieldUtils.sol";
import { ForceFieldShard } from "../utils/Vec3Storage.sol";

import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

// TODO: move to utils?

/**
 * @notice Validates that the boundary shards form a connected component using a spanning tree
 * @param boundaryShards Array of boundary shard coordinates
 * @param parents Array indicating the parent of each shard in the spanning tree
 * @return True if the spanning tree is valid and connects all boundary shards
 */
function validateSpanningTree(Vec3[] memory boundaryShards, uint256[] memory parents) pure returns (bool) {
  uint256 n = boundaryShards.length;

  if (n == 0) return true;
  if (n == 1) return parents.length == 1 && parents[0] == 0;

  // Validate parents array
  if (parents.length != n || parents[0] != 0) return false;

  // Track visited nodes
  bool[] memory visited = new bool[](n);
  visited[0] = true; // Mark root as visited
  uint256 visitedCount = 1;

  // Validate each node's parent relationship
  for (uint256 i = 1; i < n; i++) {
    uint256 parent = parents[i];

    // Parent must be in valid range, already visited and adjacent
    if (parent >= n || !visited[parent] || !boundaryShards[parent].inVonNeumannNeighborhood(boundaryShards[i])) {
      return false;
    }

    // Mark as visited
    visited[i] = true;
    visitedCount++;
  }

  return visitedCount == n;
}

/**
 * @notice Identify all boundary shards of a forcefield that are adjacent to a cuboid
 * @param forceFieldEntityId The forcefield entity ID
 * @param fromShardCoord The starting coordinate of the cuboid
 * @param toShardCoord The ending coordinate of the cuboid
 * @return An array of boundary shard coordinates
 */
function computeBoundaryShards(
  EntityId forceFieldEntityId,
  Vec3 fromShardCoord,
  Vec3 toShardCoord
) view returns (Vec3[] memory) {
  (int256 x1, int256 y1, int256 z1) = fromShardCoord.xyz();
  (int256 x2, int256 y2, int256 z2) = toShardCoord.xyz();

  Vec3[] memory tempBoundary;
  {
    uint256 dx = uint256(x2 - x1 + 1);
    uint256 dy = uint256(y2 - y1 + 1);
    uint256 dz = uint256(z2 - z1 + 1);
    uint256 maxSize = 2 * (dx * dy + dx * dz + dy * dz);
    tempBoundary = new Vec3[](maxSize);
  }

  uint256 count = 0;

  // Face at x = x1 - 1
  for (int256 y = y1; y <= y2; y++) {
    for (int256 z = z1; z <= z2; z++) {
      count = addBoundary(forceFieldEntityId, x1 - 1, y, z, tempBoundary, count);
    }
  }
  // Face at x = x2 + 1
  for (int256 y = y1; y <= y2; y++) {
    for (int256 z = z1; z <= z2; z++) {
      count = addBoundary(forceFieldEntityId, x2 + 1, y, z, tempBoundary, count);
    }
  }
  // Face at y = y1 - 1
  for (int256 x = x1; x <= x2; x++) {
    for (int256 z = z1; z <= z2; z++) {
      count = addBoundary(forceFieldEntityId, x, y1 - 1, z, tempBoundary, count);
    }
  }
  // Face at y = y2 + 1
  for (int256 x = x1; x <= x2; x++) {
    for (int256 z = z1; z <= z2; z++) {
      count = addBoundary(forceFieldEntityId, x, y2 + 1, z, tempBoundary, count);
    }
  }
  // Face at z = z1 - 1
  for (int256 x = x1; x <= x2; x++) {
    for (int256 y = y1; y <= y2; y++) {
      count = addBoundary(forceFieldEntityId, x, y, z1 - 1, tempBoundary, count);
    }
  }
  // Face at z = z2 + 1
  for (int256 x = x1; x <= x2; x++) {
    for (int256 y = y1; y <= y2; y++) {
      count = addBoundary(forceFieldEntityId, x, y, z2 + 1, tempBoundary, count);
    }
  }

  // Copy to a right-sized array
  // TODO: instead of iterating we could just return the array and the count
  Vec3[] memory boundaryShards = new Vec3[](count);
  for (uint256 i = 0; i < count; i++) {
    boundaryShards[i] = tempBoundary[i];
  }
  return boundaryShards;
}

function addBoundary(
  EntityId forceFieldEntityId,
  int256 x,
  int256 y,
  int256 z,
  Vec3[] memory tempBoundary,
  uint256 count
) view returns (uint256) {
  Vec3 shardCoord = vec3(int32(x), int32(y), int32(z));
  if (isForceFieldShard(forceFieldEntityId, shardCoord)) {
    tempBoundary[count] = shardCoord;
    return count + 1;
  }
  return count;
}

contract ForceFieldSystem is System {
  function expandForceField(
    EntityId forceFieldEntityId,
    Vec3 refShardCoord,
    Vec3 fromShardCoord,
    Vec3 toShardCoord
  ) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, forceFieldEntityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);

    require(fromShardCoord <= toShardCoord, "Invalid coordinates");

    require(
      refShardCoord.isAdjacentToCuboid(fromShardCoord, toShardCoord),
      "Reference shard is not adjacent to new shards"
    );

    require(isForceFieldShard(forceFieldEntityId, refShardCoord), "Reference shard is not part of forcefield");

    uint128 addedShards = 0;

    for (int32 x = fromShardCoord.x(); x <= toShardCoord.x(); x++) {
      for (int32 y = fromShardCoord.y(); y <= toShardCoord.y(); y++) {
        for (int32 z = fromShardCoord.z(); z <= toShardCoord.z(); z++) {
          Vec3 shardCoord = vec3(x, y, z);
          if (isForceFieldShard(forceFieldEntityId, shardCoord)) {
            continue;
          }
          EntityId shardEntityId = setupForceFieldShard(forceFieldEntityId, shardCoord);
          addedShards++;
        }
      }
    }

    // Increase drain rate per new shard
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + MACHINE_ENERGY_DRAIN_RATE * addedShards);

    // TODO: notifications
    // notify(
    //   playerEntityId,
    //   ExpandForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId, shardEntityId: shardEntityId })
    // );
    //
    // callChipOrRevert(
    //   forceFieldEntityId.getChipAddress(),
    //   abi.encodeCall(IForceFieldChip.onExpand, (playerEntityId, forceFieldEntityId, shardEntityId))
    // );
  }

  /**
   * @notice Contract a forcefield by removing shards within a specified cuboid
   * @param forceFieldEntityId The forcefield entity ID
   * @param fromShardCoord The starting coordinate of the cuboid to remove
   * @param toShardCoord The ending coordinate of the cuboid to remove
   * @param parents Indicates the parent of each boundary shard in the spanning tree, parents must be ordered (each parent comes before its children)
   */
  function contractForceField(
    EntityId forceFieldEntityId,
    Vec3 fromShardCoord,
    Vec3 toShardCoord,
    uint256[] memory parents
  ) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, forceFieldEntityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");

    // Decrease drain rate
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);

    uint128 removedShards = 0;
    require(fromShardCoord <= toShardCoord, "Invalid coordinates");

    // First, identify all boundary shards (shards adjacent to the cuboid to be removed)
    Vec3[] memory boundaryShards = computeBoundaryShards(forceFieldEntityId, fromShardCoord, toShardCoord);
    require(boundaryShards.length > 0, "No boundary shards found");

    // Validate that boundaryShards are connected
    require(validateSpanningTree(boundaryShards, parents), "Invalid spanning tree");

    // Now we can safely remove the shards
    for (int32 x = fromShardCoord.x(); x <= toShardCoord.x(); x++) {
      for (int32 y = fromShardCoord.y(); y <= toShardCoord.y(); y++) {
        for (int32 z = fromShardCoord.z(); z <= toShardCoord.z(); z++) {
          Vec3 shardCoord = vec3(x, y, z);
          // Only count if the shard exists
          if (isForceFieldShard(forceFieldEntityId, shardCoord)) {
            removeForceFieldShard(shardCoord);
            removedShards++;
          }
        }
      }
    }

    // Update drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate - MACHINE_ENERGY_DRAIN_RATE * removedShards);

    // TODO: notifications
    // Notify the player
    // notify(
    //   playerEntityId,
    //   ContractForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId, shardEntityId: shardEntityId })
    // );
    //
    // // Call the chip if it exists
    // callChipOrRevert(
    //   forceFieldEntityId.getChipAddress(),
    //   abi.encodeCall(IForceFieldChip.onContract, (playerEntityId, forceFieldEntityId, shardEntityId))
    // );
  }
}
