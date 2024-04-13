// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IStore } from "@latticexyz/store/src/IStore.sol";
import { IGravitySystem } from "./codegen/world/IGravitySystem.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { WorldContextProviderLib, WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
import { Terrain } from "@biomesaw/terrain/src/codegen/tables/Terrain.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { LastKnownPosition, LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";

import { TERRAIN_WORLD_ADDRESS, SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "./Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "./Constants.sol";
import { AirObjectID } from "./ObjectTypeIds.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function lastKnownPositionDataToVoxelCoord(LastKnownPositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function inWorldBorder(VoxelCoord memory coord) pure returns (bool) {
  return
    coord.x >= WORLD_BORDER_LOW_X &&
    coord.x <= WORLD_BORDER_HIGH_X &&
    coord.y >= WORLD_BORDER_LOW_Y &&
    coord.y <= WORLD_BORDER_HIGH_Y &&
    coord.z >= WORLD_BORDER_LOW_Z &&
    coord.z <= WORLD_BORDER_HIGH_Z;
}

function inSpawnArea(VoxelCoord memory coord) pure returns (bool) {
  return coord.x >= SPAWN_LOW_X && coord.x <= SPAWN_HIGH_X && coord.z >= SPAWN_LOW_Z && coord.z <= SPAWN_HIGH_Z;
}

function getTerrainObjectTypeId(address worldAddress, VoxelCoord memory coord) view returns (bytes32) {
  bytes32 objectTypeId = Terrain.get(IStore(TERRAIN_WORLD_ADDRESS), worldAddress, coord.x, coord.y, coord.z);
  if (objectTypeId == bytes32(0)) {
    return AirObjectID;
  }
  return objectTypeId;
}

function callGravity(bytes32 playerEntityId, VoxelCoord memory coord) returns (bool) {
  bytes memory callData = abi.encodeCall(IGravitySystem.runGravity, (playerEntityId, coord));
  bytes memory returnData = callInternalSystem(callData);
  return abi.decode(returnData, (bool));
}

function callInternalSystem(bytes memory callData) returns (bytes memory) {
  (ResourceId systemId, bytes4 systemFunctionSelector) = FunctionSelectors._get(bytes4(callData));
  (address systemAddress, ) = Systems._get(systemId);

  (bool success, bytes memory returnData) = WorldContextProviderLib.delegatecallWithContext({
    msgSender: WorldContextConsumerLib._msgSender(),
    msgValue: 0,
    target: systemAddress,
    callData: Bytes.setBytes4(callData, 0, systemFunctionSelector)
  });

  if (!success) revertWithBytes(returnData);

  return returnData;
}
