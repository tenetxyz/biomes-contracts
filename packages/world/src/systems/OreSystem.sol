// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { TotalMinedOreCount } from "../codegen/tables/TotalMinedOreCount.sol";
import { MinedOrePosition, MinedOrePositionData } from "../codegen/tables/MinedOrePosition.sol";
import { TotalBurnedOreCount } from "../codegen/tables/TotalBurnedOreCount.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";
import { OreCommitment } from "../codegen/tables/OreCommitment.sol";

import { AirObjectID, PlayerObjectID, LavaObjectID, CoalOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder } from "../Utils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, InitiateOreRevealNotifData, RevealOreNotifData } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";
import { EntityId } from "../EntityId.sol";
import { ChunkCoord } from "../Types.sol";
import { CHUNK_COMMIT_EXPIRY_BLOCKS, CHUNK_COMMIT_HALF_WIDTH, RESPAWN_ORE_BLOCK_RANGE } from "../Constants.sol";

// TODO: copied from voxel coords. Figure out way to unify coordinate utils
function inSurroundingCube(
  ChunkCoord memory cubeCenter,
  int32 halfWidth,
  ChunkCoord memory checkCoord
) pure returns (bool) {
  bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
  bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
  bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

  return isInX && isInY && isInZ;
}

contract OreSystem is System {
  using VoxelCoordLib for *;

  function oreChunkCommit(ChunkCoord memory chunkCoord) public {
    require(TerrainLib._isChunkExplored(chunkCoord, _world()), "Unexplored chunk");
    (, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    ChunkCoord memory playerChunkCoord = playerCoord.toChunkCoord();

    require(inSurroundingCube(playerChunkCoord, CHUNK_COMMIT_HALF_WIDTH, chunkCoord), "Not in commit range");

    // Check existing commitment
    uint256 commitment = OreCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    require(block.number > commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Existing ore commitment");

    // Commit starting from next block
    OreCommitment._set(chunkCoord.x, chunkCoord.y, chunkCoord.z, block.number + 1);
  }

  function respawnOre(uint256 blockNumber) public {
    require(
      blockNumber < block.number && blockNumber >= block.number - RESPAWN_ORE_BLOCK_RANGE,
      "Can only choose past 10 blocks"
    );

    uint256 burned = TotalBurnedOreCount._get();
    require(burned > 0, "No ores available for respawn");

    uint256 mined = TotalMinedOreCount._get();
    uint256 minedOreIdx = uint256(blockhash(blockNumber)) % mined;

    VoxelCoord memory oreCoord = MinedOrePosition._get(minedOreIdx).toVoxelCoord();

    // Check existing entity
    EntityId entityId = ReversePosition._get(oreCoord.x, oreCoord.y, oreCoord.z);
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == AirObjectID, "Ore coordinate is not air");
    require(InventoryObjects._lengthObjectTypeIds(entityId) == 0, "Cannot respawn where there are dropped objects");

    // Remove from mined ore array
    if (minedOreIdx < mined) {
      MinedOrePositionData memory last = MinedOrePosition._get(mined - 1);
      MinedOrePosition._set(minedOreIdx, last);
    }
    MinedOrePosition._deleteRecord(mined - 1);

    // Update total amounts
    TotalBurnedOreCount._set(burned - 1);
    TotalMinedOreCount._set(mined - 1);

    // This is enough to respawn the ore block, as it will be read from the original terrain next time
    ObjectType._deleteRecord(entityId);
    Position._deleteRecord(entityId);
    ReversePosition._deleteRecord(oreCoord.x, oreCoord.y, oreCoord.z);
  }
}
