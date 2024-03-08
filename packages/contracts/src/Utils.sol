// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { SystemSwitch } from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";
import { ITerrainSystem } from "./codegen/world/ITerrainSystem.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function getTerrainObjectTypeId(bytes32 objectTypeId, VoxelCoord memory coord) returns (bytes32) {
  bytes4 terrainSelector = ObjectTypeMetadata.getOccurence(objectTypeId);
  require(terrainSelector != bytes4(0), "ObjectTypeMetadata: object type not found");
  return abi.decode(SystemSwitch.call(abi.encodeWithSelector(terrainSelector, (coord))), (bytes32));
}
