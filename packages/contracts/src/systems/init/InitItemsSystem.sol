// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../../codegen/tables/Recipes.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { GoldBarObjectID, SilverBarObjectID, DiamondObjectID, NeptuniumBarObjectID } from "../../ObjectTypeIds.sol";
import { GoldOreObjectID } from "../../ObjectTypeIds.sol";

contract InitItemsSystem is System {
  function initItemObjectTypes() public {
    ObjectTypeMetadata.set(
      GoldBarObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 40,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      SilverBarObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 36,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      DiamondObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 60,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );

    ObjectTypeMetadata.set(
      NeptuniumBarObjectID,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: 80,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );
  }

  // TODO: Make callable only once
  // TODO: Add rest of recipes
  function initItemRecipes() public {
    // Setup variables
    bytes32 stationObjectTypeId;
    bytes32[] memory inputObjectTypeIds;
    uint8[] memory inputObjectTypeAmounts;
    bytes32[] memory outputObjectTypeIds;
    uint8[] memory outputObjectTypeAmounts;
    bytes32 newRecipeId;

    // recipeGoldBar
    stationObjectTypeId = bytes32(0);

    inputObjectTypeIds = new bytes32[](1);
    inputObjectTypeIds[0] = GoldOreObjectID;
    inputObjectTypeAmounts = new uint8[](1);
    inputObjectTypeAmounts[0] = 4;

    outputObjectTypeIds = new bytes32[](1);
    outputObjectTypeIds[0] = GoldBarObjectID;
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
