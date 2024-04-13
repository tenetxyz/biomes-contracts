// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Terrain } from "../codegen/tables/Terrain.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

contract TerrainSystem is System {
  function setTerrainObjectTypeId(VoxelCoord memory coord, bytes32 objectTypeId) public {
    Terrain.set(_msgSender(), coord.x, coord.y, coord.z, objectTypeId);
  }

  function getTerrainObjectTypeId(address worldAddress, VoxelCoord memory coord) public view returns (bytes32) {
    return Terrain.get(worldAddress, coord.x, coord.y, coord.z);
  }
}
