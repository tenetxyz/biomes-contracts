// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { ITerrainSystem } from "@biomesaw/terrain/src/codegen/world/ITerrainSystem.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { NullObjectTypeId } from "@biomesaw/terrain/src/ObjectTypeIds.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { TERRAIN_WORLD_ADDRESS } from "../Constants.sol";

contract UtilsSystem is System {
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
          bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
          if (entityId != bytes32(0)) {
            continue;
          }
          entityId = getUniqueEntity();
          ReversePosition._set(coord.x, coord.y, coord.z, entityId);
          Position._set(entityId, coord.x, coord.y, coord.z);

          uint8 objectTypeId = ITerrainSystem(TERRAIN_WORLD_ADDRESS).computeTerrainObjectTypeIdWithSet(coord);
          ObjectType._set(entityId, objectTypeId);
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
          uint8 cachedObjectTypeId = Terrain.get(IStore(TERRAIN_WORLD_ADDRESS), coord.x, coord.y, coord.z);
          if (cachedObjectTypeId == NullObjectTypeId) {
            continue;
          }

          entityId = getUniqueEntity();
          ReversePosition._set(coord.x, coord.y, coord.z, entityId);
          Position._set(entityId, coord.x, coord.y, coord.z);
          ObjectType._set(entityId, objectTypeId);
        }
      }
    }
  }
}
