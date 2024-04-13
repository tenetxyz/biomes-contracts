// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Terrain } from "../codegen/tables/Terrain.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

contract TerrainSystem is System {
  function setTerrainObjectTypeId(VoxelCoord memory coord, bytes32 objectTypeId) public {
    Terrain.set(_msgSender(), coord.x, coord.y, coord.z, objectTypeId);
  }

  function setTerrainObjectTypeIds(VoxelCoord[] memory coords, bytes32 objectTypeId) public {
    for (uint i = 0; i < coords.length; i++) {
      Terrain.set(_msgSender(), coords[i].x, coords[i].y, coords[i].z, objectTypeId);
    }
  }

  function setTerrainObjectTypeIds(VoxelCoord[] memory coords, bytes32[] memory objectTypeIds) public {
    for (uint i = 0; i < coords.length; i++) {
      Terrain.set(_msgSender(), coords[i].x, coords[i].y, coords[i].z, objectTypeIds[i]);
    }
  }

  function getTerrainObjectTypeId(address worldAddress, VoxelCoord memory coord) public view returns (bytes32) {
    return Terrain.get(worldAddress, coord.x, coord.y, coord.z);
  }
}
