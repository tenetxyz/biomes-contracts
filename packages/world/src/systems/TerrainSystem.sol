// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Terrain } from "../codegen/tables/Terrain.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { NullObjectTypeId, AirObjectID } from "../ObjectTypeIds.sol";
import { staticCallProcGenSystem, getUniqueEntity } from "../Utils.sol";

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

  function computeTerrainObjectTypeIdWithSet(VoxelCoord memory coord) public returns (uint8) {
    uint8 objectTypeId = staticCallProcGenSystem(coord);
    Terrain._set(coord.x, coord.y, coord.z, objectTypeId);
    return objectTypeId;
  }

  function fillTerrainCache(VoxelCoord memory lowerSouthWestCorner, VoxelCoord memory size) public {
    require(size.x > 0 && size.y > 0 && size.z > 0, "TerrainSystem: size must be positive");
    for (int16 x = 0; x < size.x; x++) {
      for (int16 y = 0; y < size.y; y++) {
        for (int16 z = 0; z < size.z; z++) {
          VoxelCoord memory coord = VoxelCoord(
            lowerSouthWestCorner.x + x,
            lowerSouthWestCorner.y + y,
            lowerSouthWestCorner.z + z
          );
          Terrain._set(coord.x, coord.y, coord.z, staticCallProcGenSystem(coord));
        }
      }
    }
  }

  function fillObjectTypeWithComputedTerrainCache(VoxelCoord memory coord) public {
    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId != bytes32(0)) {
      return;
    }
    entityId = getUniqueEntity();
    ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    Position._set(entityId, coord.x, coord.y, coord.z);

    uint8 objectTypeId = computeTerrainObjectTypeIdWithSet(coord);
    ObjectType._set(entityId, objectTypeId);
  }

  function fillObjectTypeWithComputedTerrainCache(
    VoxelCoord memory lowerSouthWestCorner,
    VoxelCoord memory size
  ) public {
    require(size.x > 0 && size.y > 0 && size.z > 0, "TerrainSystem: size must be positive");
    for (int16 x = 0; x < size.x; x++) {
      for (int16 y = 0; y < size.y; y++) {
        for (int16 z = 0; z < size.z; z++) {
          VoxelCoord memory coord = VoxelCoord(
            lowerSouthWestCorner.x + x,
            lowerSouthWestCorner.y + y,
            lowerSouthWestCorner.z + z
          );
          fillObjectTypeWithComputedTerrainCache(coord);
        }
      }
    }
  }

  function fillObjectTypeTerrainCache(VoxelCoord memory lowerSouthWestCorner, VoxelCoord memory size) public {
    require(size.x > 0 && size.y > 0 && size.z > 0, "TerrainSystem: size must be positive");
    for (int16 x = 0; x < size.x; x++) {
      for (int16 y = 0; y < size.y; y++) {
        for (int16 z = 0; z < size.z; z++) {
          VoxelCoord memory coord = VoxelCoord(
            lowerSouthWestCorner.x + x,
            lowerSouthWestCorner.y + y,
            lowerSouthWestCorner.z + z
          );
          bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
          if (entityId != bytes32(0)) {
            continue;
          }
          uint8 cachedObjectTypeId = Terrain._get(coord.x, coord.y, coord.z);
          if (cachedObjectTypeId == NullObjectTypeId) {
            continue;
          }

          entityId = getUniqueEntity();
          ReversePosition._set(coord.x, coord.y, coord.z, entityId);
          Position._set(entityId, coord.x, coord.y, coord.z);
          ObjectType._set(entityId, cachedObjectTypeId);
        }
      }
    }
  }
}
