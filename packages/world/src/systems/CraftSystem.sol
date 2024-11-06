// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { InventoryTool } from "../codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../codegen/tables/ReverseInventoryTool.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { NullObjectTypeId, PlayerObjectID, AnyLogObjectID, AnyLumberObjectID, AnyCottonBlockObjectID, AnyGlassObjectID, AnyReinforcedLumberObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity, callMintXP } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { getLogObjectTypes, getLumberObjectTypes, getReinforcedLumberObjectTypes, getCottonBlockObjectTypes, getGlassObjectTypes } from "../utils/ObjectTypeUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, bytes32 stationEntityId) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    bytes32 baseEntityId = BaseEntity._get(stationEntityId);
    bytes32 useStationEntityId = baseEntityId == bytes32(0) ? stationEntityId : baseEntityId;

    RecipesData memory recipeData = Recipes._get(recipeId);
    require(recipeData.inputObjectTypeIds.length > 0, "CraftSystem: recipe not found");
    if (recipeData.stationObjectTypeId != NullObjectTypeId) {
      require(ObjectType._get(useStationEntityId) == recipeData.stationObjectTypeId, "CraftSystem: wrong station");
      requireInPlayerInfluence(playerCoord, stationEntityId);
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
      } else if (recipeData.inputObjectTypeIds[i] == AnyReinforcedLumberObjectID) {
        uint8 numReinforcedLumberLeft = recipeData.inputObjectTypeAmounts[i];
        uint8[3] memory reinforcedLumberObjectTypeIds = getReinforcedLumberObjectTypes();
        for (uint256 j = 0; j < reinforcedLumberObjectTypeIds.length; j++) {
          uint16 numReinforcedLumber = InventoryCount._get(playerEntityId, reinforcedLumberObjectTypeIds[j]);
          uint8 spendReinforcedLumber = numReinforcedLumber > numReinforcedLumberLeft
            ? numReinforcedLumberLeft
            : uint8(numReinforcedLumber);
          if (spendReinforcedLumber > 0) {
            removeFromInventoryCount(playerEntityId, reinforcedLumberObjectTypeIds[j], spendReinforcedLumber);
            numReinforcedLumberLeft -= spendReinforcedLumber;
          }
        }
        require(numReinforcedLumberLeft == 0, "CraftSystem: not enough reinforced lumber");
      } else if (recipeData.inputObjectTypeIds[i] == AnyCottonBlockObjectID) {
        uint8 numCottonBlockLeft = recipeData.inputObjectTypeAmounts[i];
        uint8[14] memory cottonBlockObjectTypeIds = getCottonBlockObjectTypes();
        for (uint256 j = 0; j < cottonBlockObjectTypeIds.length; j++) {
          uint16 numCottonBlock = InventoryCount._get(playerEntityId, cottonBlockObjectTypeIds[j]);
          uint8 spendCottonBlock = numCottonBlock > numCottonBlockLeft ? numCottonBlockLeft : uint8(numCottonBlock);
          if (spendCottonBlock > 0) {
            removeFromInventoryCount(playerEntityId, cottonBlockObjectTypeIds[j], spendCottonBlock);
            numCottonBlockLeft -= spendCottonBlock;
          }
        }
        require(numCottonBlockLeft == 0, "CraftSystem: not enough cotton blocks");
      } else if (recipeData.inputObjectTypeIds[i] == AnyGlassObjectID) {
        uint8 numGlassLeft = recipeData.inputObjectTypeAmounts[i];
        uint8[10] memory glassObjectTypeIds = getGlassObjectTypes();
        for (uint256 j = 0; j < glassObjectTypeIds.length; j++) {
          uint16 numGlass = InventoryCount._get(playerEntityId, glassObjectTypeIds[j]);
          uint8 spendGlass = numGlass > numGlassLeft ? numGlassLeft : uint8(numGlass);
          if (spendGlass > 0) {
            removeFromInventoryCount(playerEntityId, glassObjectTypeIds[j], spendGlass);
            numGlassLeft -= spendGlass;
          }
        }
        require(numGlassLeft == 0, "CraftSystem: not enough glass");
      } else {
        removeFromInventoryCount(
          playerEntityId,
          recipeData.inputObjectTypeIds[i],
          recipeData.inputObjectTypeAmounts[i]
        );
      }
    }

    // Create the crafted objects
    if (ObjectTypeMetadata._getIsTool(recipeData.outputObjectTypeId)) {
      for (uint256 i = 0; i < recipeData.outputObjectTypeAmount; i++) {
        bytes32 newInventoryEntityId = getUniqueEntity();
        ObjectType._set(newInventoryEntityId, recipeData.outputObjectTypeId);
        InventoryTool._set(newInventoryEntityId, playerEntityId);
        ReverseInventoryTool._push(playerEntityId, newInventoryEntityId);
        uint24 durability = ObjectTypeMetadata._getDurability(recipeData.outputObjectTypeId);
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

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Craft,
        entityId: useStationEntityId,
        objectTypeId: recipeData.outputObjectTypeId,
        coordX: playerCoord.x,
        coordY: playerCoord.y,
        coordZ: playerCoord.z,
        amount: recipeData.outputObjectTypeAmount
      })
    );

    callMintXP(playerEntityId, initialGas, 1);
  }
}
