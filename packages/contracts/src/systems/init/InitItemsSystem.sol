// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { GoldBarObjectID, SilverBarObjectID, DiamondObjectID, NeptuniumBarObjectID } from "../../ObjectTypeIds.sol";
import { SilverOreObjectID, GoldOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID } from "../../ObjectTypeIds.sol";
import { BlueDyeObjectID, BrownDyeObjectID, GreenDyeObjectID, MagentaDyeObjectID, OrangeDyeObjectID, PinkDyeObjectID, PurpleDyeObjectID, RedDyeObjectID, TanDyeObjectID, WhiteDyeObjectID, YellowDyeObjectID, BlackDyeObjectID, SilverDyeObjectID } from "../../ObjectTypeIds.sol";
import { BellflowerObjectID, SakuraLumberObjectID, HempObjectID, LilacObjectID, AzaleaObjectID, DaylilyObjectID, AzaleaObjectID, LilacObjectID, RoseObjectID, SandObjectID, CottonBushObjectID, DandelionObjectID, NeptuniumOreObjectID, SilverOreObjectID } from "../../ObjectTypeIds.sol";

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

    createItem(BlueDyeObjectID, 1);
    createItem(BrownDyeObjectID, 1);
    createItem(GreenDyeObjectID, 1);
    createItem(MagentaDyeObjectID, 1);
    createItem(OrangeDyeObjectID, 1);
    createItem(PinkDyeObjectID, 1);
    createItem(PurpleDyeObjectID, 1);
    createItem(RedDyeObjectID, 1);
    createItem(TanDyeObjectID, 1);
    createItem(WhiteDyeObjectID, 1);
    createItem(YellowDyeObjectID, 1);
    createItem(BlackDyeObjectID, 1);
    createItem(SilverDyeObjectID, 1);
  }

  function initItemRecipes() public {
    createSingleInputRecipe(SilverOreObjectID, 4, SilverBarObjectID, 1);
    createSingleInputRecipe(GoldOreObjectID, 4, GoldBarObjectID, 1);
    createSingleInputRecipe(DiamondOreObjectID, 4, DiamondObjectID, 1);
    createSingleInputRecipe(NeptuniumOreObjectID, 4, NeptuniumBarObjectID, 1);

    createSingleInputRecipe(BellflowerObjectID, 10, BlueDyeObjectID, 10);
    createSingleInputRecipe(SakuraLumberObjectID, 10, BrownDyeObjectID, 10);
    createSingleInputRecipe(HempObjectID, 10, GreenDyeObjectID, 10);
    createSingleInputRecipe(DaylilyObjectID, 10, OrangeDyeObjectID, 10);
    createSingleInputRecipe(AzaleaObjectID, 10, PinkDyeObjectID, 10);
    createSingleInputRecipe(LilacObjectID, 10, PurpleDyeObjectID, 10);
    createSingleInputRecipe(RoseObjectID, 10, RedDyeObjectID, 10);
    createSingleInputRecipe(SandObjectID, 5, TanDyeObjectID, 10);
    createSingleInputRecipe(CottonBushObjectID, 2, WhiteDyeObjectID, 8);
    createSingleInputRecipe(DandelionObjectID, 10, YellowDyeObjectID, 10);
    createSingleInputRecipe(SilverOreObjectID, 1, SilverDyeObjectID, 9);
    createSingleInputRecipe(NeptuniumOreObjectID, 1, BlackDyeObjectID, 20);

    createDoubleInputRecipe(LilacObjectID, 5, AzaleaObjectID, 5, MagentaDyeObjectID, 10);
  }
}
