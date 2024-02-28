// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { GoldCubeObjectID, SilverCubeObjectID, DiamondCubeObjectID, NeptuniumCubeObjectID, OakLumberObjectID, ReinforcedOakLumberObjectID, SakuraLumberObjectID, RubberLumberObjectID, ReinforcedRubberLumberObjectID, BirchLumberObjectID, ReinforcedBirchLumberObjectID, MushroomLeatherBlockObjectID } from "../../ObjectTypeIds.sol";
import { SilverOreObjectID, GoldBarObjectID, SilverBarObjectID, DiamondObjectID, NeptuniumBarObjectID, OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createRecipeForAllLogVariations } from "../../Utils.sol";

contract InitWorkbenchBlocksSystem is System {
  function createWorkbenchBlock(bytes32 terrainBlockObjectTypeId, uint16 mass) internal {
    ObjectTypeMetadata.set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );
  }

  function initWorkbenchObjectTypes() public {
    createWorkbenchBlock(GoldCubeObjectID, 320);
    createWorkbenchBlock(SilverCubeObjectID, 288);
    createWorkbenchBlock(DiamondCubeObjectID, 480);
    createWorkbenchBlock(NeptuniumCubeObjectID, 640);

    createWorkbenchBlock(OakLumberObjectID, 1);
    createWorkbenchBlock(ReinforcedOakLumberObjectID, 3);
    createWorkbenchBlock(SakuraLumberObjectID, 1);
    createWorkbenchBlock(RubberLumberObjectID, 1);
    createWorkbenchBlock(ReinforcedRubberLumberObjectID, 1);
    createWorkbenchBlock(BirchLumberObjectID, 1);
    createWorkbenchBlock(ReinforcedBirchLumberObjectID, 3);
  }

  function initWorkbenchRecipes() public {
    createSingleInputRecipe(GoldBarObjectID, 8, GoldCubeObjectID, 1);
    createSingleInputRecipe(SilverBarObjectID, 8, SilverCubeObjectID, 1);
    createSingleInputRecipe(DiamondObjectID, 8, DiamondCubeObjectID, 1);
    createSingleInputRecipe(NeptuniumBarObjectID, 8, NeptuniumCubeObjectID, 1);

    createSingleInputRecipe(OakLogObjectID, 1, OakLumberObjectID, 4);
    createSingleInputRecipe(SakuraLogObjectID, 1, SakuraLumberObjectID, 4);
    createSingleInputRecipe(BirchLogObjectID, 1, BirchLumberObjectID, 4);
    createSingleInputRecipe(RubberLogObjectID, 1, RubberLumberObjectID, 4);

    createDoubleInputRecipe(OakLumberObjectID, 4, SilverOreObjectID, 1, ReinforcedOakLumberObjectID, 4);
    createDoubleInputRecipe(BirchLumberObjectID, 4, SilverOreObjectID, 1, ReinforcedBirchLumberObjectID, 4);
    createDoubleInputRecipe(RubberLumberObjectID, 4, SilverOreObjectID, 1, ReinforcedRubberLumberObjectID, 4);
  }
}
