// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Terrain } from "../../codegen/tables/Terrain.sol";

import { NullObjectTypeId } from "../../ObjectTypeIds.sol";
import { staticCallProcGenSystem } from "../../Utils.sol";

contract TerrainSystem is System {
  function getCachedTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    return Terrain._get(coord.x, coord.y, coord.z);
  }

  function getTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    uint8 cachedObjectTypeId = Terrain._get(coord.x, coord.y, coord.z);
    if (cachedObjectTypeId != 0) return cachedObjectTypeId;
    return staticCallProcGenSystem(coord);
  }

  function getTerrainObjectTypeIdWithCacheSet(VoxelCoord memory coord) public returns (uint8) {
    uint8 cachedObjectTypeId = Terrain._get(coord.x, coord.y, coord.z);
    if (cachedObjectTypeId != NullObjectTypeId) return cachedObjectTypeId;
    uint8 objectTypeId = staticCallProcGenSystem(coord);
    Terrain._set(coord.x, coord.y, coord.z, objectTypeId);
    return objectTypeId;
  }

  function fillTerrainCache(VoxelCoord memory coord) public returns (uint8) {
    uint8 objectTypeId = staticCallProcGenSystem(coord);
    Terrain._set(coord.x, coord.y, coord.z, objectTypeId);
    return objectTypeId;
  }

  function fillTerrainCache(VoxelCoord[] memory coord) public {
    for (uint i = 0; i < coord.length; i++) {
      Terrain._set(coord[i].x, coord[i].y, coord[i].z, staticCallProcGenSystem(coord[i]));
    }
  }

  function fillTerrainCache(VoxelCoord memory lowerSouthwestCorner, VoxelCoord memory size) public {
    require(size.x > 0 && size.y > 0 && size.z > 0, "TerrainSystem: size must be positive");
    for (int16 x = 0; x < size.x; x++) {
      for (int16 y = 0; y < size.y; y++) {
        for (int16 z = 0; z < size.z; z++) {
          VoxelCoord memory coord = VoxelCoord(
            lowerSouthwestCorner.x + x,
            lowerSouthwestCorner.y + y,
            lowerSouthwestCorner.z + z
          );
          Terrain._set(coord.x, coord.y, coord.z, staticCallProcGenSystem(coord));
        }
      }
    }
  }
}
