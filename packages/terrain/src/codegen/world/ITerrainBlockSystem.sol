// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

/**
 * @title ITerrainBlockSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITerrainBlockSystem {
  function getTerrainBlock(VoxelCoord memory coord) external view returns (uint8);

  function Trees(VoxelCoord memory coord) external view returns (uint8);

  function Flora(VoxelCoord memory coord) external view returns (uint8);

  function TerrainBlocks(VoxelCoord memory coord) external view returns (uint8);
}