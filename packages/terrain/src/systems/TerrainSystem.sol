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
import { ITerrainBlockSystem } from "../codegen/world/ITerrainBlockSystem.sol";
import { ITerrainOreSystem } from "../codegen/world/ITerrainOreSystem.sol";
import { NullObjectTypeId, AirObjectID } from "../ObjectTypeIds.sol";

import { staticCallInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

contract TerrainSystem is System {
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
    uint8 objectTypeId;

    objectTypeId = abi.decode(
      staticCallInternalSystem(abi.encodeCall(ITerrainBlockSystem.TerrainBlocks, (coord))),
      (uint8)
    );
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = abi.decode(staticCallInternalSystem(abi.encodeCall(ITerrainOreSystem.Ores, (coord))), (uint8));
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    objectTypeId = abi.decode(
      staticCallInternalSystem(abi.encodeCall(ITerrainBlockSystem.getTerrainBlock, (coord))),
      (uint8)
    );
    if (objectTypeId != NullObjectTypeId) return objectTypeId;

    return AirObjectID;
  }
}