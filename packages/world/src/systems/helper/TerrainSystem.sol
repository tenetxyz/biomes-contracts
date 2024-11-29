// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Terrain } from "../../codegen/tables/Terrain.sol";

import { NullObjectTypeId } from "../../ObjectTypeIds.sol";
import { staticCallProcGenSystem } from "../../Utils.sol";

contract TerrainSystem is System {
  function getCachedTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    revert("TerrainSystem: deprecated");
  }

  function getTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    (uint8 terrainObjectTypeId, ) = staticCallProcGenSystem(coord, 0);
    return terrainObjectTypeId;
  }

  function getTerrainObjectTypeIdWithCacheSet(VoxelCoord memory coord) public returns (uint8) {
    revert("TerrainSystem: deprecated");
  }

  function fillTerrainCache(VoxelCoord memory coord) public returns (uint8) {
    revert("TerrainSystem: deprecated");
  }

  function fillTerrainCache(VoxelCoord[] memory coord) public {
    revert("TerrainSystem: deprecated");
  }

  function fillTerrainCache(VoxelCoord memory lowerSouthwestCorner, VoxelCoord memory size) public {
    revert("TerrainSystem: deprecated");
  }
}
