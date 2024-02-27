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
import { Equipped } from "./codegen/tables/Equipped.sol";
import { ItemMetadata } from "./codegen/tables/ItemMetadata.sol";
import { Health, HealthData } from "./codegen/tables/Health.sol";
import { Stamina, StaminaData } from "./codegen/tables/Stamina.sol";
import { Recipes, RecipesData } from "./codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, BLOCKS_BEFORE_INCREASE_STAMINA, STAMINA_INCREASE_RATE, BLOCKS_BEFORE_INCREASE_HEALTH, HEALTH_INCREASE_RATE } from "./Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID } from "./ObjectTypeIds.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
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
  if (numFinalSlotsUsed == 0) {
    InventorySlots.deleteRecord(ownerEntityId);
  } else {
    InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  }

  if (numFinalObjects == 0) {
    InventoryCount.deleteRecord(ownerEntityId, objectTypeId);
  } else {
    InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);
  }
}

function useEquipped(bytes32 entityId) {
  bytes32 inventoryEntityId = Equipped.get(entityId);
  if (inventoryEntityId != bytes32(0)) {
    uint16 numUsesLeft = ItemMetadata.get(inventoryEntityId);
    if (numUsesLeft > 0) {
      if (numUsesLeft == 1) {
        // Destroy equipped item
        removeFromInventoryCount(entityId, ObjectType.get(inventoryEntityId), 1);
        ItemMetadata.deleteRecord(inventoryEntityId);
        Inventory.deleteRecord(inventoryEntityId);
        Equipped.deleteRecord(entityId);
        ObjectType.deleteRecord(inventoryEntityId);
      } else {
        ItemMetadata.set(inventoryEntityId, numUsesLeft - 1);
      }
    } // 0 = unlimited uses
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

function creteSingleInputWithStationRecipe(
  bytes32 stationObjectTypeId,
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  bytes32[] memory inputObjectTypeIds = new bytes32[](1);
  inputObjectTypeIds[0] = inputObjectTypeId;
  uint8[] memory inputObjectTypeAmounts = new uint8[](1);
  inputObjectTypeAmounts[0] = inputObjectTypeAmount;

  // Form recipe id from input and output object type ids
  bytes32 recipeId = keccak256(
    abi.encodePacked(inputObjectTypeId, inputObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount)
  );
  Recipes.set(
    recipeId,
    RecipesData({
      stationObjectTypeId: stationObjectTypeId,
      inputObjectTypeIds: inputObjectTypeIds,
      inputObjectTypeAmounts: inputObjectTypeAmounts,
      outputObjectTypeId: outputObjectTypeId,
      outputObjectTypeAmount: outputObjectTypeAmount
    })
  );
}

function creteSingleInputRecipe(
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  creteSingleInputWithStationRecipe(
    bytes32(0),
    inputObjectTypeId,
    inputObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function creteDoubleInputWithStationRecipe(
  bytes32 stationObjectTypeId,
  bytes32 inputObjectTypeId1,
  uint8 inputObjectTypeAmount1,
  bytes32 inputObjectTypeId2,
  uint8 inputObjectTypeAmount2,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  bytes32[] memory inputObjectTypeIds = new bytes32[](2);
  inputObjectTypeIds[0] = inputObjectTypeId1;
  inputObjectTypeIds[1] = inputObjectTypeId2;

  uint8[] memory inputObjectTypeAmounts = new uint8[](2);
  inputObjectTypeAmounts[0] = inputObjectTypeAmount1;
  inputObjectTypeAmounts[1] = inputObjectTypeAmount2;

  // Form recipe id from input and output object type ids
  bytes32 recipeId = keccak256(
    abi.encodePacked(
      inputObjectTypeId1,
      inputObjectTypeAmount1,
      inputObjectTypeId2,
      inputObjectTypeAmount2,
      outputObjectTypeId,
      outputObjectTypeAmount
    )
  );
  Recipes.set(
    recipeId,
    RecipesData({
      stationObjectTypeId: stationObjectTypeId,
      inputObjectTypeIds: inputObjectTypeIds,
      inputObjectTypeAmounts: inputObjectTypeAmounts,
      outputObjectTypeId: outputObjectTypeId,
      outputObjectTypeAmount: outputObjectTypeAmount
    })
  );
}

function creteDoubleInputRecipe(
  bytes32 inputObjectTypeId1,
  uint8 inputObjectTypeAmount1,
  bytes32 inputObjectTypeId2,
  uint8 inputObjectTypeAmount2,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  creteDoubleInputWithStationRecipe(
    bytes32(0),
    inputObjectTypeId1,
    inputObjectTypeAmount1,
    inputObjectTypeId2,
    inputObjectTypeAmount2,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}

function createRecipeForAllLogVariations(
  uint8 logObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  creteSingleInputRecipe(OakLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  creteSingleInputRecipe(SakuraLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  creteSingleInputRecipe(RubberLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
  creteSingleInputRecipe(BirchLogObjectID, logObjectTypeAmount, outputObjectTypeId, outputObjectTypeAmount);
}

function createRecipeForAllLogVariationsWithInput(
  uint8 logObjectTypeAmount,
  bytes32 inputObjectTypeId,
  uint8 inputObjectTypeAmount,
  bytes32 outputObjectTypeId,
  uint8 outputObjectTypeAmount
) {
  creteDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    OakLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  creteDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    SakuraLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  creteDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    RubberLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
  creteDoubleInputRecipe(
    inputObjectTypeId,
    inputObjectTypeAmount,
    BirchLogObjectID,
    logObjectTypeAmount,
    outputObjectTypeId,
    outputObjectTypeAmount
  );
}
