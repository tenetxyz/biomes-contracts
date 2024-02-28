// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../../codegen/tables/Recipes.sol";

import { MAX_TOOL_STACKABLE } from "../../Constants.sol";
import { StonePickObjectID, StoneAxeObjectID, StoneWhackerObjectID, SilverPickObjectID, SilverAxeObjectID, SilverWhackerObjectID, GoldPickObjectID, GoldAxeObjectID, NeptuniumPickObjectID, NeptuniumAxeObjectID, DiamondPickObjectID, DiamondAxeObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, SakuraLogObjectID, RubberLogObjectID, BirchLogObjectID, SilverBarObjectID, GoldBarObjectID, DiamondObjectID, NeptuniumBarObjectID, StoneObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createRecipeForAllLogVariations, createRecipeForAllLogVariationsWithInput } from "../../Utils.sol";

contract InitToolsSystem is System {
  function createTool(bytes32 toolObjectTypeId, uint16 mass, uint16 durability, uint16 damage) internal {
    ObjectTypeMetadata.set(
      toolObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: mass,
        stackable: MAX_TOOL_STACKABLE,
        durability: durability,
        damage: damage,
        occurence: bytes4(0)
      })
    );
  }

  // TODO: add durability and damage values
  function initToolObjectTypes() public {
    createTool(StonePickObjectID, 36, 0, 0);
    createTool(StoneAxeObjectID, 36, 0, 0);
    createTool(StoneWhackerObjectID, 72, 0, 0);

    createTool(SilverPickObjectID, 160, 0, 0);
    createTool(SilverAxeObjectID, 160, 0, 0);
    createTool(SilverWhackerObjectID, 216, 0, 0);

    createTool(GoldPickObjectID, 176, 0, 0);
    createTool(GoldAxeObjectID, 176, 0, 0);

    createTool(DiamondPickObjectID, 196, 0, 0);
    createTool(DiamondAxeObjectID, 196, 0, 0);

    createTool(NeptuniumPickObjectID, 336, 0, 0);
    createTool(NeptuniumAxeObjectID, 336, 0, 0);
  }

  function initToolRecipes() public {

    createRecipeForAllLogVariationsWithInput(4, StoneObjectID, 8, StonePickObjectID, 1);
    createRecipeForAllLogVariationsWithInput(4, StoneObjectID, 8, StoneAxeObjectID, 1);
    createRecipeForAllLogVariationsWithInput(2, StoneObjectID, 4, StoneWhackerObjectID, 1);

    createRecipeForAllLogVariationsWithInput(4, SilverBarObjectID, 4, SilverPickObjectID, 1);
    createRecipeForAllLogVariationsWithInput(4, SilverBarObjectID, 4, SilverAxeObjectID, 1);
    createSingleInputRecipe(SilverBarObjectID, 6, SilverWhackerObjectID, 1);

    createRecipeForAllLogVariationsWithInput(4, GoldBarObjectID, 4, GoldPickObjectID, 1);
    createRecipeForAllLogVariationsWithInput(4, GoldBarObjectID, 4, GoldAxeObjectID, 1);

    createRecipeForAllLogVariationsWithInput(4, DiamondObjectID, 4, DiamondPickObjectID, 1);
    createRecipeForAllLogVariationsWithInput(4, DiamondObjectID, 4, DiamondAxeObjectID, 1);

    createRecipeForAllLogVariationsWithInput(4, NeptuniumBarObjectID, 4, NeptuniumPickObjectID, 1);
    createRecipeForAllLogVariationsWithInput(4, NeptuniumBarObjectID, 4, NeptuniumAxeObjectID, 1);
  }
}
