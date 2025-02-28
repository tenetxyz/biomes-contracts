// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { VoxelCoord, VoxelCoordLib } from "../../VoxelCoord.sol";
import { ChunkCoord } from "../../Types.sol";
import { SSTORE2 } from "../../utils/SSTORE2.sol";
import { CHUNK_SIZE } from "../../Constants.sol";
import { floorDiv, mod } from "../../utils/MathUtils.sol";

uint256 constant VERSION_PADDING = 1;

library TerrainLib {
  using SSTORE2 for address;
  using VoxelCoordLib for VoxelCoord;
  bytes1 constant _VERSION = 0x00;

  /// @notice Get the terrain block type of a voxel coordinate.
  /// @dev Assumes to be called from a root system.
  function _getBlockType(VoxelCoord memory coord) public view returns (uint8) {
    return getBlockType(coord, address(this));
  }

  /// @notice Get the terrain block type of a voxel coordinate.
  /// @dev Can be called from either a root or non-root system, but consumes slightly more gas.
  function getBlockType(VoxelCoord memory coord) internal view returns (uint8) {
    return getBlockType(coord, WorldContextConsumerLib._world());
  }

  /// @notice Get the terrain block type of a voxel coordinate.
  function getBlockType(VoxelCoord memory coord, address world) internal view returns (uint8) {
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    require(_isChunkExplored(chunkCoord, world), "Chunk not explored yet");

    address chunkPointer = _getChunkPointer(chunkCoord, world);
    bytes1 version = chunkPointer.readBytes1(0);
    require(version == _VERSION, "Unsupported chunk encoding version");

    uint256 index = _getBlockIndex(coord);
    bytes1 blockType = chunkPointer.readBytes1(index);

    return uint8(blockType);
  }

  /// @dev Get the relative coordinate of a voxel coordinate within a chunk
  function _getRelativeCoord(VoxelCoord memory coord) internal pure returns (VoxelCoord memory) {
    return
      VoxelCoord({
        x: int32(uint32(mod(coord.x, CHUNK_SIZE))),
        y: int32(uint32(mod(coord.y, CHUNK_SIZE))),
        z: int32(uint32(mod(coord.z, CHUNK_SIZE)))
      });
  }

  /// @dev Get the index of a voxel coordinate within the encoded chunk
  function _getBlockIndex(VoxelCoord memory coord) internal pure returns (uint256) {
    VoxelCoord memory relativeCoord = _getRelativeCoord(coord);
    return
      VERSION_PADDING +
      uint256(
        int256(relativeCoord.x) * CHUNK_SIZE ** 2 + int256(relativeCoord.y) * CHUNK_SIZE + int256(relativeCoord.z)
      );
  }

  /// @dev Get the salt for a chunk coordinate
  function _getChunkSalt(ChunkCoord memory coord) internal pure returns (bytes32) {
    // TODO: check if this is correct, we seem to be getting revert for collisions
    return bytes32((uint256(uint32(coord.x)) << 64) | (uint256(uint32(coord.y)) << 32) | uint256(uint32(coord.z)));
  }

  /// @dev Get the address of the chunk pointer based on its deterministic CREATE3 address
  function _getChunkPointer(ChunkCoord memory coord, address world) internal pure returns (address) {
    return SSTORE2.predictDeterministicAddress(_getChunkSalt(coord), world);
  }

  /// @dev Returns true if the chunk pointer contains data, else false
  function _isChunkExplored(ChunkCoord memory coord, address world) internal view returns (bool isDefined) {
    address chunkPointer = _getChunkPointer(coord, world);
    assembly {
      isDefined := gt(extcodesize(chunkPointer), 0)
    }
  }
}
