// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Vec3 } from "../Vec3.sol";
import { SurfaceChunkCount } from "../codegen/tables/SurfaceChunkCount.sol";
import { SurfaceChunkByIndex, ExploredChunk } from "../utils/Vec3Storage.sol";
import { SSTORE2 } from "../utils/SSTORE2.sol";

import { TerrainLib } from "./libraries/TerrainLib.sol";

contract TerrainSystem is System {
  function exploreChunk(Vec3 chunkCoord, bytes memory chunkData, bytes32[] memory merkleProof) public {
    require(ExploredChunk._get(chunkCoord) == address(0), "Chunk already explored");
    // TODO: verify merkle proof
    SSTORE2.writeDeterministic(chunkData, TerrainLib._getChunkSalt(chunkCoord));

    ExploredChunk.set(chunkCoord, _msgSender());
    // TODO: we don't need to store the surface byte in the chunk's bytecode
    if (TerrainLib._isSurfaceChunk(chunkCoord)) {
      uint256 surfaceChunkCount = SurfaceChunkCount._get();
      SurfaceChunkByIndex.set(surfaceChunkCount, chunkCoord);
      SurfaceChunkCount._set(surfaceChunkCount + 1);
    }
  }
}
