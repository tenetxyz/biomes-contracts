// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectCategory } from "../../codegen/common.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";

import { ObjectTypeId } from "../../ObjectTypeIds.sol";
import { OakLumberObjectID, BlueOakLumberObjectID, BrownOakLumberObjectID, GreenOakLumberObjectID, MagentaOakLumberObjectID, OrangeOakLumberObjectID, PinkOakLumberObjectID, PurpleOakLumberObjectID, RedOakLumberObjectID, TanOakLumberObjectID, WhiteOakLumberObjectID, YellowOakLumberObjectID, BlackOakLumberObjectID, SilverOakLumberObjectID } from "../../ObjectTypeIds.sol";
import { CottonBlockObjectID, BlueCottonBlockObjectID, BrownCottonBlockObjectID, GreenCottonBlockObjectID, MagentaCottonBlockObjectID, OrangeCottonBlockObjectID, PinkCottonBlockObjectID, PurpleCottonBlockObjectID, RedCottonBlockObjectID, TanCottonBlockObjectID, WhiteCottonBlockObjectID, YellowCottonBlockObjectID, BlackCottonBlockObjectID, SilverCottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { GlassObjectID, BlueGlassObjectID, GreenGlassObjectID, OrangeGlassObjectID, PinkGlassObjectID, PurpleGlassObjectID, RedGlassObjectID, WhiteGlassObjectID, YellowGlassObjectID, BlackGlassObjectID } from "../../ObjectTypeIds.sol";
import { BlueDyeObjectID, BrownDyeObjectID, GreenDyeObjectID, MagentaDyeObjectID, OrangeDyeObjectID, PinkDyeObjectID, PurpleDyeObjectID, RedDyeObjectID, TanDyeObjectID, WhiteDyeObjectID, YellowDyeObjectID, BlackDyeObjectID, SilverDyeObjectID } from "../../ObjectTypeIds.sol";

import { DyeomaticObjectID } from "../../ObjectTypeIds.sol";
import { createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitDyedBlocksSystem is System {
  function createDyedBlock(ObjectTypeId terrainBlockObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        objectCategory: ObjectCategory.Block,
        stackable: MAX_BLOCK_STACKABLE,
        maxInventorySlots: 0,
        mass: mass,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function initDyedObjectTypes() public {
    createDyedBlock(BlueOakLumberObjectID, 20);
    createDyedBlock(BrownOakLumberObjectID, 20);
    createDyedBlock(GreenOakLumberObjectID, 20);
    createDyedBlock(MagentaOakLumberObjectID, 20);
    createDyedBlock(OrangeOakLumberObjectID, 20);
    createDyedBlock(PinkOakLumberObjectID, 20);
    createDyedBlock(PurpleOakLumberObjectID, 20);
    createDyedBlock(RedOakLumberObjectID, 20);
    createDyedBlock(TanOakLumberObjectID, 20);
    createDyedBlock(WhiteOakLumberObjectID, 20);
    createDyedBlock(YellowOakLumberObjectID, 20);
    createDyedBlock(BlackOakLumberObjectID, 20);
    createDyedBlock(SilverOakLumberObjectID, 20);

    createDyedBlock(BlueCottonBlockObjectID, 5);
    createDyedBlock(BrownCottonBlockObjectID, 5);
    createDyedBlock(GreenCottonBlockObjectID, 5);
    createDyedBlock(MagentaCottonBlockObjectID, 5);
    createDyedBlock(OrangeCottonBlockObjectID, 5);
    createDyedBlock(PinkCottonBlockObjectID, 5);
    createDyedBlock(PurpleCottonBlockObjectID, 5);
    createDyedBlock(RedCottonBlockObjectID, 5);
    createDyedBlock(TanCottonBlockObjectID, 5);
    createDyedBlock(WhiteCottonBlockObjectID, 5);
    createDyedBlock(YellowCottonBlockObjectID, 5);
    createDyedBlock(BlackCottonBlockObjectID, 5);
    createDyedBlock(SilverCottonBlockObjectID, 5);

    createDyedBlock(BlueGlassObjectID, 7);
    createDyedBlock(GreenGlassObjectID, 7);
    createDyedBlock(OrangeGlassObjectID, 7);
    createDyedBlock(PinkGlassObjectID, 7);
    createDyedBlock(PurpleGlassObjectID, 7);
    createDyedBlock(RedGlassObjectID, 7);
    createDyedBlock(WhiteGlassObjectID, 7);
    createDyedBlock(YellowGlassObjectID, 7);
    createDyedBlock(BlackGlassObjectID, 7);
  }

  function initDyedRecipes() public {
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      BlueDyeObjectID,
      1,
      BlueOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      BrownDyeObjectID,
      1,
      BrownOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      GreenDyeObjectID,
      1,
      GreenOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      MagentaDyeObjectID,
      1,
      MagentaOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      OrangeDyeObjectID,
      1,
      OrangeOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      PinkDyeObjectID,
      1,
      PinkOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      PurpleDyeObjectID,
      1,
      PurpleOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      RedDyeObjectID,
      1,
      RedOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      TanDyeObjectID,
      1,
      TanOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      WhiteDyeObjectID,
      1,
      WhiteOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      YellowDyeObjectID,
      1,
      YellowOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      BlackDyeObjectID,
      1,
      BlackOakLumberObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      OakLumberObjectID,
      1,
      SilverDyeObjectID,
      1,
      SilverOakLumberObjectID,
      1
    );

    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      BlueDyeObjectID,
      1,
      BlueCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      BrownDyeObjectID,
      1,
      BrownCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      GreenDyeObjectID,
      1,
      GreenCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      MagentaDyeObjectID,
      1,
      MagentaCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      OrangeDyeObjectID,
      1,
      OrangeCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      PinkDyeObjectID,
      1,
      PinkCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      PurpleDyeObjectID,
      1,
      PurpleCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      RedDyeObjectID,
      1,
      RedCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      TanDyeObjectID,
      1,
      TanCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      WhiteDyeObjectID,
      1,
      WhiteCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      YellowDyeObjectID,
      1,
      YellowCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      BlackDyeObjectID,
      1,
      BlackCottonBlockObjectID,
      1
    );
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      CottonBlockObjectID,
      1,
      SilverDyeObjectID,
      1,
      SilverCottonBlockObjectID,
      1
    );

    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, BlueDyeObjectID, 1, BlueGlassObjectID, 1);
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, GreenDyeObjectID, 1, GreenGlassObjectID, 1);
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      GlassObjectID,
      1,
      OrangeDyeObjectID,
      1,
      OrangeGlassObjectID,
      1
    );
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, PinkDyeObjectID, 1, PinkGlassObjectID, 1);
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      GlassObjectID,
      1,
      PurpleDyeObjectID,
      1,
      PurpleGlassObjectID,
      1
    );
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, RedDyeObjectID, 1, RedGlassObjectID, 1);
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, WhiteDyeObjectID, 1, WhiteGlassObjectID, 1);
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      GlassObjectID,
      1,
      YellowDyeObjectID,
      1,
      YellowGlassObjectID,
      1
    );
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, BlackDyeObjectID, 1, BlackGlassObjectID, 1);
  }
}
