// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../../codegen/tables/Recipes.sol";

import { MAX_TOOL_STACKABLE, MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { SilverOreObjectID, StonePickObjectID, StoneAxeObjectID, StoneWhackerObjectID, SilverPickObjectID, SilverAxeObjectID, SilverWhackerObjectID, GoldPickObjectID, GoldAxeObjectID, NeptuniumPickObjectID, NeptuniumAxeObjectID, DiamondPickObjectID, DiamondAxeObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, SakuraLogObjectID, RubberLogObjectID, BirchLogObjectID, SilverBarObjectID, GoldBarObjectID, DiamondObjectID, NeptuniumBarObjectID, StoneObjectID } from "../../ObjectTypeIds.sol";

import { ReinforcedOakLumberObjectID, ReinforcedRubberLumberObjectID, ReinforcedBirchLumberObjectID, OakLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../../ObjectTypeIds.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe, createRecipeForAllLogVariationsWithInputStation } from "../../utils/RecipeUtils.sol";

contract InitWorkbenchSystem is System {
  function createTool(bytes32 toolObjectTypeId, uint16 mass, uint24 durability, uint16 damage) internal {
    ObjectTypeMetadata.set(
      toolObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: mass,
        stackable: MAX_TOOL_STACKABLE,
        durability: durability,
        damage: damage,
        hardness: 0,
        occurenceAddress: address(0),
        occurenceSelector: bytes4(0)
      })
    );
  }

  function createBlock(bytes32 terrainBlockObjectTypeId, uint16 mass, uint16 hardness) internal {
    ObjectTypeMetadata.set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        hardness: hardness,
        occurenceAddress: address(0),
        occurenceSelector: bytes4(0)
      })
    );
  }

  function initWorkbenchObjectTypes() public {
    createTool(StonePickObjectID, 36, 900, 120);
    createTool(StoneAxeObjectID, 36, 900, 120);
    createTool(StoneWhackerObjectID, 72, 10, 120);

    createTool(SilverPickObjectID, 160, 3600, 160);
    createTool(SilverAxeObjectID, 160, 3600, 160);
    createTool(SilverWhackerObjectID, 216, 15, 160);

    createTool(GoldPickObjectID, 176, 14400, 200);
    createTool(GoldAxeObjectID, 176, 14400, 200);

    createTool(DiamondPickObjectID, 196, 57600, 230);
    createTool(DiamondAxeObjectID, 196, 57600, 240);

    createTool(NeptuniumPickObjectID, 336, 230400, 280);
    createTool(NeptuniumAxeObjectID, 336, 230400, 280);

    createBlock(ReinforcedOakLumberObjectID, 3, 8);
    createBlock(ReinforcedRubberLumberObjectID, 1, 8);
    createBlock(ReinforcedBirchLumberObjectID, 3, 8);
  }

  function initWorkbenchRecipes() public {
    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, StoneObjectID, 8, StonePickObjectID, 1);
    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, StoneObjectID, 8, StoneAxeObjectID, 1);
    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 2, StoneObjectID, 4, StoneWhackerObjectID, 1);

    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, SilverBarObjectID, 4, SilverPickObjectID, 1);
    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, SilverBarObjectID, 4, SilverAxeObjectID, 1);
    createSingleInputWithStationRecipe(WorkbenchObjectID, SilverBarObjectID, 6, SilverWhackerObjectID, 1);

    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, GoldBarObjectID, 4, GoldPickObjectID, 1);
    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, GoldBarObjectID, 4, GoldAxeObjectID, 1);

    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, DiamondObjectID, 4, DiamondPickObjectID, 1);
    createRecipeForAllLogVariationsWithInputStation(WorkbenchObjectID, 4, DiamondObjectID, 4, DiamondAxeObjectID, 1);

    createRecipeForAllLogVariationsWithInputStation(
      WorkbenchObjectID,
      4,
      NeptuniumBarObjectID,
      4,
      NeptuniumPickObjectID,
      1
    );
    createRecipeForAllLogVariationsWithInputStation(
      WorkbenchObjectID,
      4,
      NeptuniumBarObjectID,
      4,
      NeptuniumAxeObjectID,
      1
    );

    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      OakLumberObjectID,
      4,
      SilverOreObjectID,
      1,
      ReinforcedOakLumberObjectID,
      4
    );
    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      BirchLumberObjectID,
      4,
      SilverOreObjectID,
      1,
      ReinforcedBirchLumberObjectID,
      4
    );
    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      RubberLumberObjectID,
      4,
      SilverOreObjectID,
      1,
      ReinforcedRubberLumberObjectID,
      4
    );
  }
}
