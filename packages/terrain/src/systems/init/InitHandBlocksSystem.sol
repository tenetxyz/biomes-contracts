// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../../codegen/tables/Recipes.sol";

import { BlueDyeObjectID, BrownDyeObjectID, GreenDyeObjectID, MagentaDyeObjectID, OrangeDyeObjectID, PinkDyeObjectID, PurpleDyeObjectID, RedDyeObjectID, TanDyeObjectID, WhiteDyeObjectID, YellowDyeObjectID, BlackDyeObjectID, SilverDyeObjectID } from "../../ObjectTypeIds.sol";
import { ClayObjectID, StoneObjectID, CobblestoneObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { AnyLogObjectID, WoodenPickObjectID, WoodenAxeObjectID, WoodenWhackerObjectID } from "../../ObjectTypeIds.sol";
import { OakLumberObjectID, SakuraLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../../ObjectTypeIds.sol";
import { BellflowerObjectID, SakuraLumberObjectID, CactusObjectID, LilacObjectID, AzaleaObjectID, DaylilyObjectID, AzaleaObjectID, LilacObjectID, RoseObjectID, SandObjectID, CottonBushObjectID, DandelionObjectID, NeptuniumOreObjectID, SilverOreObjectID } from "../../ObjectTypeIds.sol";
import { DirtObjectID, OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID } from "../../ObjectTypeIds.sol";

import { MAX_BLOCK_STACKABLE, MAX_TOOL_STACKABLE } from "../../Constants.sol";
import { createSingleInputRecipe, createDoubleInputRecipe } from "../../utils/RecipeUtils.sol";

contract InitHandBlocksSystem is System {
  function createHandcraftedBlock(uint8 terrainBlockObjectTypeId, uint16 mass, uint16 hardness) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: true,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        hardness: hardness
      })
    );
  }

  function createHandcraftedTool(uint8 toolObjectTypeId, uint16 mass, uint24 durability, uint16 damage) internal {
    ObjectTypeMetadata._set(
      toolObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: false,
        mass: mass,
        stackable: MAX_TOOL_STACKABLE,
        durability: durability,
        damage: damage,
        hardness: 0
      })
    );
  }

  function createHandcraftedItem(uint8 itemObjectTypeId, uint16 mass) internal {
    ObjectTypeMetadata._set(
      itemObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: false,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        hardness: 0
      })
    );
  }

  function initHandcraftedObjectTypes() public {
    createHandcraftedBlock(CobblestoneObjectID, 2, 1);
    createHandcraftedBlock(ClayObjectID, 16, 1);
    createHandcraftedBlock(CottonBlockObjectID, 4, 1);

    createHandcraftedItem(BlueDyeObjectID, 1);
    createHandcraftedItem(BrownDyeObjectID, 1);
    createHandcraftedItem(GreenDyeObjectID, 1);
    createHandcraftedItem(MagentaDyeObjectID, 1);
    createHandcraftedItem(OrangeDyeObjectID, 1);
    createHandcraftedItem(PinkDyeObjectID, 1);
    createHandcraftedItem(PurpleDyeObjectID, 1);
    createHandcraftedItem(RedDyeObjectID, 1);
    createHandcraftedItem(TanDyeObjectID, 1);
    createHandcraftedItem(WhiteDyeObjectID, 1);
    createHandcraftedItem(YellowDyeObjectID, 1);
    createHandcraftedItem(BlackDyeObjectID, 1);
    createHandcraftedItem(SilverDyeObjectID, 1);

    createHandcraftedTool(WoodenPickObjectID, 16, 50, 80);
    createHandcraftedTool(WoodenAxeObjectID, 16, 50, 80);
    createHandcraftedTool(WoodenWhackerObjectID, 32, 10, 100);

    createHandcraftedBlock(OakLumberObjectID, 1, 1);
    createHandcraftedBlock(SakuraLumberObjectID, 1, 1);
    createHandcraftedBlock(RubberLumberObjectID, 1, 1);
    createHandcraftedBlock(BirchLumberObjectID, 1, 1);
  }

  function initHandcrafedRecipes() public {
    createSingleInputRecipe(StoneObjectID, 1, CobblestoneObjectID, 4);
    createSingleInputRecipe(DirtObjectID, 4, ClayObjectID, 1);

    createSingleInputRecipe(CottonBushObjectID, 4, CottonBlockObjectID, 1);

    createSingleInputRecipe(BellflowerObjectID, 10, BlueDyeObjectID, 10);
    createSingleInputRecipe(SakuraLumberObjectID, 10, BrownDyeObjectID, 10);
    createSingleInputRecipe(CactusObjectID, 4, GreenDyeObjectID, 10);
    createSingleInputRecipe(DaylilyObjectID, 10, OrangeDyeObjectID, 10);
    createSingleInputRecipe(AzaleaObjectID, 10, PinkDyeObjectID, 10);
    createSingleInputRecipe(LilacObjectID, 10, PurpleDyeObjectID, 10);
    createSingleInputRecipe(RoseObjectID, 10, RedDyeObjectID, 10);
    createSingleInputRecipe(SandObjectID, 5, TanDyeObjectID, 10);
    createSingleInputRecipe(CottonBushObjectID, 2, WhiteDyeObjectID, 8);
    createSingleInputRecipe(DandelionObjectID, 10, YellowDyeObjectID, 10);
    createSingleInputRecipe(SilverOreObjectID, 1, SilverDyeObjectID, 9);
    createSingleInputRecipe(NeptuniumOreObjectID, 1, BlackDyeObjectID, 20);
    createDoubleInputRecipe(LilacObjectID, 5, AzaleaObjectID, 5, MagentaDyeObjectID, 10);

    createSingleInputRecipe(AnyLogObjectID, 4, WoodenPickObjectID, 1);
    createSingleInputRecipe(AnyLogObjectID, 4, WoodenAxeObjectID, 1);
    createSingleInputRecipe(AnyLogObjectID, 8, WoodenWhackerObjectID, 1);

    createSingleInputRecipe(OakLogObjectID, 1, OakLumberObjectID, 4);
    createSingleInputRecipe(SakuraLogObjectID, 1, SakuraLumberObjectID, 4);
    createSingleInputRecipe(BirchLogObjectID, 1, BirchLumberObjectID, 4);
    createSingleInputRecipe(RubberLogObjectID, 1, RubberLumberObjectID, 4);
  }
}
