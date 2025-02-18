// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../codegen/tables/ReverseInventoryEntity.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId, NullObjectTypeId, PlayerObjectID, AnyLogObjectID, AnyLumberObjectID, AnyCottonBlockObjectID, AnyGlassObjectID, AnyReinforcedLumberObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { getLogObjectTypes, getLumberObjectTypes, getReinforcedLumberObjectTypes, getCottonBlockObjectTypes, getGlassObjectTypes } from "../utils/ObjectTypeUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, CraftNotifData } from "../utils/NotifUtils.sol";
import { energyToMass, transferEnergyFromPlayerToPool } from "../utils/EnergyUtils.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_CRAFT_ENERGY_COST } from "../Constants.sol";

contract CraftSystem is System {
  function craft(bytes32 recipeId, EntityId stationEntityId) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );

    EntityId baseStationEntityId = stationEntityId.baseEntityId();

    RecipesData memory recipeData = Recipes._get(recipeId);
    require(recipeData.inputObjectTypeIds.length > 0, "Recipe not found");
    if (recipeData.stationObjectTypeId != NullObjectTypeId) {
      require(ObjectType._get(baseStationEntityId) == recipeData.stationObjectTypeId, "Wrong station");
      requireInPlayerInfluence(playerCoord, stationEntityId);
    }

    // Require that the player has all the ingredients in its inventory
    // And delete the ingredients from the inventory as they are used
    uint128 totalInputObjectMass = 0;
    uint128 totalInputObjectEnergy = 0;
    for (uint256 i = 0; i < recipeData.inputObjectTypeIds.length; i++) {
      ObjectTypeId inputObjectTypeId = ObjectTypeId.wrap(recipeData.inputObjectTypeIds[i]);
      totalInputObjectMass += ObjectTypeMetadata._getMass(inputObjectTypeId);
      totalInputObjectEnergy += ObjectTypeMetadata._getEnergy(inputObjectTypeId);
      // TODO: Figure out a generic way to do this
      if (inputObjectTypeId == AnyLogObjectID) {
        uint16 numLogsLeft = recipeData.inputObjectTypeAmounts[i];
        ObjectTypeId[4] memory logObjectTypeIds = getLogObjectTypes();
        for (uint256 j = 0; j < logObjectTypeIds.length; j++) {
          uint16 numLogs = InventoryCount._get(playerEntityId, logObjectTypeIds[j]);
          uint16 spendLogs = numLogs > numLogsLeft ? numLogsLeft : uint16(numLogs);
          if (spendLogs > 0) {
            removeFromInventoryCount(playerEntityId, logObjectTypeIds[j], spendLogs);
            numLogsLeft -= spendLogs;
          }
        }
        require(numLogsLeft == 0, "Not enough logs");
      } else if (inputObjectTypeId == AnyLumberObjectID) {
        uint16 numLumberLeft = recipeData.inputObjectTypeAmounts[i];
        ObjectTypeId[17] memory lumberObjectTypeIds = getLumberObjectTypes();
        for (uint256 j = 0; j < lumberObjectTypeIds.length; j++) {
          uint16 numLumber = InventoryCount._get(playerEntityId, lumberObjectTypeIds[j]);
          uint16 spendLumber = numLumber > numLumberLeft ? numLumberLeft : uint16(numLumber);
          if (spendLumber > 0) {
            removeFromInventoryCount(playerEntityId, lumberObjectTypeIds[j], spendLumber);
            numLumberLeft -= spendLumber;
          }
        }
        require(numLumberLeft == 0, "Not enough lumber");
      } else if (inputObjectTypeId == AnyReinforcedLumberObjectID) {
        uint16 numReinforcedLumberLeft = recipeData.inputObjectTypeAmounts[i];
        ObjectTypeId[3] memory reinforcedLumberObjectTypeIds = getReinforcedLumberObjectTypes();
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
      } else if (inputObjectTypeId == AnyCottonBlockObjectID) {
        uint16 numCottonBlockLeft = recipeData.inputObjectTypeAmounts[i];
        ObjectTypeId[14] memory cottonBlockObjectTypeIds = getCottonBlockObjectTypes();
        for (uint256 j = 0; j < cottonBlockObjectTypeIds.length; j++) {
          uint16 numCottonBlock = InventoryCount._get(playerEntityId, cottonBlockObjectTypeIds[j]);
          uint16 spendCottonBlock = numCottonBlock > numCottonBlockLeft ? numCottonBlockLeft : uint16(numCottonBlock);
          if (spendCottonBlock > 0) {
            removeFromInventoryCount(playerEntityId, cottonBlockObjectTypeIds[j], spendCottonBlock);
            numCottonBlockLeft -= spendCottonBlock;
          }
        }
        require(numCottonBlockLeft == 0, "Not enough cotton blocks");
      } else if (inputObjectTypeId == AnyGlassObjectID) {
        uint16 numGlassLeft = recipeData.inputObjectTypeAmounts[i];
        ObjectTypeId[10] memory glassObjectTypeIds = getGlassObjectTypes();
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
        removeFromInventoryCount(playerEntityId, inputObjectTypeId, recipeData.inputObjectTypeAmounts[i]);
      }
    }

    // Create the crafted objects
    if (recipeData.outputObjectTypeId.isTool()) {
      for (uint256 i = 0; i < recipeData.outputObjectTypeAmount; i++) {
        EntityId newInventoryEntityId = getUniqueEntity();
        ObjectType._set(newInventoryEntityId, recipeData.outputObjectTypeId);
        InventoryEntity._set(newInventoryEntityId, playerEntityId);
        ReverseInventoryEntity._push(playerEntityId, EntityId.unwrap(newInventoryEntityId));
        uint128 toolMass = totalInputObjectMass + energyToMass(totalInputObjectEnergy);
        Mass._set(newInventoryEntityId, toolMass);
      }
    }

    // TODO: handle dyes

    transferEnergyFromPlayerToPool(playerEntityId, playerCoord, playerEnergyData, PLAYER_CRAFT_ENERGY_COST);

    addToInventoryCount(
      playerEntityId,
      PlayerObjectID,
      recipeData.outputObjectTypeId,
      recipeData.outputObjectTypeAmount
    );

    notify(playerEntityId, CraftNotifData({ recipeId: recipeId, stationEntityId: stationEntityId }));
  }
}
