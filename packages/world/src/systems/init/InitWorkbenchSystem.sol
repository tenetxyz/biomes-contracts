// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_TOOL_STACKABLE, MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { SilverOreObjectID, StonePickObjectID, StoneAxeObjectID, StoneWhackerObjectID, SilverPickObjectID, SilverAxeObjectID, SilverWhackerObjectID, GoldPickObjectID, GoldAxeObjectID, NeptuniumPickObjectID, NeptuniumAxeObjectID, DiamondPickObjectID, DiamondAxeObjectID } from "../../ObjectTypeIds.sol";
import { AnyLogObjectID, OakLogObjectID, SakuraLogObjectID, RubberLogObjectID, BirchLogObjectID, SilverBarObjectID, GoldBarObjectID, DiamondObjectID, NeptuniumBarObjectID, StoneObjectID } from "../../ObjectTypeIds.sol";

import { ReinforcedOakLumberObjectID, ReinforcedRubberLumberObjectID, ReinforcedBirchLumberObjectID, OakLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../../ObjectTypeIds.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";
import { ObjectTypeId } from "../../ObjectTypeIds.sol";

import { createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitWorkbenchSystem is System {
  function createTool(ObjectTypeId toolObjectTypeId, uint32 mass) internal {
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

  function createBlock(ObjectTypeId terrainBlockObjectTypeId, uint32 mass) internal {
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

  function initWorkbenchObjectTypes() public {
    createTool(StonePickObjectID, 100000);
    createTool(StoneAxeObjectID, 100000);
    createTool(StoneWhackerObjectID, 100000);

    createTool(SilverPickObjectID, 1400000);
    createTool(SilverAxeObjectID, 1400000);
    createTool(SilverWhackerObjectID, 1400000);

    createTool(GoldPickObjectID, 1200000);
    createTool(GoldAxeObjectID, 1200000);

    createTool(DiamondPickObjectID, 1900000);
    createTool(DiamondAxeObjectID, 1900000);

    createTool(NeptuniumPickObjectID, 5500000);
    createTool(NeptuniumAxeObjectID, 5500000);

    createBlock(ReinforcedOakLumberObjectID, 140);
    createBlock(ReinforcedRubberLumberObjectID, 140);
    createBlock(ReinforcedBirchLumberObjectID, 140);
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
