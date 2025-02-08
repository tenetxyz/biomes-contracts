// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectCategory } from "../../codegen/common.sol";

import { BlueDyeObjectID, BrownDyeObjectID, GreenDyeObjectID, MagentaDyeObjectID, OrangeDyeObjectID, PinkDyeObjectID, PurpleDyeObjectID, RedDyeObjectID, TanDyeObjectID, WhiteDyeObjectID, YellowDyeObjectID, BlackDyeObjectID, SilverDyeObjectID } from "../../ObjectTypeIds.sol";
import { ClayObjectID, StoneObjectID, CobblestoneObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { AnyLogObjectID, WoodenPickObjectID, WoodenAxeObjectID, WoodenWhackerObjectID } from "../../ObjectTypeIds.sol";
import { OakLumberObjectID, SakuraLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../../ObjectTypeIds.sol";
import { BellflowerObjectID, SakuraLumberObjectID, CactusObjectID, LilacObjectID, AzaleaObjectID, DaylilyObjectID, AzaleaObjectID, LilacObjectID, RoseObjectID, SandObjectID, CottonBushObjectID, DandelionObjectID, NeptuniumOreObjectID, SilverOreObjectID } from "../../ObjectTypeIds.sol";
import { DirtObjectID, OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID } from "../../ObjectTypeIds.sol";

import { MAX_BLOCK_STACKABLE, MAX_TOOL_STACKABLE } from "../../Constants.sol";
import { createSingleInputRecipe, createDoubleInputRecipe } from "../../utils/RecipeUtils.sol";

contract InitHandBlocksSystem is System {
  function createHandcraftedBlock(uint16 terrainBlockObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        objectCategory: ObjectCategory.Block,
        stackable: MAX_BLOCK_STACKABLE,
        maxInventorySlots: 0,
        mass: mass,
        energy: 0
      })
    );
  }

  function createHandcraftedTool(uint16 toolObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      toolObjectTypeId,
      ObjectTypeMetadataData({
        objectCategory: ObjectCategory.Tool,
        stackable: MAX_TOOL_STACKABLE,
        maxInventorySlots: 0,
        mass: mass,
        energy: 0
      })
    );
  }

  function createHandcraftedItem(uint16 itemObjectTypeId) internal {
    ObjectTypeMetadata._set(
      itemObjectTypeId,
      ObjectTypeMetadataData({
        objectCategory: ObjectCategory.Item,
        stackable: MAX_BLOCK_STACKABLE,
        maxInventorySlots: 0,
        mass: 0,
        energy: 0
      })
    );
  }

  function initHandcraftedObjectTypes() public {
    createHandcraftedBlock(CobblestoneObjectID, 55);
    createHandcraftedBlock(ClayObjectID, 10);
    createHandcraftedBlock(CottonBlockObjectID, 5);

    createHandcraftedItem(BlueDyeObjectID);
    createHandcraftedItem(BrownDyeObjectID);
    createHandcraftedItem(GreenDyeObjectID);
    createHandcraftedItem(MagentaDyeObjectID);
    createHandcraftedItem(OrangeDyeObjectID);
    createHandcraftedItem(PinkDyeObjectID);
    createHandcraftedItem(PurpleDyeObjectID);
    createHandcraftedItem(RedDyeObjectID);
    createHandcraftedItem(TanDyeObjectID);
    createHandcraftedItem(WhiteDyeObjectID);
    createHandcraftedItem(YellowDyeObjectID);
    createHandcraftedItem(BlackDyeObjectID);
    createHandcraftedItem(SilverDyeObjectID);

    createHandcraftedTool(WoodenPickObjectID, 18750);
    createHandcraftedTool(WoodenAxeObjectID, 18750);
    createHandcraftedTool(WoodenWhackerObjectID, 18750);

    createHandcraftedBlock(OakLumberObjectID, 20);
    createHandcraftedBlock(SakuraLumberObjectID, 20);
    createHandcraftedBlock(RubberLumberObjectID, 20);
    createHandcraftedBlock(BirchLumberObjectID, 20);
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
