// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";

import { Terrain } from "../src/systems/TerrainSystem.sol";
import { AirObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord, ChunkCoord } from "../src/Types.sol";

contract TerrainTest is Test {
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
    assertEq(index, 1 * 256 + 2 * 16 + 2);

    coord = VoxelCoord(16, 17, 18);
    index = Terrain._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 1 * 16 + 2);

    coord = VoxelCoord(-1, -2, -3);
    index = Terrain._getBlockIndex(coord);
    assertEq(index, 15 * 256 + 14 * 16 + 13);

    coord = VoxelCoord(16, -17, -18);
    index = Terrain._getBlockIndex(coord);
    assertEq(index, 0 * 256 + 15 * 16 + 14);
  }
}
