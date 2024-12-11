// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { Commitment } from "../codegen/tables/Commitment.sol";

import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, TIME_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, WATER_STAMINA_INCREASE_RATE, TIME_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE, IN_MAINTENANCE } from "../Constants.sol";
import { AirObjectID, WaterObjectID } from "../ObjectTypeIds.sol";
import { getTerrainObjectTypeId, positionDataToVoxelCoord } from "../Utils.sol";

function requireValidPlayer(address player) returns (bytes32, VoxelCoord memory) {
  require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
  bytes32 playerEntityId = Player._get(player);
  require(playerEntityId != bytes32(0), "Player does not exist");
  require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "Player isn't logged in");
  require(!Commitment._getHasCommitted(playerEntityId), "Player is in a commitment");
  VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));

  regenHealth(playerEntityId);
  regenStamina(playerEntityId, playerCoord);

  PlayerActivity._set(playerEntityId, block.timestamp);

  return (playerEntityId, playerCoord);
}

function requireBesidePlayer(VoxelCoord memory playerCoord, VoxelCoord memory coord) {
  require(inSurroundingCube(playerCoord, 1, coord), "Player is too far");
}

function requireBesidePlayer(VoxelCoord memory playerCoord, bytes32 entityId) returns (VoxelCoord memory) {
  VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
  requireBesidePlayer(playerCoord, coord);
  return coord;
}

function requireInPlayerInfluence(VoxelCoord memory playerCoord, VoxelCoord memory coord) {
  require(inSurroundingCube(playerCoord, MAX_PLAYER_INFLUENCE_HALF_WIDTH, coord), "Player is too far");
}

function requireInPlayerInfluence(VoxelCoord memory playerCoord, bytes32 entityId) returns (VoxelCoord memory) {
  VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(entityId));
  requireInPlayerInfluence(playerCoord, coord);
  return coord;
}

function regenHealth(bytes32 entityId) returns (uint16) {
  HealthData memory healthData = Health._get(entityId);
  if (healthData.health >= MAX_PLAYER_HEALTH) {
    return healthData.health;
  }

  // Calculate how much time has passed since last update
  uint256 timeSinceLastUpdate = block.timestamp - healthData.lastUpdatedTime;
  if (timeSinceLastUpdate <= TIME_BEFORE_INCREASE_HEALTH) {
    return healthData.health;
  }

  uint256 addHealth = (timeSinceLastUpdate / TIME_BEFORE_INCREASE_HEALTH) * HEALTH_INCREASE_RATE;
  uint16 newHealth = healthData.health + addHealth > MAX_PLAYER_HEALTH
    ? MAX_PLAYER_HEALTH
    : healthData.health + uint16(addHealth);

  Health._set(entityId, HealthData({ health: newHealth, lastUpdatedTime: block.timestamp }));

  return newHealth;
}

function regenStamina(bytes32 entityId, VoxelCoord memory entityCoord) {
  StaminaData memory staminaData = Stamina._get(entityId);
  if (staminaData.stamina >= MAX_PLAYER_STAMINA) {
    return;
  }

  // Calculate how much time has passed since last update
  uint256 timeSinceLastUpdate = block.timestamp - staminaData.lastUpdatedTime;
  if (timeSinceLastUpdate <= TIME_BEFORE_INCREASE_STAMINA) {
    return;
  }

  // Calculate the new stamina
  // bool isInWater = getTerrainObjectTypeId(entityCoord) == WaterObjectID;
  // TODO: Update after farming update
  bool isInWater = false;

  // Calculate the new stamina
  uint256 numAddStamina = (timeSinceLastUpdate / TIME_BEFORE_INCREASE_STAMINA) *
    (isInWater ? WATER_STAMINA_INCREASE_RATE : STAMINA_INCREASE_RATE);
  uint32 newStamina = staminaData.stamina + numAddStamina > MAX_PLAYER_STAMINA
    ? MAX_PLAYER_STAMINA
    : staminaData.stamina + uint32(numAddStamina);

  Stamina._set(entityId, StaminaData({ stamina: newStamina, lastUpdatedTime: block.timestamp }));
}

function despawnPlayer(bytes32 playerEntityId) {
  // Note: Inventory is already attached to the entity id, which means it'll be
  // attached to air, ie it's a "dropped" item
  ObjectType._set(playerEntityId, AirObjectID);

  Health._deleteRecord(playerEntityId);
  Stamina._deleteRecord(playerEntityId);
  ExperiencePoints._deleteRecord(playerEntityId);

  if (Equipped._get(playerEntityId) != bytes32(0)) {
    Equipped._deleteRecord(playerEntityId);
  }

  PlayerMetadata._deleteRecord(playerEntityId);
  PlayerActivity._deleteRecord(playerEntityId);
  address player = ReversePlayer._get(playerEntityId);
  Player._deleteRecord(player);
  ReversePlayer._deleteRecord(playerEntityId);
}
