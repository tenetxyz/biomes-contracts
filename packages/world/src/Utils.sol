// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem, staticCallInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { ReversePosition } from "./codegen/tables/ReversePosition.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { Terrain } from "./codegen/tables/Terrain.sol";
import { UniqueEntity } from "./codegen/tables/UniqueEntity.sol";
import { Spawn, SpawnData } from "./codegen/tables/Spawn.sol";
import { LastKnownPosition, LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";

import { SPAWN_SHARD_DIM } from "./Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z, OP_L1_GAS_ORACLE } from "./Constants.sol";
import { AirObjectID, WaterObjectID } from "./ObjectTypeIds.sol";

import { IGravitySystem } from "./codegen/world/IGravitySystem.sol";
import { IProcGenSystem } from "./codegen/world/IProcGenSystem.sol";
import { IMintXPSystem } from "./codegen/world/IMintXPSystem.sol";

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

function inSpawnArea(VoxelCoord memory coord) view returns (bool) {
  VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(coord, SPAWN_SHARD_DIM);
  SpawnData memory spawnData = Spawn._get(shardCoord.x, shardCoord.z);
  if (!spawnData.initialized) {
    return false;
  }

  return
    coord.x >= spawnData.spawnLowX &&
    coord.x <= spawnData.spawnHighX &&
    coord.z >= spawnData.spawnLowZ &&
    coord.z <= spawnData.spawnHighZ;
}

function callGravity(bytes32 playerEntityId, VoxelCoord memory playerCoord) returns (bool) {
  bytes memory callData = abi.encodeCall(IGravitySystem.runGravity, (playerEntityId, playerCoord));
  bytes memory returnData = callInternalSystem(callData);
  return abi.decode(returnData, (bool));
}

function callMintXP(bytes32 playerEntityId, uint256 initialGas, uint256 multiplier) {
  callInternalSystem(abi.encodeCall(IMintXPSystem.mintXP, (playerEntityId, initialGas, multiplier)));
}

function gravityApplies(VoxelCoord memory playerCoord) view returns (bool, bytes32) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
  if (belowEntityId == bytes32(0)) {
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(belowCoord);
    if (terrainObjectTypeId != AirObjectID) {
      return (false, belowEntityId);
    }
  } else if (ObjectType._get(belowEntityId) != AirObjectID || getTerrainObjectTypeId(belowCoord) == WaterObjectID) {
    return (false, belowEntityId);
  }

  return (true, belowEntityId);
}

function getTerrainObjectTypeId(VoxelCoord memory coord) view returns (uint8) {
  uint8 cachedObjectTypeId = Terrain._get(coord.x, coord.y, coord.z);
  if (cachedObjectTypeId != 0) return cachedObjectTypeId;
  return staticCallProcGenSystem(coord);
}

function staticCallProcGenSystem(VoxelCoord memory coord) view returns (uint8) {
  return abi.decode(staticCallInternalSystem(abi.encodeCall(IProcGenSystem.getTerrainBlock, (coord))), (uint8));
}

function getUniqueEntity() returns (bytes32) {
  uint256 uniqueEntity = UniqueEntity._get() + 1;
  UniqueEntity._set(uniqueEntity);

  return bytes32(uniqueEntity);
}

// Safe as in do not block the chip tx
function safeCallChip(address chipAddress, bytes memory callData) {
  if (chipAddress == address(0)) {
    return;
  }
  (bool success, ) = chipAddress.call{ value: WorldContextConsumerLib._msgValue() }(callData);
  if (!success) {
    // Note: we want the TX to revert if the chip call runs out of gas, but because
    // this is the last call in the function, we need to consume some dummy gas for it to revert
    // See: https://github.com/dhvanipa/evm-outofgas-call
    for (uint256 i = 0; i < 1000; i++) {
      continue;
    }
  }
}

function getL1GasPrice() view returns (uint256) {
  uint256 l1GasPriceWei = 0;
  uint32 codeSize;
  assembly {
    codeSize := extcodesize(OP_L1_GAS_ORACLE)
  }
  if (codeSize == 0) {
    return l1GasPriceWei;
  }
  (bool oracleSuccess, bytes memory oracleReturnData) = OP_L1_GAS_ORACLE.staticcall(
    abi.encodeWithSignature("l1BaseFee()")
  );
  if (oracleSuccess) {
    l1GasPriceWei = abi.decode(oracleReturnData, (uint256));
  }
  return l1GasPriceWei;
}
