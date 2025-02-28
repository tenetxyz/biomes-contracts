// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { TerrainLib, VERSION_PADDING } from "../src/systems/libraries/TerrainLib.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { ChunkCoord } from "../src/Types.sol";
import { CHUNK_SIZE } from "../src/Constants.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract TerrainTest is MudTest, GasReporter {
  using VoxelCoordLib for VoxelCoord;

  function testGetChunkCoord() public {
    VoxelCoord memory coord = VoxelCoord(1, 2, 2);
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord.x, 0);
    assertEq(chunkCoord.y, 0);
    assertEq(chunkCoord.z, 0);

    coord = VoxelCoord(16, 17, 18);
    chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord.x, 1);
    assertEq(chunkCoord.y, 1);
    assertEq(chunkCoord.z, 1);

    coord = VoxelCoord(-1, -2, -3);
    chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord.x, -1);
    assertEq(chunkCoord.y, -1);
    assertEq(chunkCoord.z, -1);

    coord = VoxelCoord(16, -17, -18);
    chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord.x, 1);
    assertEq(chunkCoord.y, -2);
    assertEq(chunkCoord.z, -2);
  }

  function testGetRelativeCoord() public {
    VoxelCoord memory coord = VoxelCoord(1, 2, 2);
    VoxelCoord memory relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 1);
    assertEq(relativeCoord.y, 2);
    assertEq(relativeCoord.z, 2);

    coord = VoxelCoord(16, 17, 18);
    relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 0);
    assertEq(relativeCoord.y, 1);
    assertEq(relativeCoord.z, 2);

    coord = VoxelCoord(-1, -2, -3);
    relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 15);
    assertEq(relativeCoord.y, 14);
    assertEq(relativeCoord.z, 13);

    coord = VoxelCoord(16, -17, -18);
    relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 0);
    assertEq(relativeCoord.y, 15);
    assertEq(relativeCoord.z, 14);
  }

  function testGetBlockIndex() public {
    VoxelCoord memory coord = VoxelCoord(1, 2, 2);
    uint256 index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 1 * 256 + 2 * 16 + 2 + VERSION_PADDING);

    coord = VoxelCoord(16, 17, 18);
    index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 1 * 16 + 2 + VERSION_PADDING);

    coord = VoxelCoord(-1, -2, -3);
    index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 15 * 256 + 14 * 16 + 13 + VERSION_PADDING);

    coord = VoxelCoord(16, -17, -18);
    index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 15 * 16 + 14 + VERSION_PADDING);
  }

  function testGetChunkSalt() public {
    ChunkCoord memory chunkCoord = ChunkCoord(1, 2, 3);
    bytes32 salt = TerrainLib._getChunkSalt(chunkCoord);
    assertEq(salt, bytes32(abi.encodePacked(bytes20(0), chunkCoord.x, chunkCoord.y, chunkCoord.z)));
    assertEq(salt, bytes32(uint256(uint96(bytes12(abi.encodePacked(chunkCoord.x, chunkCoord.y, chunkCoord.z))))));

    chunkCoord = ChunkCoord(-1, -2, -3);
    salt = TerrainLib._getChunkSalt(chunkCoord);
    assertEq(salt, bytes32(abi.encodePacked(bytes20(0), chunkCoord.x, chunkCoord.y, chunkCoord.z)));
    assertEq(salt, bytes32(uint256(uint96(bytes12(abi.encodePacked(chunkCoord.x, chunkCoord.y, chunkCoord.z))))));
  }

  function _getTestChunk() internal pure returns (uint8[][][] memory chunk) {
    chunk = new uint8[][][](uint256(int256(CHUNK_SIZE)));
    for (uint256 x = 0; x < uint256(int256(CHUNK_SIZE)); x++) {
      chunk[x] = new uint8[][](uint256(int256(CHUNK_SIZE)));
      for (uint256 y = 0; y < uint256(int256(CHUNK_SIZE)); y++) {
        chunk[x][y] = new uint8[](uint256(int256(CHUNK_SIZE)));
        for (uint256 z = 0; z < uint256(int256(CHUNK_SIZE)); z++) {
          chunk[x][y][z] = uint8(bytes1(keccak256(abi.encode(x, y, z)))); // random value between 0 and 255
        }
      }
    }
  }

  function testExploreChunk() public {
    uint8[][][] memory chunk = _getTestChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = ChunkCoord(0, 0, 0);
    bytes32[] memory merkleProof = new bytes32[](0);

    startGasReport("TerrainLib.exploreChunk");
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, merkleProof);
    endGasReport();

    VoxelCoord memory voxelCoord = VoxelCoord(1, 2, 3);
    startGasReport("TerrainLib.getBlockType (non-root)");
    uint8 blockType = TerrainLib.getBlockType(voxelCoord);
    endGasReport();

    startGasReport("TerrainLib.getBlockType (root)");
    blockType = TerrainLib.getBlockType(voxelCoord, worldAddress);
    endGasReport();

    assertEq(blockType, chunk[1][2][3]);

    for (int32 x = 0; x < CHUNK_SIZE; x++) {
      for (int32 y = 0; y < CHUNK_SIZE; y++) {
        for (int32 z = 0; z < CHUNK_SIZE; z++) {
          voxelCoord = VoxelCoord(int32(x), int32(y), int32(z));
          blockType = TerrainLib.getBlockType(voxelCoord);
          assertEq(blockType, chunk[uint256(int256(x))][uint256(int256(y))][uint256(int256(z))]);
        }
      }
    }
  }

  function testExploreChunk_Fail_ChunkAlreadyExplored() public {
    uint8[][][] memory chunk = _getTestChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = ChunkCoord(0, 0, 0);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));

    vm.expectRevert("Chunk already explored");
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
  }

  function testGetBlockType() public {
    uint8[][][] memory chunk = _getTestChunk();
    bytes memory encodedChunk = encodeChunk(chunk);

    // Test we can get the block type for a voxel in the chunk
    ChunkCoord memory chunkCoord = ChunkCoord(0, 0, 0);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
    VoxelCoord memory voxelCoord = VoxelCoord(1, 2, 3);
    uint8 blockType = TerrainLib.getBlockType(voxelCoord);
    assertEq(blockType, chunk[1][2][3]);

    // Test for chunks that are not at the origin
    chunkCoord = ChunkCoord(1, 2, 3);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
    voxelCoord = VoxelCoord(16 + 1, 16 * 2 + 2, 16 * 3 + 3);
    blockType = TerrainLib.getBlockType(voxelCoord);
    assertEq(blockType, chunk[1][2][3]);

    // Test for negative coordinates
    chunkCoord = ChunkCoord(-1, -2, -3);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
    voxelCoord = VoxelCoord(-16 + 1, -16 * 2 + 2, -16 * 3 + 3);
    blockType = TerrainLib.getBlockType(voxelCoord);
    assertEq(blockType, chunk[1][2][3]);
  }

  /// forge-config: default.allow_internal_expect_revert = true
  function testGetBlockType_Fail_ChunkNotExplored() public {
    vm.expectRevert("Chunk not explored yet");
    TerrainLib.getBlockType(VoxelCoord(0, 0, 0));
  }
}
