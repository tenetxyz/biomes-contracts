// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectTypeId, AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";

import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { updateEnergyLevel } from "./EnergyUtils.sol";
import { getForceField } from "./ForceFieldUtils.sol";
import { transferAllInventoryEntities } from "./InventoryUtils.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";

function requireValidPlayer(address player) returns (EntityId, Vec3, EnergyData memory) {
  checkWorldStatus();
  EntityId playerEntityId = Player._get(player);
  require(playerEntityId.exists(), "Player does not exist");
  require(!PlayerStatus._getBedEntityId(playerEntityId).exists(), "Player is sleeping");
  Vec3 playerCoord = PlayerPosition._get(playerEntityId);

  EnergyData memory playerEnergyData = updateEnergyLevel(playerEntityId);
  require(playerEnergyData.energy > 0, "Player is dead");

  PlayerActivity._set(playerEntityId, uint128(block.timestamp));
  return (playerEntityId, playerCoord, playerEnergyData);
}

function requireBesidePlayer(Vec3 playerCoord, Vec3 coord) pure {
  require(playerCoord.inSurroundingCube(1, coord), "Player is too far");
}

function requireBesidePlayer(Vec3 playerCoord, EntityId entityId) view returns (Vec3) {
  Vec3 coord = Position._get(entityId);
  requireBesidePlayer(playerCoord, coord);
  return coord;
}

function requireInPlayerInfluence(Vec3 playerCoord, Vec3 coord) pure {
  require(playerCoord.inSurroundingCube(MAX_PLAYER_INFLUENCE_HALF_WIDTH, coord), "Player is too far");
}

function requireInPlayerInfluence(Vec3 playerCoord, EntityId entityId) view returns (Vec3) {
  Vec3 coord = Position._get(entityId);
  requireInPlayerInfluence(playerCoord, coord);
  return coord;
}

function createPlayer(EntityId playerEntityId, Vec3 playerCoord) {
  // Set the player object type first
  ObjectType._set(playerEntityId, PlayerObjectID);

  // Position the player at the given coordinates
  addPlayerToGrid(playerEntityId, playerCoord);
}

function addPlayerToGrid(EntityId playerEntityId, Vec3 playerCoord) {
  // Check if the spawn location is valid
  ObjectTypeId terrainObjectTypeId = playerCoord.getObjectTypeId();
  require(terrainObjectTypeId == AirObjectID && !playerCoord.getPlayer().exists(), "Cannot spawn on a non-air block");

  // Set the player at the base coordinate
  playerCoord.setPlayer(playerEntityId);

  // Handle the player's body parts
  Vec3[] memory coords = playerCoord.getRelativeCoords(PlayerObjectID);
  // Only iterate through relative schema coords
  for (uint256 i = 1; i < coords.length; i++) {
    Vec3 relativeCoord = coords[i];
    ObjectTypeId relativeTerrainObjectTypeId = relativeCoord.getObjectTypeId();
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

function removePlayerFromGrid(EntityId playerEntityId, Vec3 playerCoord) {
  PlayerPosition._deleteRecord(playerEntityId);
  ReversePlayerPosition._deleteRecord(playerCoord);

  Vec3[] memory coords = playerCoord.getRelativeCoords(PlayerObjectID);
  // Only iterate through relative schema coords
  for (uint256 i = 1; i < coords.length; i++) {
    Vec3 relativeCoord = coords[i];
    EntityId relativePlayerEntityId = relativeCoord.getPlayer();
    PlayerPosition._deleteRecord(relativePlayerEntityId);
    ReversePlayerPosition._deleteRecord(relativeCoord);
    ObjectType._deleteRecord(relativePlayerEntityId);
    BaseEntity._deleteRecord(relativePlayerEntityId);
  }
}

function removePlayerFromBed(EntityId playerEntityId, EntityId bedEntityId, EntityId forceFieldEntityId) {
  PlayerStatus._deleteRecord(playerEntityId);
  BedPlayer._deleteRecord(bedEntityId);

  // Decrease forcefield's drain rate
  Energy._setDrainRate(forceFieldEntityId, Energy._getDrainRate(forceFieldEntityId) - PLAYER_ENERGY_DRAIN_RATE);
}
