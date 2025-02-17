// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";
import { OreCommitment } from "../codegen/tables/OreCommitment.sol";
import { Commitment } from "../codegen/tables/Commitment.sol";
import { BlockPrevrandao } from "../codegen/tables/BlockPrevrandao.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID, LavaObjectID, CoalOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getRandomNumberBetween0And99 } from "../Utils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, InitiateOreRevealNotifData, RevealOreNotifData } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";
import { EntityId } from "../EntityId.sol";
import { ChunkCoord } from "../Types.sol";

contract OreSystem is System {
  using VoxelCoordLib for *;

  // TODO: extract to utils?
  // TODO: replace with actual implementation
  function inCommitRange(ChunkCoord memory self, ChunkCoord memory other) internal pure returns (bool) {
    return true;
  }

  function oreChunkCommit(ChunkCoord memory chunkCoord) public {
    // TODO: check chunk is inside world / revealed
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    ChunkCoord memory playerChunkCoord = playerCoord.toChunkCoord();
    require(inCommitRange(playerChunkCoord, chunkCoord), "Not in commit range");
    uint256 blockNum = OreCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
    require(blockNum < block.number - 256, "Existing Terrain commitment");
    OreCommitment._set(chunkCoord.x, chunkCoord.y, chunkCoord.z, block.number + 1);
  }

  function respawnOre(uint256 revealedOreIdx, VoxelCoord memory oreCoord) public {}
}
