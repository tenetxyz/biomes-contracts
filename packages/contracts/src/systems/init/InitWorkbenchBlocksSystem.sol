// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
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

  function initWorkbenchTwoObjectTypes() public {
    createWorkbenchBlock(GoldCubeObjectID, 320);
    createWorkbenchBlock(SilverCubeObjectID, 288);
    createWorkbenchBlock(DiamondCubeObjectID, 480);
    createWorkbenchBlock(NeptuniumCubeObjectID, 640);
  }

  function initWorkbenchTwoRecipes() public {
    createSingleInputRecipe(GoldBarObjectID, 8, GoldCubeObjectID, 1);
    createSingleInputRecipe(SilverBarObjectID, 8, SilverCubeObjectID, 1);
    createSingleInputRecipe(DiamondObjectID, 8, DiamondCubeObjectID, 1);
    createSingleInputRecipe(NeptuniumBarObjectID, 8, NeptuniumCubeObjectID, 1);
  }
}
