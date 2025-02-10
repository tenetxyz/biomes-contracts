// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { TerrainCommitment, TerrainCommitmentData } from "../codegen/tables/TerrainCommitment.sol";
import { Commitment } from "../codegen/tables/Commitment.sol";
import { BlockPrevrandao } from "../codegen/tables/BlockPrevrandao.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID, AnyOreObjectID, LavaObjectID, CoalOreObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getRandomNumberBetween0And99 } from "../Utils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

contract OreSystem is System {
  function initiateOreReveal(VoxelCoord memory coord) public {
    require(inWorldBorder(coord), "Cannot reveal ore outside world border");

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);
    if (TerrainCommitment._getBlockNumber(coord.x, coord.y, coord.z) != 0) {
      revealOre(coord);
      return;
    }

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId != bytes32(0), "Cannot initiate ore reveal on unrevealed terrain");
    uint16 mineObjectTypeId = ObjectType._get(entityId);
    require(mineObjectTypeId == AnyOreObjectID, "Terrain is not an ore");

    TerrainCommitment._set(coord.x, coord.y, coord.z, block.number, playerEntityId);
    Commitment._set(playerEntityId, true, coord.x, coord.y, coord.z);
    BlockPrevrandao._set(block.number, block.prevrandao);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.InitiateOreReveal,
        entityId: playerEntityId,
        objectTypeId: mineObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: block.number
      })
    );
  }

  // Can be called by anyone
  function revealOre(VoxelCoord memory coord) public returns (uint16) {
    TerrainCommitmentData memory terrainCommitmentData = TerrainCommitment._get(coord.x, coord.y, coord.z);
    require(terrainCommitmentData.blockNumber != 0, "Terrain commitment not found");

    uint256 randomNumber = getRandomNumberBetween0And99(terrainCommitmentData.blockNumber);

    // TODO: Fix
    uint16 oreObjectTypeId = CoalOreObjectID;

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId != bytes32(0), "Cannot reveal ore on unrevealed terrain");

    uint16 mineObjectTypeId = ObjectType._get(entityId);
    require(mineObjectTypeId == AnyOreObjectID, "Terrain is not an ore");

    ObjectType._set(entityId, oreObjectTypeId);

    if (oreObjectTypeId == LavaObjectID) {
      // Apply consequences of lava
      if (ObjectType._get(terrainCommitmentData.committerEntityId) == PlayerObjectID) {
        VoxelCoord memory committerCoord = PlayerStatus._getIsLoggedOff(terrainCommitmentData.committerEntityId)
          ? lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(terrainCommitmentData.committerEntityId))
          : positionDataToVoxelCoord(Position._get(terrainCommitmentData.committerEntityId));

        // TODO: apply lava damage

        PlayerActionNotif._set(
          terrainCommitmentData.committerEntityId,
          PlayerActionNotifData({
            actionType: ActionType.RevealOre,
            entityId: terrainCommitmentData.committerEntityId,
            objectTypeId: oreObjectTypeId,
            coordX: coord.x,
            coordY: coord.y,
            coordZ: coord.z,
            amount: 0
          })
        );
      } // else: the player died, no need to do anything
    }

    // Clear commitment data
    TerrainCommitment._deleteRecord(coord.x, coord.y, coord.z);
    Commitment._deleteRecord(terrainCommitmentData.committerEntityId);

    bytes32 playerEntityId = Player._get(_msgSender());
    if (playerEntityId != bytes32(0)) {
      PlayerActionNotif._set(
        playerEntityId,
        PlayerActionNotifData({
          actionType: ActionType.RevealOre,
          entityId: terrainCommitmentData.committerEntityId,
          objectTypeId: oreObjectTypeId,
          coordX: coord.x,
          coordY: coord.y,
          coordZ: coord.z,
          amount: terrainCommitmentData.blockNumber
        })
      );
    }

    return oreObjectTypeId;
  }
}
