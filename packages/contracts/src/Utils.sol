// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { SystemSwitch } from "@latticexyz/world-modules/src/utils/SystemSwitch.sol";
import { ITerrainSystem } from "./codegen/world/ITerrainSystem.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function getTerrainObjectTypeId(VoxelCoord memory coord) returns (bytes32) {
  return abi.decode(SystemSwitch.call(abi.encodeCall(ITerrainSystem.getTerrainBlock, (coord))), (bytes32));
}
