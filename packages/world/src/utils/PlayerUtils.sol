// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { Position, PositionData } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy } from "../codegen/tables/Energy.sol";
import { Commitment } from "../codegen/tables/Commitment.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus } from "../Utils.sol";
import { updatePlayerEnergyLevel } from "./EnergyUtils.sol";

import { EntityId } from "../EntityId.sol";

using VoxelCoordLib for PositionData;

function requireValidPlayer(address player) returns (EntityId, VoxelCoord memory) {
  checkWorldStatus();
  EntityId playerEntityId = Player._get(player);
  require(playerEntityId.exists(), "Player does not exist");
  require(!PlayerStatus._getIsLoggedOff(playerEntityId), "Player isn't logged in");
  require(!Commitment._getHasCommitted(playerEntityId), "Player is in a commitment");
  VoxelCoord memory playerCoord = Position._get(playerEntityId).toVoxelCoord();
  updatePlayerEnergyLevel(playerEntityId);
  PlayerActivity._set(playerEntityId, uint128(block.timestamp));
  return (playerEntityId, playerCoord);
}

function requireBesidePlayer(VoxelCoord memory playerCoord, VoxelCoord memory coord) pure {
  require(playerCoord.inSurroundingCube(1, coord), "Player is too far");
}

function requireBesidePlayer(VoxelCoord memory playerCoord, EntityId entityId) view returns (VoxelCoord memory) {
  VoxelCoord memory coord = Position._get(entityId).toVoxelCoord();
  requireBesidePlayer(playerCoord, coord);
  return coord;
}

function requireInPlayerInfluence(VoxelCoord memory playerCoord, VoxelCoord memory coord) pure {
  require(playerCoord.inSurroundingCube(MAX_PLAYER_INFLUENCE_HALF_WIDTH, coord), "Player is too far");
}

function requireInPlayerInfluence(VoxelCoord memory playerCoord, EntityId entityId) view returns (VoxelCoord memory) {
  VoxelCoord memory coord = Position._get(entityId).toVoxelCoord();
  requireInPlayerInfluence(playerCoord, coord);
  return coord;
}

function despawnPlayer(EntityId playerEntityId) {
  // Note: Inventory is already attached to the entity id, which means it'll be
  // attached to air, ie it's a "dropped" item
  ObjectType._set(playerEntityId, AirObjectID);

  Mass._deleteRecord(playerEntityId);
  Energy._deleteRecord(playerEntityId);

  if (Equipped._get(playerEntityId).exists()) {
    Equipped._deleteRecord(playerEntityId);
  }

  PlayerStatus._deleteRecord(playerEntityId);
  PlayerActivity._deleteRecord(playerEntityId);
  address player = ReversePlayer._get(playerEntityId);
  Player._deleteRecord(player);
  ReversePlayer._deleteRecord(playerEntityId);
}
