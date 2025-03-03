// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Vec3 } from "../Vec3.sol";
import { ExploredChunkCount } from "../codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex, ExploredChunk } from "../utils/Vec3Storage.sol";
import { SSTORE2 } from "../utils/SSTORE2.sol";

import { TerrainLib } from "./libraries/TerrainLib.sol";

contract TerrainSystem is System {
  function exploreChunk(Vec3 chunkCoord, bytes memory chunkData, bytes32[] memory merkleProof) public {
    require(ExploredChunk._get(chunkCoord) == address(0), "Chunk already explored");
    // TODO: verify merkle proof
    SSTORE2.writeDeterministic(chunkData, TerrainLib._getChunkSalt(chunkCoord));

    ExploredChunk.set(chunkCoord, _msgSender());
    uint256 exploredChunkCount = ExploredChunkCount._get();
    ExploredChunkByIndex.set(exploredChunkCount, chunkCoord);
    ExploredChunkCount._set(exploredChunkCount + 1);
  }
}
