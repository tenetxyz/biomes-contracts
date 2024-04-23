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
import { InventoryTool } from "../codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../codegen/tables/ReverseInventoryTool.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { RecipesData } from "@biomesaw/terrain/src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { NullObjectTypeId, AirObjectID, PlayerObjectID, AnyLogObjectID, AnyLumberObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { getObjectTypeDurability, getRecipe, getObjectTypeIsTool } from "../utils/TerrainUtils.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { getLogObjectTypes, getLumberObjectTypes } from "@biomesaw/terrain/src/utils/ObjectTypeUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, bytes32 stationEntityId) public {
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

    // Require that the player has all the ingredients in its inventory
    // And delete the ingredients from the inventory as they are used
    for (uint256 i = 0; i < recipeData.inputObjectTypeIds.length; i++) {
      if (recipeData.inputObjectTypeIds[i] == AnyLogObjectID) {
        uint8 numLogsLeft = recipeData.inputObjectTypeAmounts[i];
        uint8[4] memory logObjectTypeIds = getLogObjectTypes();
        for (uint256 j = 0; j < logObjectTypeIds.length; j++) {
          uint16 numLogs = InventoryCount._get(playerEntityId, logObjectTypeIds[j]);
          uint8 spendLogs = numLogs > numLogsLeft ? numLogsLeft : uint8(numLogs);
          if (spendLogs > 0) {
            removeFromInventoryCount(playerEntityId, logObjectTypeIds[j], spendLogs);
            numLogsLeft -= spendLogs;
          }
        }
        require(numLogsLeft == 0, "CraftSystem: not enough logs");
      } else if (recipeData.inputObjectTypeIds[i] == AnyLumberObjectID) {
        uint8 numLumberLeft = recipeData.inputObjectTypeAmounts[i];
        uint8[17] memory lumberObjectTypeIds = getLumberObjectTypes();
        for (uint256 j = 0; j < lumberObjectTypeIds.length; j++) {
          uint16 numLumber = InventoryCount._get(playerEntityId, lumberObjectTypeIds[j]);
          uint8 spendLumber = numLumber > numLumberLeft ? numLumberLeft : uint8(numLumber);
          if (spendLumber > 0) {
            removeFromInventoryCount(playerEntityId, lumberObjectTypeIds[j], spendLumber);
            numLumberLeft -= spendLumber;
          }
        }
        require(numLumberLeft == 0, "CraftSystem: not enough lumber");
      } else {
        removeFromInventoryCount(
          playerEntityId,
          recipeData.inputObjectTypeIds[i],
          recipeData.inputObjectTypeAmounts[i]
        );
      }
    }

    // Create the crafted objects
    if (getObjectTypeIsTool(recipeData.outputObjectTypeId)) {
      for (uint256 i = 0; i < recipeData.outputObjectTypeAmount; i++) {
        bytes32 newInventoryEntityId = getUniqueEntity();
        ObjectType._set(newInventoryEntityId, recipeData.outputObjectTypeId);
        InventoryTool._set(newInventoryEntityId, playerEntityId);
        ReverseInventoryTool._push(playerEntityId, newInventoryEntityId);
        uint24 durability = getObjectTypeDurability(recipeData.outputObjectTypeId);
        if (durability > 0) {
          ItemMetadata._set(newInventoryEntityId, durability);
        }
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
