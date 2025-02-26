// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { Position, PositionData } from "../codegen/tables/Position.sol";
import { PlayerPosition, PlayerPositionData } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";
import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { updatePlayerEnergyLevel } from "./EnergyUtils.sol";
import { EntityId } from "../EntityId.sol";

using VoxelCoordLib for PositionData;
using VoxelCoordLib for PlayerPositionData;

function requireValidPlayer(address player) returns (EntityId, VoxelCoord memory, EnergyData memory) {
  checkWorldStatus();
  EntityId playerEntityId = Player._get(player);
  require(playerEntityId.exists(), "Player does not exist");
  require(!PlayerStatus._getBedEntityId(playerEntityId).exists(), "Player is sleeping");
  VoxelCoord memory playerCoord = PlayerPosition._get(playerEntityId).toVoxelCoord();
  EnergyData memory playerEnergyData = updatePlayerEnergyLevel(playerEntityId);
  PlayerActivity._set(playerEntityId, uint128(block.timestamp));
  return (playerEntityId, playerCoord, playerEnergyData);
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

function createPlayer(EntityId playerEntityId, VoxelCoord memory playerCoord) {
  (, ObjectTypeId terrainObjectTypeId) = playerCoord.getEntity();
  require(terrainObjectTypeId == AirObjectID && !playerCoord.getPlayer().exists(), "Cannot spawn on a non-air block");

  ObjectType._set(playerEntityId, PlayerObjectID);
  playerCoord.setPlayer(playerEntityId);

  VoxelCoord[] memory coords = playerCoord.getRelativeCoords(PlayerObjectID);
  // Only iterate through relative schema coords
  for (uint256 i = 1; i < coords.length; i++) {
    VoxelCoord memory relativeCoord = coords[i];
    (, ObjectTypeId relativeTerrainObjectTypeId) = relativeCoord.getEntity();
    require(
      relativeTerrainObjectTypeId == AirObjectID && !relativeCoord.getPlayer().exists(),
      "Cannot spawn on a non-air block"
    );
    EntityId relativePlayerEntityId = getUniqueEntity();
    ObjectType._set(relativePlayerEntityId, PlayerObjectID);
    relativeCoord.setPlayer(relativePlayerEntityId);
    BaseEntity._set(relativePlayerEntityId, playerEntityId);
  }
}

function deletePlayer(EntityId playerEntityId, VoxelCoord memory playerCoord) {
  ObjectType._deleteRecord(playerEntityId);
  PlayerPosition._deleteRecord(playerEntityId);
  ReversePlayerPosition._deleteRecord(playerCoord.x, playerCoord.y, playerCoord.z);

  VoxelCoord[] memory coords = playerCoord.getRelativeCoords(PlayerObjectID);
  // Only iterate through relative schema coords
  for (uint256 i = 1; i < coords.length; i++) {
    VoxelCoord memory relativeCoord = coords[i];
    EntityId relativePlayerEntityId = relativeCoord.getPlayer();
    PlayerPosition._deleteRecord(relativePlayerEntityId);
    ReversePlayerPosition._deleteRecord(relativeCoord.x, relativeCoord.y, relativeCoord.z);
    ObjectType._deleteRecord(relativePlayerEntityId);
    BaseEntity._deleteRecord(relativePlayerEntityId);
  }
}
