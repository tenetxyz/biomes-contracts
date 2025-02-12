// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../Types.sol";
import { inSurroundingCube } from "./VoxelCoordUtils.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy } from "../codegen/tables/Energy.sol";
import { Commitment } from "../codegen/tables/Commitment.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, positionDataToVoxelCoord } from "../Utils.sol";

import { EntityId } from "../EntityId.sol";

function requireValidPlayer(address player) returns (EntityId, VoxelCoord memory) {
  checkWorldStatus();
  EntityId playerEntityId = Player._get(player);
  require(playerEntityId.exists(), "Player does not exist");
  require(!PlayerStatus._getIsLoggedOff(playerEntityId), "Player isn't logged in");
  require(!Commitment._getHasCommitted(playerEntityId), "Player is in a commitment");
  VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));

  // TODO: update energy, should decrease over time
  Energy._setEnergy(playerEntityId, Energy._getEnergy(playerEntityId) + 1);

  PlayerActivity._set(playerEntityId, uint128(block.timestamp));

  return (playerEntityId, playerCoord);
}

function requireBesidePlayer(VoxelCoord memory playerCoord, VoxelCoord memory coord) pure {
  require(inSurroundingCube(playerCoord, 1, coord), "Player is too far");
}

function requireBesidePlayer(VoxelCoord memory playerCoord, EntityId entityId) view returns (VoxelCoord memory) {
  VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
  requireBesidePlayer(playerCoord, coord);
  return coord;
}

function requireInPlayerInfluence(VoxelCoord memory playerCoord, VoxelCoord memory coord) pure {
  require(inSurroundingCube(playerCoord, MAX_PLAYER_INFLUENCE_HALF_WIDTH, coord), "Player is too far");
}

function requireInPlayerInfluence(VoxelCoord memory playerCoord, EntityId entityId) view returns (VoxelCoord memory) {
  VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
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
