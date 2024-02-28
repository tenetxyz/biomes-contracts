// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory, InventoryTableId } from "../codegen/tables/Inventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, addToInventoryCount, removeFromInventoryCount } from "../Utils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, bytes32[] memory ingredientEntityIds, bytes32 stationEntityId) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "CraftSystem: player does not exist");

    RecipesData memory recipeData = Recipes.get(recipeId);
    require(recipeData.inputObjectTypeIds.length > 0, "CraftSystem: recipe not found");
    if (recipeData.stationObjectTypeId != bytes32(0)) {
      require(ObjectType.get(stationEntityId) == recipeData.stationObjectTypeId, "CraftSystem: wrong station");
      require(
        inSurroundingCube(
          positionDataToVoxelCoord(Position.get(stationEntityId)),
          1,
          positionDataToVoxelCoord(Position.get(playerEntityId))
        ),
        "CraftSystem: player is too far from the station"
      );
    }

    // Require that the acting object has all the ingredients in its inventory
    // And delete the ingredients from the inventory as they are used
    for (uint256 i = 0; i < recipeData.inputObjectTypeIds.length; i++) {
      uint256 numInputObjectTypesFound = 0;
      for (uint256 j = 0; j < ingredientEntityIds.length; j++) {
        if (Inventory.get(ingredientEntityIds[j]) == playerEntityId) {
          bytes32 ingredientObjectTypeId = ObjectType.get(ingredientEntityIds[j]);
          if (ingredientObjectTypeId == recipeData.inputObjectTypeIds[i]) {
            numInputObjectTypesFound++;

            // Delete the ingredient from the inventory
            ObjectType.deleteRecord(ingredientEntityIds[j]);
            Inventory.deleteRecord(ingredientEntityIds[j]);
            if (ItemMetadata.get(ingredientEntityIds[j]) != 0) {
              ItemMetadata.deleteRecord(ingredientEntityIds[j]);
            }
            if (Equipped.get(playerEntityId) == ingredientEntityIds[j]) {
              Equipped.deleteRecord(playerEntityId);
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
      ObjectType.set(newInventoryEntityId, recipeData.outputObjectTypeId);
      Inventory.set(newInventoryEntityId, playerEntityId);
      uint16 durability = ObjectTypeMetadata.getDurability(recipeData.outputObjectTypeId);
      if (durability > 0) {
        ItemMetadata.set(newInventoryEntityId, durability);
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
