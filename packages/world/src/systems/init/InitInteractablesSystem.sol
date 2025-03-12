// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitInteractablesSystem is System {
  function createInteractableBlock(
    ObjectTypeId objectTypeId,
    uint32 mass,
    uint16 maxInventorySlots,
    uint16 stackable
  ) internal {
    ObjectTypeMetadata._set(
      objectTypeId,
      ObjectTypeMetadataData({
        stackable: stackable,
        maxInventorySlots: maxInventorySlots,
        mass: mass,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function initInteractableObjectTypes() public {
    createInteractableBlock(ObjectTypes.Chest, 20, 24, 1);
    createInteractableBlock(ObjectTypes.SmartChest, 20, 24, 1);
    createInteractableBlock(ObjectTypes.TextSign, 20, 0, 99);
    createInteractableBlock(ObjectTypes.SmartTextSign, 20, 0, 99);
    createInteractableBlock(ObjectTypes.Thermoblaster, 80, 0, 1);
    createInteractableBlock(ObjectTypes.Workbench, 20, 0, 1);
    createInteractableBlock(ObjectTypes.Dyeomatic, 80, 0, 1);
    createInteractableBlock(ObjectTypes.Powerstone, 80, 0, 1);
    createInteractableBlock(ObjectTypes.ForceField, 80, 0, 99);
    createInteractableBlock(ObjectTypes.SpawnTile, 80, 0, 99);
    createInteractableBlock(ObjectTypes.Bed, 80, 36, 1);
  }

  function initInteractablesRecipes() public {
    createSingleInputWithStationRecipe(ObjectTypes.Workbench, ObjectTypes.AnyPlanks, 8, ObjectTypes.Chest, 1);
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.Chest,
      1,
      ObjectTypes.SilverBar,
      1,
      ObjectTypes.SmartChest,
      1
    );
    createSingleInputWithStationRecipe(ObjectTypes.Workbench, ObjectTypes.AnyPlanks, 4, ObjectTypes.TextSign, 1);
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.TextSign,
      1,
      ObjectTypes.SilverBar,
      1,
      ObjectTypes.SmartTextSign,
      1
    );
    createSingleInputRecipe(ObjectTypes.AnyLog, 5, ObjectTypes.Workbench, 1);
    createSingleInputRecipe(ObjectTypes.Stone, 9, ObjectTypes.Thermoblaster, 1);
    createDoubleInputRecipe(ObjectTypes.Clay, 4, ObjectTypes.Sand, 4, ObjectTypes.Dyeomatic, 1);
    createDoubleInputRecipe(ObjectTypes.Stone, 6, ObjectTypes.Sand, 2, ObjectTypes.Powerstone, 1);
    createDoubleInputWithStationRecipe(
      ObjectTypes.Thermoblaster,
      ObjectTypes.Stone,
      30,
      ObjectTypes.SilverBar,
      5,
      ObjectTypes.ForceField,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Thermoblaster,
      ObjectTypes.ForceField,
      1,
      ObjectTypes.NeptuniumOre,
      4,
      ObjectTypes.SpawnTile,
      1
    );

    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyPlanks,
      8,
      ObjectTypes.SilverBar,
      8,
      ObjectTypes.Bed,
      1
    );
  }
}
