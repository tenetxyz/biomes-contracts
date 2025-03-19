// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Program } from "../codegen/tables/Program.sol";

import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getUniqueEntity } from "../Utils.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { notify, ExpandForceFieldNotifData, ContractForceFieldNotifData } from "../utils/NotifUtils.sol";
import { isForceFieldFragment, isForceFieldFragmentActive, setupForceFieldFragment, removeForceFieldFragment } from "../utils/ForceFieldUtils.sol";
import { ForceFieldFragment } from "../utils/Vec3Storage.sol";

import { IForceFieldProgram } from "../prototypes/IForceFieldProgram.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract ForceFieldSystem is System {
  /**
   * @notice Validates that the boundary fragments form a connected component using a spanning tree
   * @param boundaryFragments Array of boundary fragment coordinates
   * @param len Number of boundaryFragments
   * @param parents Array indicating the parent of each fragment in the spanning tree
   * @return True if the spanning tree is valid and connects all boundary fragments
   */
  function validateSpanningTree(
    Vec3[] memory boundaryFragments,
    uint256 len,
    uint256[] calldata parents
  ) public pure returns (bool) {
    // If no boundary, it means no forcefield exists
    if (len == 0) return false;
    if (len == 1) return parents.length == 1 && parents[0] == 0;

    // Validate parents array
    if (parents.length != len || parents[0] != 0) return false;

    // Track visited nodes
    bool[] memory visited = new bool[](len);
    visited[0] = true; // Mark root as visited
    uint256 visitedCount = 1;

    // Validate each node's parent relationship
    for (uint256 i = 1; i < len; i++) {
      uint256 parent = parents[i];

      // Parent must be in valid range, already visited and adjacent
      if (
        parent >= len || !visited[parent] || !boundaryFragments[parent].inVonNeumannNeighborhood(boundaryFragments[i])
      ) {
        return false;
      }

      // Mark as visited
      visited[i] = true;
      visitedCount++;
    }

    return visitedCount == len;
  }

  /**
   * @notice Identify all boundary fragments of a forcefield that are adjacent to a cuboid
   * @param forceFieldEntityId The forcefield entity ID
   * @param fromFragmentCoord The starting coordinate of the cuboid
   * @param toFragmentCoord The ending coordinate of the cuboid
   * @return An array of boundary fragment coordinates and its length (the array can be longer)
   */
  function computeBoundaryFragments(
    EntityId forceFieldEntityId,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord
  ) public view returns (Vec3[] memory, uint256) {
    uint256 maxSize;
    {
      (int256 dx, int256 dy, int256 dz) = (toFragmentCoord - fromFragmentCoord).xyz();
      uint256 innerVolume = uint256(dx + 1) * uint256(dy + 1) * uint256(dz + 1);
      uint256 outerVolume = uint256(dx + 3) * uint256(dy + 3) * uint256(dz + 3);
      maxSize = outerVolume - innerVolume;
    }

    Vec3 expandedFrom = fromFragmentCoord - vec3(1, 1, 1);
    Vec3 expandedTo = toFragmentCoord + vec3(1, 1, 1);

    Vec3[] memory tempBoundary = new Vec3[](maxSize);
    uint256 count = 0;

    // Iterate through the entire expanded cuboid
    for (int32 x = expandedFrom.x(); x <= expandedTo.x(); x++) {
      for (int32 y = expandedFrom.y(); y <= expandedTo.y(); y++) {
        for (int32 z = expandedFrom.z(); z <= expandedTo.z(); z++) {
          Vec3 currentPos = vec3(x, y, z);

          // Skip if the coordinate is inside the original cuboid
          if (fromFragmentCoord <= currentPos && currentPos <= toFragmentCoord) {
            continue;
          }

          // Add to boundary if it's a forcefield fragment
          if (isForceFieldFragment(forceFieldEntityId, currentPos)) {
            tempBoundary[count] = currentPos;
            count++;
          }
        }
      }
    }

    return (tempBoundary, count);
  }

  function expandForceField(
    EntityId forceFieldEntityId,
    Vec3 refFragmentCoord,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord,
    bytes calldata extraData
  ) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());
    PlayerUtils.requireInPlayerInfluence(playerCoord, forceFieldEntityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");
    (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);

    require(fromFragmentCoord <= toFragmentCoord, "Invalid coordinates");

    require(
      refFragmentCoord.isAdjacentToCuboid(fromFragmentCoord, toFragmentCoord),
      "Reference fragment is not adjacent to new fragments"
    );

    require(isForceFieldFragment(forceFieldEntityId, refFragmentCoord), "Reference fragment is not part of forcefield");

    uint128 addedFragments = 0;

    for (int32 x = fromFragmentCoord.x(); x <= toFragmentCoord.x(); x++) {
      for (int32 y = fromFragmentCoord.y(); y <= toFragmentCoord.y(); y++) {
        for (int32 z = fromFragmentCoord.z(); z <= toFragmentCoord.z(); z++) {
          Vec3 fragmentCoord = vec3(x, y, z);
          // TODO: optimize, these three functions are retrieving the shard's data
          // If already belongs to the forcefield, skip it
          if (isForceFieldFragment(forceFieldEntityId, fragmentCoord)) {
            continue;
          }

          require(!isForceFieldFragmentActive(fragmentCoord), "Can't expand to existing forcefield");
          setupForceFieldFragment(forceFieldEntityId, fragmentCoord);
          addedFragments++;
        }
      }
    }

    // Increase drain rate per new fragment
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + MACHINE_ENERGY_DRAIN_RATE * addedFragments);

    notify(playerEntityId, ExpandForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId }));

    callProgramOrRevert(
      forceFieldEntityId.getProgram(),
      abi.encodeCall(
        IForceFieldProgram.onExpand,
        (playerEntityId, forceFieldEntityId, fromFragmentCoord, toFragmentCoord, extraData)
      )
    );
  }

  /**
   * @notice Contract a forcefield by removing fragments within a specified cuboid
   * @param forceFieldEntityId The forcefield entity ID
   * @param fromFragmentCoord The starting coordinate of the cuboid to remove
   * @param toFragmentCoord The ending coordinate of the cuboid to remove
   * @param parents Indicates the parent of each boundary fragment in the spanning tree, parents must be ordered (each parent comes before its children)
   */
  function contractForceField(
    EntityId forceFieldEntityId,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord,
    uint256[] calldata parents,
    bytes calldata extraData
  ) public {
    require(fromFragmentCoord <= toFragmentCoord, "Invalid coordinates");

    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());

    Vec3 forceFieldFragmentCoord;
    {
      Vec3 forceFieldCoord = PlayerUtils.requireInPlayerInfluence(playerCoord, forceFieldEntityId);
      forceFieldFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    }

    {
      ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
      require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");
    }

    {
      // First, identify all boundary fragments (fragments adjacent to the cuboid to be removed)
      (Vec3[] memory boundaryFragments, uint256 len) = computeBoundaryFragments(
        forceFieldEntityId,
        fromFragmentCoord,
        toFragmentCoord
      );
      require(len > 0, "No boundary fragments found");

      // Validate that boundaryFragments are connected
      require(validateSpanningTree(boundaryFragments, len, parents), "Invalid spanning tree");
    }

    {
      uint128 removedFragments = 0;
      // Now we can safely remove the fragments
      for (int32 x = fromFragmentCoord.x(); x <= toFragmentCoord.x(); x++) {
        for (int32 y = fromFragmentCoord.y(); y <= toFragmentCoord.y(); y++) {
          for (int32 z = fromFragmentCoord.z(); z <= toFragmentCoord.z(); z++) {
            Vec3 fragmentCoord = vec3(x, y, z);
            require(forceFieldFragmentCoord != fragmentCoord, "Can't remove forcefield's fragment");

            // Only remove if the fragment is part of the forcefield
            // TODO: optimize, both functions are retrieving the shard's data
            if (isForceFieldFragment(forceFieldEntityId, fragmentCoord)) {
              removeForceFieldFragment(fragmentCoord);
              removedFragments++;
            }
          }
        }
      }

      (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
      // Update drain rate
      Energy._setDrainRate(forceFieldEntityId, machineData.drainRate - MACHINE_ENERGY_DRAIN_RATE * removedFragments);
    }

    notify(playerEntityId, ContractForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId }));

    // Call the program if it exists
    callProgramOrRevert(
      forceFieldEntityId.getProgram(),
      abi.encodeCall(
        IForceFieldProgram.onContract,
        (playerEntityId, forceFieldEntityId, fromFragmentCoord, toFragmentCoord, extraData)
      )
    );
  }
}
