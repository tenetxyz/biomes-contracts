// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "./VoxelCoord.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";
import { Position, PositionData } from "./codegen/tables/Position.sol";
import { ReversePosition } from "./codegen/tables/ReversePosition.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { UniqueEntity } from "./codegen/tables/UniqueEntity.sol";
import { BlockHash } from "./codegen/tables/BlockHash.sol";
import { BlockPrevrandao } from "./codegen/tables/BlockPrevrandao.sol";
import { WorldStatus } from "./codegen/tables/WorldStatus.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "./Constants.sol";
import { ObjectTypeId, AirObjectID } from "./ObjectTypeIds.sol";
import { TerrainLib } from "./systems/libraries/TerrainLib.sol";

import { EntityId } from "./EntityId.sol";

function checkWorldStatus() view {
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

function gravityApplies(VoxelCoord memory playerCoord) view returns (bool) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  (EntityId belowEntityId, ObjectTypeId belowObjectTypeId) = belowCoord.getEntity();
  if (!ObjectTypeMetadata._getCanPassThrough(belowObjectTypeId)) {
    return false;
  }
  if (belowCoord.getPlayer().exists()) {
    return false;
  }

  return true;
}

function getUniqueEntity() returns (EntityId) {
  uint256 uniqueEntity = UniqueEntity._get() + 1;
  UniqueEntity._set(uniqueEntity);

  return EntityId.wrap(bytes32(uniqueEntity));
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
