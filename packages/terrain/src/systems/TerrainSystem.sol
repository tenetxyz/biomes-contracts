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
import { AirObjectID } from "../ObjectTypeIds.sol";

import { staticCallInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

contract TerrainSystem is System {
  function setTerrainObjectTypeId(VoxelCoord memory coord) public {
    Terrain.set(_msgSender(), coord.x, coord.y, coord.z, computeTerrainObjectTypeId(coord));
  }

  function setTerrainObjectTypeIds(VoxelCoord[] memory coord) public {
    for (uint i = 0; i < coord.length; i++) {
      setTerrainObjectTypeId(coord[i]);
    }
  }

  function setTerrainObjectTypeId() public {
    // Set an area of 1000 x 500 x 1000
    for (int32 x = -1000; x < 0; x++) {
      for (int32 z = -1000; z < 0; z++) {
        for (int32 y = -150; y < 250; y++) {
          setTerrainObjectTypeId(VoxelCoord(x, y, z));
        }
      }
    }
  }

  function getTerrainObjectTypeId(address worldAddress, VoxelCoord memory coord) public view returns (bytes32) {
    return Terrain.get(worldAddress, coord.x, coord.y, coord.z);
  }

  function computeTerrainObjectTypeId(VoxelCoord memory coord) public view returns (bytes32) {
    bytes32 objectTypeId;

    objectTypeId = abi.decode(staticCallInternalSystem(abi.encodeCall(ITerrainBlockSystem.Trees, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(staticCallInternalSystem(abi.encodeCall(ITerrainBlockSystem.Flora, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(staticCallInternalSystem(abi.encodeCall(ITerrainOreSystem.Ores, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(
      staticCallInternalSystem(abi.encodeCall(ITerrainBlockSystem.TerrainBlocks, (coord))),
      (bytes32)
    );
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(staticCallInternalSystem(abi.encodeCall(ITerrainBlockSystem.Air, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    return AirObjectID;
  }
}
