// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "./Types.sol";
import { coordToShardCoordIgnoreY } from "./utils/VoxelCoordUtils.sol";
import { callInternalSystem, staticCallInternalSystem } from "./utils/CallUtils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { Position, PositionData } from "./codegen/tables/Position.sol";
import { ReversePosition } from "./codegen/tables/ReversePosition.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { UniqueEntity } from "./codegen/tables/UniqueEntity.sol";
import { Spawn, SpawnData } from "./codegen/tables/Spawn.sol";
import { LastKnownPosition, LastKnownPositionData } from "./codegen/tables/LastKnownPosition.sol";
import { BlockHash } from "./codegen/tables/BlockHash.sol";
import { BlockPrevrandao } from "./codegen/tables/BlockPrevrandao.sol";
import { WorldStatus } from "./codegen/tables/WorldStatus.sol";
import { SPAWN_SHARD_DIM } from "./Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "./Constants.sol";
import { AirObjectID, WaterObjectID } from "./ObjectTypeIds.sol";

import { IGravitySystem } from "./codegen/world/IGravitySystem.sol";

import { EntityId } from "./EntityId.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function lastKnownPositionDataToVoxelCoord(LastKnownPositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function checkWorldStatus() {
  require(!WorldStatus._getInMaintenance(), "Biomes is in maintenance mode. Try again later");
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

function callGravity(EntityId playerEntityId, VoxelCoord memory playerCoord) returns (bool) {
  bytes memory callData = abi.encodeCall(IGravitySystem.runGravity, (playerEntityId, playerCoord));
  bytes memory returnData = callInternalSystem(callData, 0);
  return abi.decode(returnData, (bool));
}

function gravityApplies(VoxelCoord memory playerCoord) view returns (bool) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  EntityId belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
  require(belowEntityId.exists(), "Attempted to apply gravity but encountered an unrevealed block");
  uint16 belowObjectTypeId = ObjectType._get(belowEntityId);
  if (belowObjectTypeId != AirObjectID && belowObjectTypeId != WaterObjectID) {
    return false;
  }

  return true;
}

function getUniqueEntity() returns (EntityId) {
  uint256 uniqueEntity = UniqueEntity._get() + 1;
  UniqueEntity._set(uniqueEntity);

  return EntityId.wrap(bytes32(uniqueEntity));
}

// Safe as in do not block the chip tx
function safeCallChip(address chipAddress, bytes memory callData) {
  if (chipAddress == address(0)) {
    return;
  }
  // TODO: pass in a fixed amount of gas
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

// Random number between 0 and 99
function getRandomNumberBetween0And99(uint256 blockNumber) view returns (uint256) {
  bytes32 blockHash = blockhash(blockNumber);
  if (blockHash == bytes32(0)) {
    blockHash = BlockHash._get(blockNumber);
  }
  require(
    blockHash != bytes32(0),
    string.concat("getRandomNumber: block hash is missing for block ", Strings.toString(blockNumber))
  );

  uint256 blockPrevrandao = BlockPrevrandao._get(blockNumber);

  // Use the block hash and prevrandao to generate a random number by converting it to uint256 and applying modulo
  uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockHash, blockPrevrandao))) % 100;

  return randomNumber;
}
