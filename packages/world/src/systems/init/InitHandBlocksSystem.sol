// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";

import { MAX_BLOCK_STACKABLE, MAX_TOOL_STACKABLE, MAX_ITEM_STACKABLE } from "../../Constants.sol";
import { createSingleInputRecipe, createDoubleInputRecipe } from "../../utils/RecipeUtils.sol";

contract InitHandBlocksSystem is System {
  function createHandcraftedBlock(ObjectTypeId terrainBlockObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        stackable: MAX_BLOCK_STACKABLE,
        maxInventorySlots: 0,
        mass: mass,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function createHandcraftedTool(ObjectTypeId toolObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      toolObjectTypeId,
      ObjectTypeMetadataData({
        stackable: MAX_TOOL_STACKABLE,
        maxInventorySlots: 0,
        mass: mass,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function createHandcraftedItem(ObjectTypeId itemObjectTypeId) internal {
    ObjectTypeMetadata._set(
      itemObjectTypeId,
      ObjectTypeMetadataData({
        stackable: MAX_ITEM_STACKABLE,
        maxInventorySlots: 0,
        mass: 0,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function initHandcraftedObjectTypes() public {
    createHandcraftedTool(ObjectTypes.WoodenPick, 18750);
    createHandcraftedTool(ObjectTypes.WoodenAxe, 18750);
    createHandcraftedTool(ObjectTypes.WoodenWhacker, 18750);

    createHandcraftedBlock(ObjectTypes.OakPlanks, 20);
    createHandcraftedBlock(ObjectTypes.BirchPlanks, 20);
    createHandcraftedBlock(ObjectTypes.JunglePlanks, 20);
    createHandcraftedBlock(ObjectTypes.SakuraPlanks, 20);
    createHandcraftedBlock(ObjectTypes.AcaciaPlanks, 20);
    createHandcraftedBlock(ObjectTypes.SprucePlanks, 20);
    createHandcraftedBlock(ObjectTypes.DarkOakPlanks, 20);
  }

  function initHandcrafedRecipes() public {
    createSingleInputRecipe(ObjectTypes.AnyLog, 4, ObjectTypes.WoodenPick, 1);
    createSingleInputRecipe(ObjectTypes.AnyLog, 4, ObjectTypes.WoodenAxe, 1);
    createSingleInputRecipe(ObjectTypes.AnyLog, 8, ObjectTypes.WoodenWhacker, 1);

    createSingleInputRecipe(ObjectTypes.OakLog, 1, ObjectTypes.OakPlanks, 4);
    createSingleInputRecipe(ObjectTypes.BirchLog, 1, ObjectTypes.BirchPlanks, 4);
    createSingleInputRecipe(ObjectTypes.JungleLog, 1, ObjectTypes.JunglePlanks, 4);
    createSingleInputRecipe(ObjectTypes.SakuraLog, 1, ObjectTypes.SakuraPlanks, 4);
    createSingleInputRecipe(ObjectTypes.AcaciaLog, 1, ObjectTypes.AcaciaPlanks, 4);
    createSingleInputRecipe(ObjectTypes.SpruceLog, 1, ObjectTypes.SprucePlanks, 4);
    createSingleInputRecipe(ObjectTypes.DarkOakLog, 1, ObjectTypes.DarkOakPlanks, 4);
  }
}
