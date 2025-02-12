// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, ChunkCoord } from "../Types.sol";
import { AirObjectID } from "../ObjectTypeIds.sol";
import { ExploredChunk } from "../codegen/tables/ExploredChunk.sol";
import { SSTORE2 } from "../utils/SSTORE2.sol";
import { CHUNK_SIZE } from "../Constants.sol";
import { floorDiv, mod } from "../utils/MathUtils.sol";

contract TerrainSystem is System {
  // TODO: attach merkle proof to the chunk data
  function exploreChunk(VoxelCoord memory chunkCoord, bytes calldata chunkData) public {
    require(ExploredChunk.get(chunkCoord.x, chunkCoord.y, chunkCoord.z) == address(0), "Chunk already explored");
    address pointer = SSTORE2.write(chunkData);
    ExploredChunk.set(chunkCoord.x, chunkCoord.y, chunkCoord.z, pointer);
  }
}

library Terrain {
  using SSTORE2 for address;

  function getBlockType(VoxelCoord memory coord) internal view returns (uint8) {
    uint256 index = _getBlockIndex(coord);
    ChunkCoord memory chunkCoord = _getChunkCoord(coord);
    address chunkPointer = ExploredChunk.get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    bytes1 blockType = chunkPointer.readBytes1(index);
    return uint8(blockType);
  }

  // Get the chunk coordinate of a voxel coordinate
  function _getChunkCoord(VoxelCoord memory chunkCoord) internal pure returns (ChunkCoord memory) {
    return
      ChunkCoord({
        x: floorDiv(chunkCoord.x, CHUNK_SIZE),
        y: floorDiv(chunkCoord.y, CHUNK_SIZE),
        z: floorDiv(chunkCoord.z, CHUNK_SIZE)
      });
  }

  // Get the index within the chunk of a voxel coordinate
  function _getBlockIndex(VoxelCoord memory coord) internal pure returns (uint256) {
    return
      (mod(coord.x, CHUNK_SIZE) * uint256(uint32(CHUNK_SIZE)) ** 2) +
      (mod(coord.y, CHUNK_SIZE) * uint256(uint32(CHUNK_SIZE))) +
      mod(coord.z, CHUNK_SIZE);
  }
}
