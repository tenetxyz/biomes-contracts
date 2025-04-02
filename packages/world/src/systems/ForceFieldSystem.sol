// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ActionType } from "../codegen/common.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { getUniqueEntity } from "../Utils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";

import {
  isForceFieldFragment,
  isForceFieldFragmentActive,
  removeForceFieldFragment,
  setupForceFieldFragment
} from "../utils/ForceFieldUtils.sol";
import { AddFragmentNotification, RemoveFragmentNotification, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { ForceFieldFragment, Position } from "../utils/Vec3Storage.sol";

import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { IAddFragmentHook, IRemoveFragmentHook } from "../ProgramInterfaces.sol";
import { Vec3, vec3 } from "../Vec3.sol";

contract ForceFieldSystem is System {
  /**
   * @notice Validates that the boundary fragments form a connected component using a spanning tree
   * @param boundaryFragments Array of boundary fragment coordinates
   * @param len Number of boundaryFragments
   * @param parents Array indicating the parent of each fragment in the spanning tree
   * @return True if the spanning tree is valid and connects all boundary fragments
   */
  function validateSpanningTree(Vec3[26] memory boundaryFragments, uint256 len, uint256[] calldata parents)
    public
    pure
    returns (bool)
  {
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
   * @notice Identify all boundary fragments of a forcefield that are adjacent to a fragment
   * @param forceField The forcefield entity ID
   * @param fragmentCoord The coordinate of the fragment
   * @return An array of boundary fragment coordinates and its length (the array can be longer)
   */
  function computeBoundaryFragments(EntityId forceField, Vec3 fragmentCoord)
    public
    view
    returns (Vec3[26] memory, uint256)
  {
    uint256 count = 0;

    // Iterate through the entire boundary
    Vec3[26] memory boundary;
    Vec3[26] memory neighbors = fragmentCoord.neighbors26();
    for (uint8 i = 0; i < neighbors.length; i++) {
      // Add to resulting boundary if it's a forcefield fragment
      if (isForceFieldFragment(forceField, neighbors[i])) {
        boundary[count++] = neighbors[i];
      }
    }

    return (boundary, count);
  }

  function addFragment(
    EntityId caller,
    EntityId forceField,
    Vec3 refFragmentCoord,
    Vec3 fragmentCoord,
    bytes calldata extraData
  ) public {
    caller.activate();
    // caller.requireConnected(forceField);

    ObjectTypeId objectTypeId = ObjectType._get(forceField);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");
    (EnergyData memory machineData,) = updateMachineEnergy(forceField);

    require(
      refFragmentCoord.inVonNeumannNeighborhood(fragmentCoord), "Reference fragment is not adjacent to new fragment"
    );

    require(isForceFieldFragment(forceField, refFragmentCoord), "Reference fragment is not part of forcefield");
    require(!isForceFieldFragmentActive(fragmentCoord), "Fragment already belongs to a forcefield");
    EntityId fragment = setupForceFieldFragment(forceField, fragmentCoord);

    // Increase drain rate per new fragment
    Energy._setDrainRate(forceField, machineData.drainRate + MACHINE_ENERGY_DRAIN_RATE);

    bytes memory onAddFragment =
      abi.encodeCall(IAddFragmentHook.onAddFragment, (caller, forceField, fragment, extraData));

    forceField.getProgram().callOrRevert(onAddFragment);

    notify(caller, AddFragmentNotification({ forceField: forceField }));
  }

  /**
   * @notice Removes a fragment from a forcefield
   * @param forceField The forcefield entity ID
   * @param fragmentCoord The coordinate of the fragment
   * @param parents Indicates the parent of each boundary fragment in the spanning tree, parents must be ordered (each parent comes before its children)
   */
  function removeFragment(
    EntityId caller,
    EntityId forceField,
    Vec3 fragmentCoord,
    uint256[] calldata parents,
    bytes calldata extraData
  ) public {
    caller.activate();

    Vec3 forceFieldFragmentCoord;
    forceFieldFragmentCoord = Position._get(forceField).toForceFieldFragmentCoord();

    ObjectTypeId objectTypeId = ObjectType._get(forceField);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");

    require(forceFieldFragmentCoord != fragmentCoord, "Can't remove forcefield's fragment");
    require(isForceFieldFragment(forceField, fragmentCoord), "Fragment is not part of forcefield");

    // First, identify all boundary fragments (fragments adjacent to the fragment to be removed)
    (Vec3[26] memory boundary, uint256 len) = computeBoundaryFragments(forceField, fragmentCoord);

    require(len > 0, "No boundary fragments found");

    // Validate that boundaryFragments are connected
    require(validateSpanningTree(boundary, len, parents), "Invalid spanning tree");

    EntityId fragment = removeForceFieldFragment(fragmentCoord);

    (EnergyData memory machineData,) = updateMachineEnergy(forceField);

    // Update drain rate
    Energy._setDrainRate(forceField, machineData.drainRate - MACHINE_ENERGY_DRAIN_RATE);

    {
      bytes memory onRemoveFragment =
        abi.encodeCall(IRemoveFragmentHook.onRemoveFragment, (caller, forceField, fragment, extraData));
      forceField.getProgram().callOrRevert(onRemoveFragment);
    }

    notify(caller, RemoveFragmentNotification({ forceField: forceField }));
  }
}
