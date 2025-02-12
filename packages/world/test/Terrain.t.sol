// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { Terrain, VERSION_PADDING } from "../src/systems/TerrainSystem.sol";
import { AirObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord, ChunkCoord } from "../src/Types.sol";
import { CHUNK_SIZE } from "../src/Constants.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract TerrainTest is MudTest, GasReporter {
  function testGetChunkCoord() public {
    VoxelCoord memory coord = VoxelCoord(1, 2, 2);
    ChunkCoord memory chunkCoord = Terrain._getChunkCoord(coord);
    assertEq(chunkCoord.x, 0);
    assertEq(chunkCoord.y, 0);
    assertEq(chunkCoord.z, 0);

    coord = VoxelCoord(16, 17, 18);
    chunkCoord = Terrain._getChunkCoord(coord);
    assertEq(chunkCoord.x, 1);
    assertEq(chunkCoord.y, 1);
    assertEq(chunkCoord.z, 1);

    coord = VoxelCoord(-1, -2, -3);
    chunkCoord = Terrain._getChunkCoord(coord);
    assertEq(chunkCoord.x, -1);
    assertEq(chunkCoord.y, -1);
    assertEq(chunkCoord.z, -1);

    coord = VoxelCoord(16, -17, -18);
    chunkCoord = Terrain._getChunkCoord(coord);
    assertEq(chunkCoord.x, 1);
    assertEq(chunkCoord.y, -2);
    assertEq(chunkCoord.z, -2);
  }

  function testGetRelativeCoord() public {
    VoxelCoord memory coord = VoxelCoord(1, 2, 2);
    VoxelCoord memory relativeCoord = Terrain._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 1);
    assertEq(relativeCoord.y, 2);
    assertEq(relativeCoord.z, 2);

    coord = VoxelCoord(16, 17, 18);
    relativeCoord = Terrain._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 0);
    assertEq(relativeCoord.y, 1);
    assertEq(relativeCoord.z, 2);

    coord = VoxelCoord(-1, -2, -3);
    relativeCoord = Terrain._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 15);
    assertEq(relativeCoord.y, 14);
    assertEq(relativeCoord.z, 13);

    coord = VoxelCoord(16, -17, -18);
    relativeCoord = Terrain._getRelativeCoord(coord);
    assertEq(relativeCoord.x, 0);
    assertEq(relativeCoord.y, 15);
    assertEq(relativeCoord.z, 14);
  }

  function testGetBlockIndex() public {
    VoxelCoord memory coord = VoxelCoord(1, 2, 2);
    uint256 index = Terrain._getBlockIndex(coord);
    assertEq(index, 1 * 256 + 2 * 16 + 2 + VERSION_PADDING);

    coord = VoxelCoord(16, 17, 18);
    index = Terrain._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 1 * 16 + 2 + VERSION_PADDING);

    coord = VoxelCoord(-1, -2, -3);
    index = Terrain._getBlockIndex(coord);
    assertEq(index, 15 * 256 + 14 * 16 + 13 + VERSION_PADDING);

    coord = VoxelCoord(16, -17, -18);
    index = Terrain._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 15 * 16 + 14 + VERSION_PADDING);
  }

  function testEncodeChunk() public {
    uint8[][][] memory chunk = new uint8[][][](uint256(int256(CHUNK_SIZE)));
    for (uint256 x = 0; x < uint256(int256(CHUNK_SIZE)); x++) {
      chunk[x] = new uint8[][](uint256(int256(CHUNK_SIZE)));
      for (uint256 y = 0; y < uint256(int256(CHUNK_SIZE)); y++) {
        chunk[x][y] = new uint8[](uint256(int256(CHUNK_SIZE)));
        for (uint256 z = 0; z < uint256(int256(CHUNK_SIZE)); z++) {
          chunk[x][y][z] = uint8(bytes1(keccak256(abi.encode(x, y, z)))); // random value between 0 and 255
        }
      }
    }
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = ChunkCoord(0, 0, 0);
    IWorld(worldAddress).exploreChunk(chunkCoord, encodedChunk);

    VoxelCoord memory voxelCoord = VoxelCoord(1, 2, 3);
    startGasReport("Terrain.getBlockType");
    uint8 blockType = Terrain.getBlockType(voxelCoord);
    endGasReport();

    assertEq(blockType, chunk[1][2][3]);

    for (int32 x = 0; x < CHUNK_SIZE; x++) {
      for (int32 y = 0; y < CHUNK_SIZE; y++) {
        for (int32 z = 0; z < CHUNK_SIZE; z++) {
          voxelCoord = VoxelCoord(int32(x), int32(y), int32(z));
          blockType = Terrain.getBlockType(voxelCoord);
          assertEq(blockType, chunk[uint256(int256(x))][uint256(int256(y))][uint256(int256(z))]);
        }
      }
    }
  }
}
