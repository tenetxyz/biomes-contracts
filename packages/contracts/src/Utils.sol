// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ITerrainSystem } from "./codegen/world/ITerrainSystem.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function getTerrainObjectTypeId(bytes32 objectTypeId, VoxelCoord memory coord) view returns (bytes32) {
  address terrainAddress = ObjectTypeMetadata.getOccurenceAddress(objectTypeId);
  bytes4 terrainSelector = ObjectTypeMetadata.getOccurenceSelector(objectTypeId);
  // require(terrainAddress != address(0) && terrainSelector != bytes4(0), "ObjectTypeMetadata: object type not found");
  (bool success, bytes memory returnData) = terrainAddress.staticcall(abi.encodeWithSelector(terrainSelector, coord));
  require(success, "getTerrainObjectTypeId: call failed");
  return abi.decode(returnData, (bytes32));
}
