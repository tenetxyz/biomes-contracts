// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { Build, BuildWithPos } from "./../../utils/BuildUtils.sol";

/**
 * @title IBuildsSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IBuildsSystem {
  function experience__setBuild(bytes32 buildId, string memory name, Build memory build) external;

  function experience__deleteBuild(bytes32 buildId) external;

  function experience__setBuildWithPos(bytes32 buildId, string memory name, BuildWithPos memory build) external;

  function experience__deleteBuildWithPos(bytes32 buildId) external;
}
