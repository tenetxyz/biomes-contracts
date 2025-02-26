// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { EntityId } from "../../EntityId.sol";
import { VoxelCoord } from "../../VoxelCoord.sol";

/**
 * @title IHitMachineSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IHitMachineSystem {
  function hitMachine(EntityId entityId) external;

  function hitForceField(VoxelCoord memory entityCoord) external;
}
