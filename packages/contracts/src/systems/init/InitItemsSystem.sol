// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { GoldBarObjectID, SilverBarObjectID, DiamondObjectID, NeptuniumBarObjectID } from "../../ObjectTypeIds.sol";
import { SilverOreObjectID, GoldOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe } from "../../Utils.sol";

contract InitItemsSystem is System {
  function createItem(bytes32 itemObjectTypeId, uint16 mass) internal {
    ObjectTypeMetadata.set(
      itemObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: false,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: bytes4(0)
      })
    );
  }

  function initItemObjectTypes() public {
    createItem(SilverBarObjectID, 36);
    createItem(GoldBarObjectID, 40);
    createItem(DiamondObjectID, 60);
    createItem(NeptuniumBarObjectID, 80);
  }

  function initItemRecipes() public {
    createSingleInputRecipe(SilverOreObjectID, 4, SilverBarObjectID, 1);
    createSingleInputRecipe(GoldOreObjectID, 4, GoldBarObjectID, 1);
    createSingleInputRecipe(DiamondOreObjectID, 4, DiamondObjectID, 1);
    createSingleInputRecipe(NeptuniumOreObjectID, 4, NeptuniumBarObjectID, 1);
  }
}
