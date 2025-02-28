// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ChunkCoord } from "../../Types.sol";

/**
 * @title IOreSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IOreSystem {
  function oreChunkCommit(ChunkCoord memory chunkCoord) external;

  function respawnOre(uint256 blockNumber) external;
}
