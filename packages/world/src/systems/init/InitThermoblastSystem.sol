// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE, MAX_ITEM_STACKABLE } from "../../Constants.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";

import { createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitThermoblastSystem is System {
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

  function createItem(ObjectTypeId itemObjectTypeId) internal {
    ObjectTypeMetadata._set(
      itemObjectTypeId,
      ObjectTypeMetadataData({
        stackable: MAX_ITEM_STACKABLE,
        maxInventorySlots: 0,
        mass: 0,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function initThermoblastObjectTypes() public {
    createItem(ObjectTypes.SilverBar);
    createItem(ObjectTypes.GoldBar);
    createItem(ObjectTypes.Diamond);
    createItem(ObjectTypes.NeptuniumBar);
    createItem(ObjectTypes.ChipBattery);
  }

  function initThermoblastRecipes() public {
    createSingleInputWithStationRecipe(ObjectTypes.Thermoblaster, ObjectTypes.SilverOre, 1, ObjectTypes.SilverBar, 1);
    createSingleInputWithStationRecipe(ObjectTypes.Thermoblaster, ObjectTypes.GoldOre, 1, ObjectTypes.GoldBar, 1);
    createSingleInputWithStationRecipe(ObjectTypes.Thermoblaster, ObjectTypes.DiamondOre, 1, ObjectTypes.Diamond, 1);
    createSingleInputWithStationRecipe(
      ObjectTypes.Thermoblaster,
      ObjectTypes.NeptuniumOre,
      1,
      ObjectTypes.NeptuniumBar,
      1
    );
  }
}
