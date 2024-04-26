// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../../codegen/tables/Recipes.sol";

import { MAX_TOOL_STACKABLE, MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { SilverOreObjectID, StonePickObjectID, StoneAxeObjectID, StoneWhackerObjectID, SilverPickObjectID, SilverAxeObjectID, SilverWhackerObjectID, GoldPickObjectID, GoldAxeObjectID, NeptuniumPickObjectID, NeptuniumAxeObjectID, DiamondPickObjectID, DiamondAxeObjectID } from "../../ObjectTypeIds.sol";
import { AnyLogObjectID, OakLogObjectID, SakuraLogObjectID, RubberLogObjectID, BirchLogObjectID, SilverBarObjectID, GoldBarObjectID, DiamondObjectID, NeptuniumBarObjectID, StoneObjectID } from "../../ObjectTypeIds.sol";

import { ReinforcedOakLumberObjectID, ReinforcedRubberLumberObjectID, ReinforcedBirchLumberObjectID, OakLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../../ObjectTypeIds.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitWorkbenchSystem is System {
  function createTool(uint8 toolObjectTypeId, uint24 durability, uint16 damage) internal {
    ObjectTypeMetadata._set(
      toolObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: false,
        isTool: true,
        miningDifficulty: 0,
        stackable: MAX_TOOL_STACKABLE,
        durability: durability,
        damage: damage
      })
    );
  }

  function createBlock(uint8 terrainBlockObjectTypeId, uint16 miningDifficulty) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: true,
        isTool: false,
        miningDifficulty: miningDifficulty,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0
      })
    );
  }

  function initWorkbenchObjectTypes() public {
    createTool(StonePickObjectID, 900, 120);
    createTool(StoneAxeObjectID, 900, 120);
    createTool(StoneWhackerObjectID, 10, 120);

    createTool(SilverPickObjectID, 3600, 160);
    createTool(SilverAxeObjectID, 3600, 160);
    createTool(SilverWhackerObjectID, 15, 160);

    createTool(GoldPickObjectID, 14400, 200);
    createTool(GoldAxeObjectID, 14400, 200);

    createTool(DiamondPickObjectID, 57600, 230);
    createTool(DiamondAxeObjectID, 57600, 240);

    createTool(NeptuniumPickObjectID, 230400, 280);
    createTool(NeptuniumAxeObjectID, 230400, 280);

    createBlock(ReinforcedOakLumberObjectID, 24);
    createBlock(ReinforcedRubberLumberObjectID, 8);
    createBlock(ReinforcedBirchLumberObjectID, 24);
  }

  function initWorkbenchRecipes() public {
    createDoubleInputWithStationRecipe(WorkbenchObjectID, AnyLogObjectID, 4, StoneObjectID, 8, StonePickObjectID, 1);
    createDoubleInputWithStationRecipe(WorkbenchObjectID, AnyLogObjectID, 4, StoneObjectID, 8, StoneAxeObjectID, 1);
    createDoubleInputWithStationRecipe(WorkbenchObjectID, AnyLogObjectID, 2, StoneObjectID, 4, StoneWhackerObjectID, 1);

    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      AnyLogObjectID,
      4,
      SilverBarObjectID,
      4,
      SilverPickObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      AnyLogObjectID,
      4,
      SilverBarObjectID,
      4,
      SilverAxeObjectID,
      1
    );
    createSingleInputWithStationRecipe(WorkbenchObjectID, SilverBarObjectID, 6, SilverWhackerObjectID, 1);

    createDoubleInputWithStationRecipe(WorkbenchObjectID, AnyLogObjectID, 4, GoldBarObjectID, 4, GoldPickObjectID, 1);
    createDoubleInputWithStationRecipe(WorkbenchObjectID, AnyLogObjectID, 4, GoldBarObjectID, 4, GoldAxeObjectID, 1);

    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      AnyLogObjectID,
      4,
      DiamondObjectID,
      4,
      DiamondPickObjectID,
      1
    );
    createDoubleInputWithStationRecipe(WorkbenchObjectID, AnyLogObjectID, 4, DiamondObjectID, 4, DiamondAxeObjectID, 1);

    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      AnyLogObjectID,
      4,
      NeptuniumBarObjectID,
      4,
      NeptuniumPickObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      WorkbenchObjectID,
      AnyLogObjectID,
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
