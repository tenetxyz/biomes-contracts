// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

/**
 * @title ISpawnSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ISpawnSystem {
  function spawnPlayer(VoxelCoord memory spawnCoord) external returns (bytes32);

  function initSpawnAreaTop() external;

  function initSpawnAreaTopPart2() external;

  function initSpawnAreaBottom() external;

  function initSpawnAreaBottomPart2() external;

  function initSpawnAreaBottomBorder() external;
}