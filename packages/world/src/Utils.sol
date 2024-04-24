// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IGravitySystem } from "./codegen/world/IGravitySystem.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { ReversePosition } from "./codegen/tables/ReversePosition.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { LastKnownPosition, LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";

import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "./Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "./Constants.sol";
import { getTerrainObjectTypeId } from "./utils/TerrainUtils.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";
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

function callGravity(bytes32 playerEntityId, VoxelCoord memory playerCoord) returns (bool) {
  bytes memory callData = abi.encodeCall(IGravitySystem.runGravity, (playerEntityId, playerCoord));
  bytes memory returnData = callInternalSystem(callData);
  return abi.decode(returnData, (bool));
}

function gravityApplies(bytes32 playerEntityId, VoxelCoord memory playerCoord) returns (bool) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
  if (belowEntityId == bytes32(0)) {
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(belowCoord);
    if (terrainObjectTypeId != AirObjectID && terrainObjectTypeId != WaterObjectID) {
      return false;
    }
  } else if (ObjectType._get(belowEntityId) != AirObjectID) {
    return false;
  }

  return true;
}
