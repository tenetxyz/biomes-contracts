// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health, HealthData } from "../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../codegen/tables/Stamina.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, BLOCKS_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, BLOCKS_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";

function regenHealth(bytes32 entityId) {
  HealthData memory healthData = Health.get(entityId);
  if (healthData.health >= MAX_PLAYER_HEALTH && healthData.lastUpdateBlock != block.number) {
    Health.setLastUpdateBlock(entityId, block.number);
    return;
  }

  // Calculate how many blocks have passed since last update
  uint256 blocksSinceLastUpdate = block.number - healthData.lastUpdateBlock;
  if (blocksSinceLastUpdate <= BLOCKS_BEFORE_INCREASE_HEALTH) {
    return;
  }

  // Calculate the new health
  // TODO: check overflow?
  uint16 numAddHealth = uint16((blocksSinceLastUpdate / BLOCKS_BEFORE_INCREASE_HEALTH) * HEALTH_INCREASE_RATE);
  uint16 newHealth = healthData.health + numAddHealth;
  if (newHealth > MAX_PLAYER_HEALTH) {
    newHealth = MAX_PLAYER_HEALTH;
  }

  Health.set(entityId, HealthData({ health: newHealth, lastUpdateBlock: block.number }));
}

function regenStamina(bytes32 entityId) {
  StaminaData memory staminaData = Stamina.get(entityId);
  if (staminaData.stamina >= MAX_PLAYER_STAMINA && staminaData.lastUpdateBlock != block.number) {
    Stamina.setLastUpdateBlock(entityId, block.number);
    return;
  }

  // Calculate how many blocks have passed since last update
  uint256 blocksSinceLastUpdate = block.number - staminaData.lastUpdateBlock;
  if (blocksSinceLastUpdate <= BLOCKS_BEFORE_INCREASE_STAMINA) {
    return;
  }

  // Calculate the new stamina
  // TODO: check overflow?
  uint32 numAddStamina = uint32((blocksSinceLastUpdate / BLOCKS_BEFORE_INCREASE_STAMINA) * STAMINA_INCREASE_RATE);
  uint32 newStamina = staminaData.stamina + numAddStamina;
  if (newStamina > MAX_PLAYER_STAMINA) {
    newStamina = MAX_PLAYER_STAMINA;
  }

  Stamina.set(entityId, StaminaData({ stamina: newStamina, lastUpdateBlock: block.number }));
}

function despawnPlayer(address player, bytes32 playerEntityId) {
  // Note: Inventory is already attached to the entity id, which means it'll be
  // attached to air, ie it's a "dropped" item
  ObjectType.set(playerEntityId, AirObjectID);

  Health.deleteRecord(playerEntityId);
  Stamina.deleteRecord(playerEntityId);
  if (Equipped.get(playerEntityId) != bytes32(0)) {
    Equipped.deleteRecord(playerEntityId);
  }

  PlayerMetadata.deleteRecord(playerEntityId);
  Player.deleteRecord(player);
}
