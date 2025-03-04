// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { Position, PlayerPosition, ReversePlayerPosition } from "../utils/Vec3Storage.sol";

import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { updateEnergyLevel } from "./EnergyUtils.sol";
import { getForceField } from "./ForceFieldUtils.sol";
import { transferAllInventoryEntities } from "./InventoryUtils.sol";
import { getObjectTypeIdAt, getPlayer, setPlayer } from "./EntityUtils.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";

using ObjectTypeLib for ObjectTypeId;

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
  require(playerCoord.inSurroundingCube(coord, 1), "Player is too far");
}

function requireBesidePlayer(Vec3 playerCoord, EntityId entityId) view returns (Vec3) {
  Vec3 coord = Position._get(entityId);
  requireBesidePlayer(playerCoord, coord);
  return coord;
}

function requireInPlayerInfluence(Vec3 playerCoord, Vec3 coord) pure {
  require(playerCoord.inSurroundingCube(coord, MAX_PLAYER_INFLUENCE_HALF_WIDTH), "Player is too far");
}

function requireInPlayerInfluence(Vec3 playerCoord, EntityId entityId) view returns (Vec3) {
  Vec3 coord = Position._get(entityId);
  requireInPlayerInfluence(playerCoord, coord);
  return coord;
}

function createPlayer(EntityId playerEntityId, Vec3 playerCoord) {
  // Set the player object type first
  ObjectType._set(playerEntityId, ObjectTypes.Player);

  // Position the player at the given coordinates
  addPlayerToGrid(playerEntityId, playerCoord);
}

function addPlayerToGrid(EntityId playerEntityId, Vec3 playerCoord) {
  // Check if the spawn location is valid
  ObjectTypeId terrainObjectTypeId = getObjectTypeIdAt(playerCoord);
  require(
    terrainObjectTypeId == ObjectTypes.Air && !getPlayer(playerCoord).exists(),
    "Cannot spawn on a non-air block"
  );

  // Set the player at the base coordinate
  setPlayer(playerCoord, playerEntityId);

  // Handle the player's body parts
  Vec3[] memory coords = ObjectTypes.Player.getRelativeCoords(playerCoord);
  // Only iterate through relative schema coords
  for (uint256 i = 1; i < coords.length; i++) {
    Vec3 relativeCoord = coords[i];
    ObjectTypeId relativeTerrainObjectTypeId = getObjectTypeIdAt(relativeCoord);
    require(
      relativeTerrainObjectTypeId == ObjectTypes.Air && !getPlayer(relativeCoord).exists(),
      "Cannot spawn on a non-air block"
    );
    EntityId relativePlayerEntityId = getUniqueEntity();
    ObjectType._set(relativePlayerEntityId, ObjectTypes.Player);
    setPlayer(relativeCoord, relativePlayerEntityId);
    BaseEntity._set(relativePlayerEntityId, playerEntityId);
  }
}

function removePlayerFromGrid(EntityId playerEntityId, Vec3 playerCoord) {
  PlayerPosition._deleteRecord(playerEntityId);
  ReversePlayerPosition._deleteRecord(playerCoord);

  Vec3[] memory coords = ObjectTypes.Player.getRelativeCoords(playerCoord);
  // Only iterate through relative schema coords
  for (uint256 i = 1; i < coords.length; i++) {
    Vec3 relativeCoord = coords[i];
    EntityId relativePlayerEntityId = getPlayer(relativeCoord);
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
