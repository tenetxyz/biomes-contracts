// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BiomesTest } from "./BiomesTest.sol";

import { TerrainLib, VERSION_PADDING } from "../src/systems/libraries/TerrainLib.sol";
import { ObjectTypes.Air } from "../src/ObjectTypeIds.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { CHUNK_SIZE } from "../src/Constants.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract TerrainTest is BiomesTest {
  function testGetChunkCoord() public {
    Vec3 coord = vec3(1, 2, 2);
    Vec3 chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord, vec3(0, 0, 0));

    coord = vec3(16, 17, 18);
    chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord, vec3(1, 1, 1));

    coord = vec3(-1, -2, -3);
    chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord, vec3(-1, -1, -1));

    coord = vec3(16, -17, -18);
    chunkCoord = coord.toChunkCoord();
    assertEq(chunkCoord, vec3(1, -2, -2));
  }

  function testGetRelativeCoord() public {
    Vec3 coord = vec3(1, 2, 2);
    Vec3 relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord, vec3(1, 2, 2));

    coord = vec3(16, 17, 18);
    relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord, vec3(0, 1, 2));

    coord = vec3(-1, -2, -3);
    relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord, vec3(15, 14, 13));

    coord = vec3(16, -17, -18);
    relativeCoord = TerrainLib._getRelativeCoord(coord);
    assertEq(relativeCoord, vec3(0, 15, 14));
  }

  function testGetBlockIndex() public {
    Vec3 coord = vec3(1, 2, 2);
    uint256 index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 1 * 256 + 2 * 16 + 2 + VERSION_PADDING);

    coord = vec3(16, 17, 18);
    index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 1 * 16 + 2 + VERSION_PADDING);

    coord = vec3(-1, -2, -3);
    index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 15 * 256 + 14 * 16 + 13 + VERSION_PADDING);

    coord = vec3(16, -17, -18);
    index = TerrainLib._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 15 * 16 + 14 + VERSION_PADDING);
  }

  function testGetChunkSalt() public {
    Vec3 chunkCoord = vec3(1, 2, 3);
    bytes32 salt = TerrainLib._getChunkSalt(chunkCoord);
    assertEq(salt, bytes32(abi.encodePacked(bytes20(0), chunkCoord)));
    assertEq(salt, bytes32(uint256(uint96(bytes12(abi.encodePacked(chunkCoord))))));

    chunkCoord = vec3(-1, -2, -3);
    salt = TerrainLib._getChunkSalt(chunkCoord);
    assertEq(salt, bytes32(abi.encodePacked(bytes20(0), chunkCoord)));
    assertEq(salt, bytes32(uint256(uint96(bytes12(abi.encodePacked(chunkCoord))))));
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
    Vec3 chunkCoord = vec3(0, 0, 0);
    bytes32[] memory merkleProof = new bytes32[](0);

    startGasReport("TerrainLib.exploreChunk");
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, merkleProof);
    endGasReport();

    Vec3 coord = vec3(1, 2, 3);
    startGasReport("TerrainLib.getBlockType (non-root)");
    uint8 blockType = TerrainLib.getBlockType(coord);
    endGasReport();

    startGasReport("TerrainLib.getBlockType (root)");
    blockType = TerrainLib.getBlockType(coord, worldAddress);
    endGasReport();

    assertEq(blockType, chunk[1][2][3]);

    for (int32 x = 0; x < CHUNK_SIZE; x++) {
      for (int32 y = 0; y < CHUNK_SIZE; y++) {
        for (int32 z = 0; z < CHUNK_SIZE; z++) {
          coord = vec3(x, y, z);
          blockType = TerrainLib.getBlockType(coord);
          assertEq(blockType, chunk[uint256(int256(x))][uint256(int256(y))][uint256(int256(z))]);
        }
      }
    }
  }

  function testExploreChunk_Fail_ChunkAlreadyExplored() public {
    uint8[][][] memory chunk = _getTestChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    Vec3 chunkCoord = vec3(0, 0, 0);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));

    vm.expectRevert("Chunk already explored");
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
  }

  function testGetBlockType() public {
    uint8[][][] memory chunk = _getTestChunk();
    bytes memory encodedChunk = encodeChunk(chunk);

    // Test we can get the block type for a voxel in the chunk
    Vec3 chunkCoord = vec3(0, 0, 0);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
    Vec3 coord = vec3(1, 2, 3);
    uint8 blockType = TerrainLib.getBlockType(coord);
    assertEq(blockType, chunk[1][2][3]);

    // Test for chunks that are not at the origin
    chunkCoord = vec3(1, 2, 3);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
    coord = vec3(16 + 1, 16 * 2 + 2, 16 * 3 + 3);
    blockType = TerrainLib.getBlockType(coord);
    assertEq(blockType, chunk[1][2][3]);

    // Test for negative coordinates
    chunkCoord = vec3(-1, -2, -3);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk, new bytes32[](0));
    coord = vec3(-16 + 1, -16 * 2 + 2, -16 * 3 + 3);
    blockType = TerrainLib.getBlockType(coord);
    assertEq(blockType, chunk[1][2][3]);
  }

  /// forge-config: default.allow_internal_expect_revert = true
  function testGetBlockType_Fail_ChunkNotExplored() public {
    vm.expectRevert("Chunk not explored yet");
    TerrainLib.getBlockType(vec3(0, 0, 0));
  }
}
