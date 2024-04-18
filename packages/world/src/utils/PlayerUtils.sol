// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, TIME_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, TIME_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";

function regenHealth(bytes32 entityId) {
  HealthData memory healthData = Health._get(entityId);
  if (healthData.health >= MAX_PLAYER_HEALTH) {
    return;
  }

  // Calculate how much time has passed since last update
  uint256 timeSinceLastUpdate = block.timestamp - healthData.lastUpdatedTime;
  if (timeSinceLastUpdate <= TIME_BEFORE_INCREASE_HEALTH) {
    return;
  }

  uint256 addHealth = (timeSinceLastUpdate / TIME_BEFORE_INCREASE_HEALTH) * HEALTH_INCREASE_RATE;
  uint16 newHealth = healthData.health + addHealth > MAX_PLAYER_HEALTH
    ? MAX_PLAYER_HEALTH
    : healthData.health + uint16(addHealth);

  Health._set(entityId, HealthData({ health: newHealth, lastUpdatedTime: block.timestamp }));
}

function regenStamina(bytes32 entityId) {
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
  uint256 numAddStamina = (timeSinceLastUpdate / TIME_BEFORE_INCREASE_STAMINA) * STAMINA_INCREASE_RATE;
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
  if (Equipped._get(playerEntityId) != bytes32(0)) {
    Equipped._deleteRecord(playerEntityId);
  }

  PlayerMetadata._deleteRecord(playerEntityId);
  address player = ReversePlayer._get(playerEntityId);
  Player._deleteRecord(player);
  ReversePlayer._deleteRecord(playerEntityId);
}
