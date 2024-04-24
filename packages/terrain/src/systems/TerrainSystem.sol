// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { Terrain } from "../codegen/tables/Terrain.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { IProcGenSystem } from "../codegen/world/IProcGenSystem.sol";
import { NullObjectTypeId, AirObjectID } from "../ObjectTypeIds.sol";

import { staticCallInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

contract TerrainSystem is System {
  function getCachedTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    return Terrain.get(coord.x, coord.y, coord.z);
  }

  function getTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    uint8 cachedObjectTypeId = Terrain.get(coord.x, coord.y, coord.z);
    if (cachedObjectTypeId != 0) return cachedObjectTypeId;
    return computeTerrainObjectTypeId(coord);
  }

  function getTerrainObjectTypeIdWithCacheSet(VoxelCoord memory coord) public returns (uint8) {
    uint8 cachedObjectTypeId = Terrain.get(coord.x, coord.y, coord.z);
    if (cachedObjectTypeId != NullObjectTypeId) return cachedObjectTypeId;
    uint8 objectTypeId = computeTerrainObjectTypeId(coord);
    Terrain.set(coord.x, coord.y, coord.z, objectTypeId);
    return objectTypeId;
  }

  function computeTerrainObjectTypeId(VoxelCoord memory coord) public view returns (uint8) {
    return abi.decode(staticCallInternalSystem(abi.encodeCall(IProcGenSystem.getTerrainBlock, (coord))), (uint8));
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
          Terrain.set(coord.x, coord.y, coord.z, computeTerrainObjectTypeId(coord));
        }
      }
    }
  }
}
