// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { MinedOreCount } from "../codegen/tables/MinedOreCount.sol";
import { MinedOre, MinedOreData } from "../codegen/tables/MinedOre.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";
import { OreCommitment } from "../codegen/tables/OreCommitment.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID, LavaObjectID, CoalOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder } from "../Utils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, InitiateOreRevealNotifData, RevealOreNotifData } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";
import { EntityId } from "../EntityId.sol";
import { ChunkCoord } from "../Types.sol";
import { COMMIT_EXPIRY_BLOCKS, COMMIT_HALF_WIDTH } from "../Constants.sol";

contract OreSystem is System {
  using VoxelCoordLib for *;

  // TODO: copied from voxel coords. Figure out way to unify coordinate utils
  function inSurroundingCube(
    ChunkCoord memory cubeCenter,
    int32 halfWidth,
    ChunkCoord memory checkCoord
  ) internal pure returns (bool) {
    bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
    bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
    bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

    return isInX && isInY && isInZ;
  }

  function oreChunkCommit(ChunkCoord memory chunkCoord) public {
    // TODO: check chunk is inside world / revealed
    require(TerrainLib._isChunkExplored(chunkCoord, _world()));
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    (, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    ChunkCoord memory playerChunkCoord = playerCoord.toChunkCoord();

    require(inSurroundingCube(playerChunkCoord, COMMIT_HALF_WIDTH, chunkCoord), "Not in commit range");

    // Check existing commitment
    uint256 blockNumber = OreCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    require(blockNumber < block.number - COMMIT_EXPIRY_BLOCKS, "Existing Terrain commitment");

    // Commit to next block
    OreCommitment._set(chunkCoord.x, chunkCoord.y, chunkCoord.z, block.number + 1);
  }

  function respawnOre(uint256 blockNumber) public {
    uint256 count = MinedOreCount._get();
    // TODO: use constant
    require(blockNumber < block.number - 10, "Can only choose past 10 blocks");
    // TODO: I don't think it should hash _msgSender in this case as you could automate mining accounts that spawn blocks next to you
    uint256 minedOreIdx = uint256(blockhash(blockNumber)) % count;

    // Check that coord and index match
    VoxelCoord memory oreCoord = MinedOre._get(minedOreIdx).toVoxelCoord();

    // Remove from mined ore array
    MinedOreData memory last = MinedOre._get(count - 1);
    MinedOre._set(minedOreIdx, last);
    MinedOreCount._set(count - 1);

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
