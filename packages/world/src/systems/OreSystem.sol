// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { TotalMinedOreCount } from "../codegen/tables/TotalMinedOreCount.sol";
import { MinedOrePosition, MinedOrePositionData } from "../codegen/tables/MinedOrePosition.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
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
import { COMMIT_EXPIRY_BLOCKS, COMMIT_HALF_WIDTH } from "../Constants.sol";

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

    require(inSurroundingCube(playerChunkCoord, COMMIT_HALF_WIDTH, chunkCoord), "Not in commit range");

    // Check existing commitment
    uint256 blockNumber = OreCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    require(blockNumber < block.number - COMMIT_EXPIRY_BLOCKS, "Existing ore commitment");

    // Commit to next block
    OreCommitment._set(chunkCoord.x, chunkCoord.y, chunkCoord.z, block.number + 1);
  }

  function respawnOre(uint256 blockNumber) public {
    // TODO: use constant
    require(blockNumber > block.number - 10, "Can only choose past 10 blocks");

    uint256 count = TotalMinedOreCount._get();
    require(count > 0, "No ores available for respawn");

    uint256 minedOreIdx = uint256(blockhash(blockNumber)) % count;

    VoxelCoord memory oreCoord = MinedOrePosition._get(minedOreIdx).toVoxelCoord();

    // Remove from mined ore array
    MinedOrePositionData memory last = MinedOrePosition._get(count - 1);
    MinedOrePosition._set(minedOreIdx, last);
    TotalMinedOreCount._set(count - 1);

    // Check existing entity
    EntityId entityId = ReversePosition._get(oreCoord.x, oreCoord.y, oreCoord.z);
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == AirObjectID, "Ore coordinate is not air");
    require(InventoryObjects._lengthObjectTypeIds(entityId) == 0, "Cannot respawn where there are dropped objects");

    // This is enough to respawn the ore block, as it will be read from the original terrain next time
    ObjectType._deleteRecord(entityId);
    Position._deleteRecord(entityId);
    ReversePosition._deleteRecord(oreCoord.x, oreCoord.y, oreCoord.z);
  }
}
