// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Terrain } from "../../codegen/tables/Terrain.sol";

contract AdminTerrainSystem is System {
  function setTerrainObjectTypeIds(VoxelCoord[] memory coord, uint8[] memory objectTypeId) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    for (uint i = 0; i < coord.length; i++) {
      Terrain._set(coord[i].x, coord[i].y, coord[i].z, objectTypeId[i]);
    }
  }

  function setTerrainObjectTypeIds(VoxelCoord[] memory coord, uint8 objectTypeId) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    for (uint i = 0; i < coord.length; i++) {
      Terrain._set(coord[i].x, coord[i].y, coord[i].z, objectTypeId);
    }
  }

  function setTerrainObjectTypeIds(
    VoxelCoord memory lowerSouthwestCorner,
    VoxelCoord memory size,
    uint8 objectTypeId
  ) public {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    for (int16 x = 0; x < size.x; x++) {
      for (int16 y = 0; y < size.y; y++) {
        for (int16 z = 0; z < size.z; z++) {
          VoxelCoord memory coord = VoxelCoord(
            lowerSouthwestCorner.x + x,
            lowerSouthwestCorner.y + y,
            lowerSouthwestCorner.z + z
          );
          Terrain._set(coord.x, coord.y, coord.z, objectTypeId);
        }
      }
    }
  }
}
