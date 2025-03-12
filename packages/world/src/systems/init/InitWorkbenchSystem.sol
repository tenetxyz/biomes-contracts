// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_TOOL_STACKABLE, MAX_BLOCK_STACKABLE } from "../../Constants.sol";

import { ObjectTypeId } from "../../ObjectTypeId.sol";
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

  function initWorkbenchObjectTypes() public {
    createTool(ObjectTypes.StonePick, 10000);
    createTool(ObjectTypes.StoneAxe, 10000);
    createTool(ObjectTypes.StoneWhacker, 10000);

    createTool(ObjectTypes.SilverPick, 140000);
    createTool(ObjectTypes.SilverAxe, 140000);
    createTool(ObjectTypes.SilverWhacker, 140000);
    createTool(ObjectTypes.SilverHoe, 140000);

    createTool(ObjectTypes.GoldPick, 120000);
    createTool(ObjectTypes.GoldAxe, 120000);

    createTool(ObjectTypes.DiamondPick, 190000);
    createTool(ObjectTypes.DiamondAxe, 190000);

    createTool(ObjectTypes.NeptuniumPick, 550000);
    createTool(ObjectTypes.NeptuniumAxe, 550000);

    // TODO: inlining this as it is a special case
    ObjectTypeMetadata._set(
      ObjectTypes.Bucket,
      ObjectTypeMetadataData({ stackable: 1, maxInventorySlots: 0, mass: 0, energy: 0, canPassThrough: false })
    );

    ObjectTypeMetadata._set(
      ObjectTypes.WaterBucket,
      ObjectTypeMetadataData({ stackable: 1, maxInventorySlots: 0, mass: 0, energy: 0, canPassThrough: false })
    );
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
      ObjectTypes.SilverBar,
      4,
      ObjectTypes.SilverHoe,
      1
    );

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

    createSingleInputWithStationRecipe(ObjectTypes.Workbench, ObjectTypes.AnyLog, 4, ObjectTypes.Bucket, 1);
  }
}
