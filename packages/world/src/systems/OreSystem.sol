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
import { TerrainCommitment, TerrainCommitmentData } from "../codegen/tables/TerrainCommitment.sol";
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
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    ChunkCoord memory playerChunkCoord = playerCoord.toChunkCoord();
    require(inCommitRange(playerChunkCoord, chunkCoord), "Not in commit range");
    uint256 blockNum = TerrainCommitment._get(chunkCoord.x, chunkCoord.y, chunkCoord.z);
  }

  function initiateOreReveal(VoxelCoord memory coord) public {
    require(inWorldBorder(coord), "Cannot reveal ore outside world border");

    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);
    if (TerrainCommitment._getBlockNumber(coord.x, coord.y, coord.z) != 0) {
      revealOre(coord);
      return;
    }

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(!entityId.exists(), "Ore already revealed");
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(coord));
    require(mineObjectTypeId == AnyOreObjectID, "Terrain is not an ore");

    TerrainCommitment._set(coord.x, coord.y, coord.z, block.number, playerEntityId);
    Commitment._set(playerEntityId, true, coord.x, coord.y, coord.z);
    BlockPrevrandao._set(block.number, block.prevrandao);

    notify(playerEntityId, InitiateOreRevealNotifData({ oreCoord: coord }));
  }

  // Can be called by anyone
  function revealOre(VoxelCoord memory coord) public returns (ObjectTypeId) {
    TerrainCommitmentData memory terrainCommitmentData = TerrainCommitment._get(coord.x, coord.y, coord.z);
    require(terrainCommitmentData.blockNumber != 0, "Terrain commitment not found");

    uint256 randomNumber = getRandomNumberBetween0And99(terrainCommitmentData.blockNumber);

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(!entityId.exists(), "Ore already revealed");

    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(coord));
    require(mineObjectTypeId == AnyOreObjectID, "Terrain is not an ore");
    // TODO: Calculate ore object type based on random number
    ObjectTypeId oreObjectTypeId = CoalOreObjectID;

    ObjectType._set(entityId, oreObjectTypeId);

    if (oreObjectTypeId == LavaObjectID) {
      // Apply consequences of lava
      if (ObjectType._get(terrainCommitmentData.committerEntityId) == PlayerObjectID) {
        VoxelCoord memory committerCoord = PlayerStatus._getIsLoggedOff(terrainCommitmentData.committerEntityId)
          ? LastKnownPosition._get(terrainCommitmentData.committerEntityId).toVoxelCoord()
          : Position._get(terrainCommitmentData.committerEntityId).toVoxelCoord();

        // TODO: apply lava damage

        notify(
          terrainCommitmentData.committerEntityId,
          RevealOreNotifData({ oreCoord: coord, oreObjectTypeId: oreObjectTypeId })
        );
      } // else: the player died, no need to do anything
    }

    // Clear commitment data
    TerrainCommitment._deleteRecord(coord.x, coord.y, coord.z);
    Commitment._deleteRecord(terrainCommitmentData.committerEntityId);

    return oreObjectTypeId;
  }
}
