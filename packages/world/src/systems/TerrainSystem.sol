// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ChunkCoord } from "../Types.sol";
import { ExploredChunk } from "../codegen/tables/ExploredChunk.sol";
import { SSTORE2 } from "../utils/SSTORE2.sol";

import { TerrainLib } from "./libraries/TerrainLib.sol";

contract TerrainSystem is System {
  function exploreChunk(ChunkCoord memory chunkCoord, bytes memory chunkData, bytes32[] memory merkleProof) public {
    require(ExploredChunk.get(chunkCoord.x, chunkCoord.y, chunkCoord.z) == address(0), "Chunk already explored");
    // TODO: verify merkle proof
    SSTORE2.writeDeterministic(chunkData, TerrainLib._getChunkSalt(chunkCoord));
    ExploredChunk.set(chunkCoord.x, chunkCoord.y, chunkCoord.z, _msgSender());
  }
}
