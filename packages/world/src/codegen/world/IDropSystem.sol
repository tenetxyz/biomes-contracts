// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { VoxelCoord } from "../../Types.sol";

/**
 * @title IDropSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IDropSystem {
  function drop(uint16 dropObjectTypeId, uint16 numToDrop, VoxelCoord memory coord) external;

  function dropTool(bytes32 toolEntityId, VoxelCoord memory coord) external;

  function dropTools(bytes32[] memory toolEntityIds, VoxelCoord memory coord) external;
}
