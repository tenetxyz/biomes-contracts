// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../codegen/world/IWorld.sol";

import { SystemSwitch } from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";
import { ITerrainSystem } from "../codegen/world/ITerrainSystem.sol";
import { ITerrainOreSystem } from "../codegen/world/ITerrainOreSystem.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID } from "../ObjectTypeIds.sol";

contract TerrainHelperSystem is System {
  //////////////////////////////////////////////////////////////////////////////////////
  // Get Terrain
  //////////////////////////////////////////////////////////////////////////////////////

  function getTerrainBlock(VoxelCoord memory coord) public returns (bytes32) {
    bytes32 objectTypeId;

    objectTypeId = abi.decode(SystemSwitch.call(abi.encodeCall(ITerrainSystem.Trees, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(SystemSwitch.call(abi.encodeCall(ITerrainSystem.Flora, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(SystemSwitch.call(abi.encodeCall(ITerrainOreSystem.Ores, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(SystemSwitch.call(abi.encodeCall(ITerrainSystem.TerrainBlocks, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    objectTypeId = abi.decode(SystemSwitch.call(abi.encodeCall(ITerrainSystem.Air, (coord))), (bytes32));
    if (objectTypeId != bytes32(0)) return objectTypeId;

    return AirObjectID;
  }
}
