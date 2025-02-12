// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";

import { Terrain } from "../src/terrain/Terrain.sol";
import { AirObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord } from "../src/Types.sol";

contract TerrainTest is Test {
  Terrain terrain;

  function setUp() public {
    terrain = new Terrain();
  }

  function testTerrain() public {
    VoxelCoord memory coord = VoxelCoord(0, 0, 0);
    uint16 blockType = terrain.getBlockType(coord);
    assertEq(blockType, AirObjectID);
  }
}
