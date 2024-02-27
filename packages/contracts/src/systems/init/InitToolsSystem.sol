// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../../codegen/tables/Recipes.sol";

import { MAX_TOOL_STACKABLE, WoodenPickObjectID, WoodenAxeObjectID, WoodenWhackerObjectID, StonePickObjectID, StoneAxeObjectID, StoneWhackerObjectID, SilverPickObjectID, SilverAxeObjectID, SilverWhackerObjectID, GoldPickObjectID, GoldAxeObjectID, NeptuniumPickObjectID, NeptuniumAxeObjectID, DiamondPickObjectID, DiamondAxeObjectID } from "../../Constants.sol";
import { OakLogObjectID } from "../../Constants.sol";

contract InitToolsSystem is System {

  // TODO: add durability and damage values
  function initToolObjectTypes() public {
    ObjectTypeMetadata.set(
      WoodenPickObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 16,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      WoodenAxeObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 16,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      WoodenWhackerObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 32,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      StonePickObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 36,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      StoneAxeObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 36,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      StoneWhackerObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 72,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      SilverPickObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 160,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      SilverAxeObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 160,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      SilverWhackerObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 216,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      GoldPickObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 176,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      GoldAxeObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 176,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      DiamondPickObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 196,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      DiamondAxeObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 196,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      NeptuniumPickObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 336,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      NeptuniumAxeObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 336,
        stackable: MAX_TOOL_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );
  }

  // TODO: Make callable only once
  // TODO: Add rest of recipes
  function initToolRecipes() public {
    // Setup variables
    bytes32 stationObjectTypeId;
    bytes32[] memory inputObjectTypeIds;
    uint8[] memory inputObjectTypeAmounts;
    bytes32[] memory outputObjectTypeIds;
    uint8[] memory outputObjectTypeAmounts;
    bytes32 newRecipeId;

    // Wooden Pickaxe
    stationObjectTypeId = bytes32(0);

    // Recipe inputs
    inputObjectTypeIds = new bytes32[](1);
    inputObjectTypeIds[0] = OakLogObjectID;
    inputObjectTypeAmounts = new uint8[](1);
    inputObjectTypeAmounts[0] = 4;

    // Recipe outputs
    outputObjectTypeIds = new bytes32[](1);
    outputObjectTypeIds[0] = WoodenPickObjectID;
    outputObjectTypeAmounts = new uint8[](1);
    outputObjectTypeAmounts[0] = 1;

    newRecipeId = getUniqueEntity();
    Recipes.set(
      newRecipeId,
      RecipesData({
        stationObjectTypeId: stationObjectTypeId,
        inputObjectTypeIds: inputObjectTypeIds,
        inputObjectTypeAmounts: inputObjectTypeAmounts,
        outputObjectTypeIds: outputObjectTypeIds,
        outputObjectTypeAmounts: outputObjectTypeAmounts
      })
    );
  }
}
