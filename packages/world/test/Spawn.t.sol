// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";

import { TerrainLib, VERSION_PADDING } from "../src/systems/libraries/TerrainLib.sol";
import { AirObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord, ChunkCoord } from "../src/Types.sol";
import { CHUNK_SIZE } from "../src/Constants.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract SpawnTest is MudTest, GasReporter {
  IWorld private world;

  function setUp() public override {
    super.setUp();

    world = IWorld(worldAddress);
  }

  function testRandomSpawnFailsDueToOldBlock() public {
    uint256 pastBlock = block.number - 11;
    int32 y = 1;
    vm.expectRevert("Can only choose past 10 blocks");
    world.randomSpawn(pastBlock, y);
  }
}
