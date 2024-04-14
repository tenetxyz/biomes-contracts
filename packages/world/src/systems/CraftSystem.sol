// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { RecipesData } from "@biomesaw/terrain/src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { NullObjectTypeId, AirObjectID, PlayerObjectID, AnyLogObjectID, AnyLumberObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { getObjectTypeDurability, getRecipe } from "../utils/TerrainUtils.sol";
import { addToInventoryCount, removeFromInventoryCount, removeEntityIdFromReverseInventory } from "../utils/InventoryUtils.sol";
import { isLog, isLumber } from "@biomesaw/terrain/src/utils/ObjectTypeUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, bytes32[] memory ingredientEntityIds, bytes32 stationEntityId) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "CraftSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "CraftSystem: player isn't logged in");

    RecipesData memory recipeData = getRecipe(recipeId);
    require(recipeData.inputObjectTypeIds.length > 0, "CraftSystem: recipe not found");
    if (recipeData.stationObjectTypeId != NullObjectTypeId) {
      require(ObjectType._get(stationEntityId) == recipeData.stationObjectTypeId, "CraftSystem: wrong station");
      require(
        inSurroundingCube(
          positionDataToVoxelCoord(Position._get(stationEntityId)),
          1,
          positionDataToVoxelCoord(Position._get(playerEntityId))
        ),
        "CraftSystem: player is too far from the station"
      );
    }

    // Require that the acting object has all the ingredients in its inventory
    // And delete the ingredients from the inventory as they are used
    for (uint256 i = 0; i < recipeData.inputObjectTypeIds.length; i++) {
      uint256 numInputObjectTypesFound = 0;
      for (uint256 j = 0; j < ingredientEntityIds.length; j++) {
        if (Inventory._get(ingredientEntityIds[j]) == playerEntityId) {
          uint8 ingredientObjectTypeId = ObjectType._get(ingredientEntityIds[j]);
          if (
            ingredientObjectTypeId == recipeData.inputObjectTypeIds[i] ||
            (recipeData.inputObjectTypeIds[i] == AnyLogObjectID && isLog(ingredientObjectTypeId)) ||
            (recipeData.inputObjectTypeIds[i] == AnyLumberObjectID && isLumber(ingredientObjectTypeId))
          ) {
            numInputObjectTypesFound++;

            // Delete the ingredient from the inventory
            ObjectType._deleteRecord(ingredientEntityIds[j]);
            Inventory._deleteRecord(ingredientEntityIds[j]);
            removeEntityIdFromReverseInventory(playerEntityId, ingredientEntityIds[j]);
            if (ItemMetadata._get(ingredientEntityIds[j]) != 0) {
              ItemMetadata._deleteRecord(ingredientEntityIds[j]);
            }
            if (Equipped._get(playerEntityId) == ingredientEntityIds[j]) {
              Equipped._deleteRecord(playerEntityId);
            }

            // Note: this can't be moved out of the loop because of the object variants (ie log/lumber)
            removeFromInventoryCount(playerEntityId, ingredientObjectTypeId, 1);
          }
        }
      }
      require(numInputObjectTypesFound == recipeData.inputObjectTypeAmounts[i], "CraftSystem: not enough ingredients");
    }

    // Create the crafted objects
    for (uint256 i = 0; i < recipeData.outputObjectTypeAmount; i++) {
      bytes32 newInventoryEntityId = getUniqueEntity();
      ObjectType._set(newInventoryEntityId, recipeData.outputObjectTypeId);
      Inventory._set(newInventoryEntityId, playerEntityId);
      ReverseInventory._push(playerEntityId, newInventoryEntityId);
      uint24 durability = getObjectTypeDurability(recipeData.outputObjectTypeId);
      if (durability > 0) {
        ItemMetadata._set(newInventoryEntityId, durability);
      }
    }
    addToInventoryCount(
      playerEntityId,
      PlayerObjectID,
      recipeData.outputObjectTypeId,
      recipeData.outputObjectTypeAmount
    );
  }
}
