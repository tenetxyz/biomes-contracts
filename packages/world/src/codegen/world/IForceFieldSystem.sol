// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { VoxelCoord } from "../../Types.sol";

/**
 * @title IForceFieldSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IForceFieldSystem {
  function requireBuildsAllowed(
    bytes32 playerEntityId,
    bytes32 baseEntityId,
    uint16 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) external payable;

  function requireMinesAllowed(
    bytes32 playerEntityId,
    bytes32 baseEntityId,
    uint16 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) external payable;
}
