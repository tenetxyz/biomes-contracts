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
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId, NullObjectTypeId, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, removeAnyFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, CraftNotifData } from "../utils/NotifUtils.sol";
import { energyToMass, transferEnergyToPool } from "../utils/EnergyUtils.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_CRAFT_ENERGY_COST } from "../Constants.sol";

contract CraftSystem is System {
  function craftWithStation(bytes32 recipeId, EntityId stationEntityId) public {
    RecipesData memory recipeData = Recipes._get(recipeId);
    require(recipeData.inputTypes.length > 0, "Recipe not found");

    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    if (!recipeData.stationTypeId.isNull()) {
      require(stationEntityId.exists(), "This recipe requires a station");
      require(ObjectType._get(stationEntityId.baseEntityId()) == recipeData.stationTypeId, "Invalid station");
      requireInPlayerInfluence(playerCoord, stationEntityId);
    }

    // Require that the player has all the ingredients in its inventory
    // And delete the ingredients from the inventory as they are used
    for (uint256 i = 0; i < recipeData.inputTypes.length; i++) {
      ObjectTypeId inputObjectTypeId = ObjectTypeId.wrap(recipeData.inputTypes[i]);
      // totalInputObjectMass += ObjectTypeMetadata._getMass(inputObjectTypeId);
      // totalInputObjectEnergy += ObjectTypeMetadata._getEnergy(inputObjectTypeId);
      if (inputObjectTypeId.isAny()) {
        removeAnyFromInventoryCount(playerEntityId, inputObjectTypeId, recipeData.inputAmounts[i]);
      } else {
        removeFromInventoryCount(playerEntityId, inputObjectTypeId, recipeData.inputAmounts[i]);
      }
    }

    // Create the crafted objects
    for (uint256 i = 0; i < recipeData.outputTypes.length; i++) {
      ObjectTypeId outputType = ObjectTypeId.wrap(recipeData.outputTypes[i]);
      uint16 outputAmount = recipeData.outputAmounts[i];
      if (outputType.isTool()) {
        for (uint256 j = 0; j < outputAmount; j++) {
          EntityId newInventoryEntityId = getUniqueEntity();
          ObjectType._set(newInventoryEntityId, outputType);
          InventoryEntity._set(newInventoryEntityId, playerEntityId);
          ReverseInventoryEntity._push(playerEntityId, EntityId.unwrap(newInventoryEntityId));
          // TODO: figure out how mass should work with multiple inputs/outputs
          // TODO: should we check that total output energy == total input energy? or should we do it at the recipe level?
          // uint128 toolMass = totalInputObjectMass + energyToMass(totalInputObjectEnergy);
          Mass._set(newInventoryEntityId, ObjectTypeMetadata._getMass(outputType));
        }
      }

      addToInventoryCount(playerEntityId, PlayerObjectID, outputType, outputAmount);
    }

    // TODO: handle dyes

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_CRAFT_ENERGY_COST);

    notify(playerEntityId, CraftNotifData({ recipeId: recipeId, stationEntityId: stationEntityId }));
  }

  function craft(bytes32 recipeId) public {
    craftWithStation(recipeId, EntityId.wrap(bytes32(0)));
  }
}
