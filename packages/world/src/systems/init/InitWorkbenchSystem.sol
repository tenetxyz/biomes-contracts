// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_TOOL_STACKABLE, MAX_BLOCK_STACKABLE } from "../../Constants.sol";

import { ObjectTypeId } from "../../ObjectTypeIds.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";

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
    createTool(ObjectTypes.StonePick, 100000);
    createTool(ObjectTypes.StoneAxe, 100000);
    createTool(ObjectTypes.StoneWhacker, 100000);

    createTool(ObjectTypes.SilverPick, 1400000);
    createTool(ObjectTypes.SilverAxe, 1400000);
    createTool(ObjectTypes.SilverWhacker, 1400000);

    createTool(ObjectTypes.GoldPick, 1200000);
    createTool(ObjectTypes.GoldAxe, 1200000);

    createTool(ObjectTypes.DiamondPick, 1900000);
    createTool(ObjectTypes.DiamondAxe, 1900000);

    createTool(ObjectTypes.NeptuniumPick, 5500000);
    createTool(ObjectTypes.NeptuniumAxe, 5500000);
  }

  function initWorkbenchRecipes() public {
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.Stone,
      8,
      ObjectTypes.StonePick,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.Stone,
      8,
      ObjectTypes.StoneAxe,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      2,
      ObjectTypes.Stone,
      4,
      ObjectTypes.StoneWhacker,
      1
    );

    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.SilverBar,
      4,
      ObjectTypes.SilverPick,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.SilverBar,
      4,
      ObjectTypes.SilverAxe,
      1
    );
    createSingleInputWithStationRecipe(ObjectTypes.Workbench, ObjectTypes.SilverBar, 6, ObjectTypes.SilverWhacker, 1);

    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.GoldBar,
      4,
      ObjectTypes.GoldPick,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.GoldBar,
      4,
      ObjectTypes.GoldAxe,
      1
    );

    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.Diamond,
      4,
      ObjectTypes.DiamondPick,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.Diamond,
      4,
      ObjectTypes.DiamondAxe,
      1
    );

    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.NeptuniumBar,
      4,
      ObjectTypes.NeptuniumPick,
      1
    );
    createDoubleInputWithStationRecipe(
      ObjectTypes.Workbench,
      ObjectTypes.AnyLog,
      4,
      ObjectTypes.NeptuniumBar,
      4,
      ObjectTypes.NeptuniumAxe,
      1
    );
  }
}
