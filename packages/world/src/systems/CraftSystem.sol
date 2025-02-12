// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../codegen/tables/ReverseInventoryEntity.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectCategory, ActionType } from "../codegen/common.sol";

import { NullObjectTypeId, PlayerObjectID, AnyLogObjectID, AnyLumberObjectID, AnyCottonBlockObjectID, AnyGlassObjectID, AnyReinforcedLumberObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { getLogObjectTypes, getLumberObjectTypes, getReinforcedLumberObjectTypes, getCottonBlockObjectTypes, getGlassObjectTypes } from "../utils/ObjectTypeUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, CraftNotifData } from "../utils/NotifUtils.sol";

import { EntityId } from "../EntityId.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, EntityId stationEntityId) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    EntityId baseStationEntityId = stationEntityId.baseEntityId();

    RecipesData memory recipeData = Recipes._get(recipeId);
    require(recipeData.inputObjectTypeIds.length > 0, "Recipe not found");
    if (recipeData.stationObjectTypeId != NullObjectTypeId) {
      require(ObjectType._get(baseStationEntityId) == recipeData.stationObjectTypeId, "Wrong station");
      requireInPlayerInfluence(playerCoord, stationEntityId);
    }

    // Require that the player has all the ingredients in its inventory
    // And delete the ingredients from the inventory as they are used
    for (uint256 i = 0; i < recipeData.inputObjectTypeIds.length; i++) {
      // TODO: Figure out a generic way to do this
      if (recipeData.inputObjectTypeIds[i] == AnyLogObjectID) {
        uint16 numLogsLeft = recipeData.inputObjectTypeAmounts[i];
        uint16[4] memory logObjectTypeIds = getLogObjectTypes();
        for (uint256 j = 0; j < logObjectTypeIds.length; j++) {
          uint16 numLogs = InventoryCount._get(playerEntityId, logObjectTypeIds[j]);
          uint16 spendLogs = numLogs > numLogsLeft ? numLogsLeft : uint16(numLogs);
          if (spendLogs > 0) {
            removeFromInventoryCount(playerEntityId, logObjectTypeIds[j], spendLogs);
            numLogsLeft -= spendLogs;
          }
        }
        require(numLogsLeft == 0, "Not enough logs");
      } else if (recipeData.inputObjectTypeIds[i] == AnyLumberObjectID) {
        uint16 numLumberLeft = recipeData.inputObjectTypeAmounts[i];
        uint16[17] memory lumberObjectTypeIds = getLumberObjectTypes();
        for (uint256 j = 0; j < lumberObjectTypeIds.length; j++) {
          uint16 numLumber = InventoryCount._get(playerEntityId, lumberObjectTypeIds[j]);
          uint16 spendLumber = numLumber > numLumberLeft ? numLumberLeft : uint16(numLumber);
          if (spendLumber > 0) {
            removeFromInventoryCount(playerEntityId, lumberObjectTypeIds[j], spendLumber);
            numLumberLeft -= spendLumber;
          }
        }
        require(numLumberLeft == 0, "Not enough lumber");
      } else if (recipeData.inputObjectTypeIds[i] == AnyReinforcedLumberObjectID) {
        uint16 numReinforcedLumberLeft = recipeData.inputObjectTypeAmounts[i];
        uint16[3] memory reinforcedLumberObjectTypeIds = getReinforcedLumberObjectTypes();
        for (uint256 j = 0; j < reinforcedLumberObjectTypeIds.length; j++) {
          uint16 numReinforcedLumber = InventoryCount._get(playerEntityId, reinforcedLumberObjectTypeIds[j]);
          uint16 spendReinforcedLumber = numReinforcedLumber > numReinforcedLumberLeft
            ? numReinforcedLumberLeft
            : uint16(numReinforcedLumber);
          if (spendReinforcedLumber > 0) {
            removeFromInventoryCount(playerEntityId, reinforcedLumberObjectTypeIds[j], spendReinforcedLumber);
            numReinforcedLumberLeft -= spendReinforcedLumber;
          }
        }
        require(numReinforcedLumberLeft == 0, "Not enough reinforced lumber");
      } else if (recipeData.inputObjectTypeIds[i] == AnyCottonBlockObjectID) {
        uint16 numCottonBlockLeft = recipeData.inputObjectTypeAmounts[i];
        uint16[14] memory cottonBlockObjectTypeIds = getCottonBlockObjectTypes();
        for (uint256 j = 0; j < cottonBlockObjectTypeIds.length; j++) {
          uint16 numCottonBlock = InventoryCount._get(playerEntityId, cottonBlockObjectTypeIds[j]);
          uint16 spendCottonBlock = numCottonBlock > numCottonBlockLeft ? numCottonBlockLeft : uint16(numCottonBlock);
          if (spendCottonBlock > 0) {
            removeFromInventoryCount(playerEntityId, cottonBlockObjectTypeIds[j], spendCottonBlock);
            numCottonBlockLeft -= spendCottonBlock;
          }
        }
        require(numCottonBlockLeft == 0, "Not enough cotton blocks");
      } else if (recipeData.inputObjectTypeIds[i] == AnyGlassObjectID) {
        uint16 numGlassLeft = recipeData.inputObjectTypeAmounts[i];
        uint16[10] memory glassObjectTypeIds = getGlassObjectTypes();
        for (uint256 j = 0; j < glassObjectTypeIds.length; j++) {
          uint16 numGlass = InventoryCount._get(playerEntityId, glassObjectTypeIds[j]);
          uint16 spendGlass = numGlass > numGlassLeft ? numGlassLeft : uint16(numGlass);
          if (spendGlass > 0) {
            removeFromInventoryCount(playerEntityId, glassObjectTypeIds[j], spendGlass);
            numGlassLeft -= spendGlass;
          }
        }
        require(numGlassLeft == 0, "Not enough glass");
      } else {
        removeFromInventoryCount(
          playerEntityId,
          recipeData.inputObjectTypeIds[i],
          recipeData.inputObjectTypeAmounts[i]
        );
      }
    }

    // Create the crafted objects
    if (ObjectTypeMetadata._getObjectCategory(recipeData.outputObjectTypeId) == ObjectCategory.Tool) {
      for (uint256 i = 0; i < recipeData.outputObjectTypeAmount; i++) {
        EntityId newInventoryEntityId = getUniqueEntity();
        ObjectType._set(newInventoryEntityId, recipeData.outputObjectTypeId);
        InventoryEntity._set(newInventoryEntityId, playerEntityId);
        ReverseInventoryEntity._push(playerEntityId, EntityId.unwrap(newInventoryEntityId));
        uint128 mass = ObjectTypeMetadata._getMass(recipeData.outputObjectTypeId);
        if (mass > 0) {
          Mass._setMass(newInventoryEntityId, mass);
        }
      }
    }

    addToInventoryCount(
      playerEntityId,
      PlayerObjectID,
      recipeData.outputObjectTypeId,
      recipeData.outputObjectTypeAmount
    );

    notify(playerEntityId, CraftNotifData({ recipeId: recipeId, stationEntityId: stationEntityId }));
  }
}
