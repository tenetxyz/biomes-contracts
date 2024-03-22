// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, TIME_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, TIME_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";

function regenHealth(bytes32 entityId) {
  HealthData memory healthData = Health.get(entityId);
  if (healthData.health >= MAX_PLAYER_HEALTH && healthData.lastUpdatedTime != block.timestamp) {
    Health.setLastUpdatedTime(entityId, block.timestamp);
    return;
  }

  // Calculate how much time has passed since last update
  uint256 timeSinceLastUpdate = block.timestamp - healthData.lastUpdatedTime;
  if (timeSinceLastUpdate <= TIME_BEFORE_INCREASE_HEALTH) {
    return;
  }

  // Calculate the new health
  uint16 numAddHealth = uint16((timeSinceLastUpdate / TIME_BEFORE_INCREASE_HEALTH) * HEALTH_INCREASE_RATE);
  uint16 newHealth = healthData.health + numAddHealth;
  if (newHealth > MAX_PLAYER_HEALTH) {
    newHealth = MAX_PLAYER_HEALTH;
  }

  Health.set(entityId, HealthData({ health: newHealth, lastUpdatedTime: block.timestamp }));
}

function regenStamina(bytes32 entityId) {
  StaminaData memory staminaData = Stamina.get(entityId);
  if (staminaData.stamina >= MAX_PLAYER_STAMINA && staminaData.lastUpdatedTime != block.timestamp) {
    Stamina.setLastUpdatedTime(entityId, block.timestamp);
    return;
  }

  // Calculate how much time has passed since last update
  uint256 timeSinceLastUpdate = block.timestamp - staminaData.lastUpdatedTime;
  if (timeSinceLastUpdate <= TIME_BEFORE_INCREASE_STAMINA) {
    return;
  }

  // Calculate the new stamina
  uint32 numAddStamina = uint32((timeSinceLastUpdate / TIME_BEFORE_INCREASE_STAMINA) * STAMINA_INCREASE_RATE);
  uint32 newStamina = staminaData.stamina + numAddStamina;
  if (newStamina > MAX_PLAYER_STAMINA) {
    newStamina = MAX_PLAYER_STAMINA;
  }

  Stamina.set(entityId, StaminaData({ stamina: newStamina, lastUpdatedTime: block.timestamp }));
}

function despawnPlayer(bytes32 playerEntityId) {
  // Note: Inventory is already attached to the entity id, which means it'll be
  // attached to air, ie it's a "dropped" item
  ObjectType.set(playerEntityId, AirObjectID);

  Health.deleteRecord(playerEntityId);
  Stamina.deleteRecord(playerEntityId);
  if (Equipped.get(playerEntityId) != bytes32(0)) {
    Equipped.deleteRecord(playerEntityId);
  }

  PlayerMetadata.deleteRecord(playerEntityId);
  address player = ReversePlayer.get(playerEntityId);
  Player.deleteRecord(player);
  ReversePlayer.deleteRecord(playerEntityId);
}
