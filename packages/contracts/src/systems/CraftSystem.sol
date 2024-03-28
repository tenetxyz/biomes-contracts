// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, removeEntityIdFromReverseInventory } from "../utils/InventoryUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, bytes32[] memory ingredientEntityIds, bytes32 stationEntityId) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "CraftSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "CraftSystem: player isn't logged in");

    RecipesData memory recipeData = Recipes._get(recipeId);
    require(recipeData.inputObjectTypeIds.length > 0, "CraftSystem: recipe not found");
    if (recipeData.stationObjectTypeId != bytes32(0)) {
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
          bytes32 ingredientObjectTypeId = ObjectType._get(ingredientEntityIds[j]);
          if (ingredientObjectTypeId == recipeData.inputObjectTypeIds[i]) {
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
          }
        }
      }
      require(numInputObjectTypesFound == recipeData.inputObjectTypeAmounts[i], "CraftSystem: not enough ingredients");
      removeFromInventoryCount(playerEntityId, recipeData.inputObjectTypeIds[i], recipeData.inputObjectTypeAmounts[i]);
    }

    // Create the crafted objects
    for (uint256 i = 0; i < recipeData.outputObjectTypeAmount; i++) {
      bytes32 newInventoryEntityId = getUniqueEntity();
      ObjectType._set(newInventoryEntityId, recipeData.outputObjectTypeId);
      Inventory._set(newInventoryEntityId, playerEntityId);
      ReverseInventory._push(playerEntityId, newInventoryEntityId);
      uint24 durability = ObjectTypeMetadata._getDurability(recipeData.outputObjectTypeId);
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
