// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

/**
 * @title IAdminSpawnSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IAdminSpawnSystem {
  function setObjectAtCoord(uint8 objectTypeId, VoxelCoord memory coord) external;

  function setObjectAtCoord(uint8 objectTypeId, VoxelCoord[] memory coord) external;

  function setObjectAtCoord(uint8[] memory objectTypeId, VoxelCoord[] memory coord) external;
}
