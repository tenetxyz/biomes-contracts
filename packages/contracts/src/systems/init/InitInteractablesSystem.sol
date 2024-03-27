// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { WorkbenchObjectID } from "../../ObjectTypeIds.sol";

import { ChestObjectID, ThermoblasterObjectID, WorkbenchObjectID, DyeomaticObjectID } from "../../ObjectTypeIds.sol";
import { StoneObjectID, ClayObjectID, SandObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe, createRecipeForAllLumberVariations, createRecipeForAllLogVariations, createRecipeForAllLumberVariationsWithInputStation } from "../../utils/RecipeUtils.sol";

contract InitInteractablesSystem is System {
  function createInteractableBlock(bytes32 terrainBlockObjectTypeId, uint16 mass) internal {
    ObjectTypeMetadata.set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: mass,
        stackable: 1,
        durability: 0,
        damage: 0,
        hardness: 1
      })
    );
  }

  function initInteractableObjectTypes() public {
    createInteractableBlock(ChestObjectID, 8);
    createInteractableBlock(ThermoblasterObjectID, 63);
    createInteractableBlock(WorkbenchObjectID, 20);
    createInteractableBlock(DyeomaticObjectID, 72);
  }

  function initInteractablesRecipes() public {
    createRecipeForAllLumberVariationsWithInputStation(WorkbenchObjectID, 8, ChestObjectID, 1);
    createRecipeForAllLogVariations(5, WorkbenchObjectID, 1);
    createSingleInputRecipe(StoneObjectID, 9, ThermoblasterObjectID, 1);
    createDoubleInputRecipe(ClayObjectID, 4, SandObjectID, 4, DyeomaticObjectID, 1);
  }
}
