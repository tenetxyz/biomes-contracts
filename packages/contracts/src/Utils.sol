// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";

import { PositionData } from "./codegen/tables/Position.sol";
import { Inventory, InventoryTableId } from "./codegen/tables/Inventory.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";
import { InventorySlots } from "./codegen/tables/InventorySlots.sol";
import { InventoryCount } from "./codegen/tables/InventoryCount.sol";
import { Health, HealthData } from "./codegen/tables/Health.sol";
import { Stamina, StaminaData } from "./codegen/tables/Stamina.sol";

import { VoxelCoord } from "./Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, BLOCKS_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, BLOCKS_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE } from "./Constants.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function inSurroundingCube(
  VoxelCoord memory cubeCenter,
  int32 halfWidth,
  VoxelCoord memory checkCoord
) pure returns (bool) {
  // Check if `checkCoord` is within the cube in all three dimensions
  bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
  bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
  bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

  return isInX && isInY && isInZ;
}

function addToInventoryCount(
  bytes32 ownerEntityId,
  bytes32 ownerObjectTypeId,
  bytes32 objectTypeId,
  uint16 numObjectsToAdd
) {
  uint8 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be added to the inventory");

  uint16 numInitialObjects = InventoryCount.get(ownerEntityId, objectTypeId);
  uint16 numFinalObjects = numInitialObjects + numObjectsToAdd;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numFinalSlotsUsed = numFinalFullStacks + (hasFinalPartialStack ? 1 : 0);
  if (ownerObjectTypeId == PlayerObjectID) {
    require(numFinalSlotsUsed <= MAX_PLAYER_INVENTORY_SLOTS, "Inventory is full");
  } else if (ownerObjectTypeId == ChestObjectID) {
    require(numFinalSlotsUsed <= MAX_CHEST_INVENTORY_SLOTS, "Inventory is full");
  }
  InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);
}

function removeFromInventoryCount(bytes32 ownerEntityId, bytes32 objectTypeId, uint16 numObjectsToRemove) {
  uint16 numInitialObjects = InventoryCount.get(ownerEntityId, objectTypeId);
  require(numInitialObjects >= numObjectsToRemove, "Not enough objects in the inventory");

  uint8 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be removed from the inventory");

  uint16 numFinalObjects = numInitialObjects - numObjectsToRemove;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numFinalSlotsUsed = numFinalFullStacks + (hasFinalPartialStack ? 1 : 0);
  if(numFinalSlotsUsed == 0){
    InventorySlots.deleteRecord(ownerEntityId);
  } else {
    InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  }

  if(numFinalObjects == 0){
    InventoryCount.deleteRecord(ownerEntityId, objectTypeId);
  } else {
    InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);
  }
}

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
