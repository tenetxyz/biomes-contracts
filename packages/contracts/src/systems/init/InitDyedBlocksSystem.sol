// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";

import { OakLumberObjectID, BlueOakLumberObjectID, BrownOakLumberObjectID, GreenOakLumberObjectID, MagentaOakLumberObjectID, OrangeOakLumberObjectID, PinkOakLumberObjectID, PurpleOakLumberObjectID, RedOakLumberObjectID, TanOakLumberObjectID, WhiteOakLumberObjectID, YellowOakLumberObjectID, BlackOakLumberObjectID, SilverOakLumberObjectID } from "../../ObjectTypeIds.sol";
import { CottonBlockObjectID, BlueCottonBlockObjectID, BrownCottonBlockObjectID, GreenCottonBlockObjectID, MagentaCottonBlockObjectID, OrangeCottonBlockObjectID, PinkCottonBlockObjectID, PurpleCottonBlockObjectID, RedCottonBlockObjectID, TanCottonBlockObjectID, WhiteCottonBlockObjectID, YellowCottonBlockObjectID, BlackCottonBlockObjectID, SilverCottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { GlassObjectID, BlueGlassObjectID, BrownGlassObjectID, GreenGlassObjectID, MagentaGlassObjectID, OrangeGlassObjectID, PinkGlassObjectID, PurpleGlassObjectID, RedGlassObjectID, TanGlassObjectID, WhiteGlassObjectID, YellowGlassObjectID, BlackGlassObjectID, SilverGlassObjectID } from "../../ObjectTypeIds.sol";
import { BlueDyeObjectID, BrownDyeObjectID, GreenDyeObjectID, MagentaDyeObjectID, OrangeDyeObjectID, PinkDyeObjectID, PurpleDyeObjectID, RedDyeObjectID, TanDyeObjectID, WhiteDyeObjectID, YellowDyeObjectID, BlackDyeObjectID, SilverDyeObjectID } from "../../ObjectTypeIds.sol";

import { DyeomaticObjectID } from "../../ObjectTypeIds.sol";
import { createDoubleInputWithStationRecipe } from "../../Utils.sol";

contract InitDyedBlocksSystem is System {
  function createDyedBlock(bytes32 terrainBlockObjectTypeId, uint16 mass) internal {
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

  function initDyedObjectTypes() public {
    createDyedBlock(BlueOakLumberObjectID, 2);
    createDyedBlock(BrownOakLumberObjectID, 2);
    createDyedBlock(GreenOakLumberObjectID, 2);
    createDyedBlock(MagentaOakLumberObjectID, 2);
    createDyedBlock(OrangeOakLumberObjectID, 2);
    createDyedBlock(PinkOakLumberObjectID, 2);
    createDyedBlock(PurpleOakLumberObjectID, 2);
    createDyedBlock(RedOakLumberObjectID, 2);
    createDyedBlock(TanOakLumberObjectID, 2);
    createDyedBlock(WhiteOakLumberObjectID, 2);
    createDyedBlock(YellowOakLumberObjectID, 2);
    createDyedBlock(BlackOakLumberObjectID, 2);
    createDyedBlock(SilverOakLumberObjectID, 2);

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

    createDyedBlock(BlueGlassObjectID, 5);
    createDyedBlock(BrownGlassObjectID, 5);
    createDyedBlock(GreenGlassObjectID, 5);
    createDyedBlock(MagentaGlassObjectID, 5);
    createDyedBlock(OrangeGlassObjectID, 5);
    createDyedBlock(PinkGlassObjectID, 5);
    createDyedBlock(PurpleGlassObjectID, 5);
    createDyedBlock(RedGlassObjectID, 5);
    createDyedBlock(TanGlassObjectID, 5);
    createDyedBlock(WhiteGlassObjectID, 5);
    createDyedBlock(YellowGlassObjectID, 5);
    createDyedBlock(BlackGlassObjectID, 5);
    createDyedBlock(SilverGlassObjectID, 5);
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
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, BrownDyeObjectID, 1, BrownGlassObjectID, 1);
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, GreenDyeObjectID, 1, GreenGlassObjectID, 1);
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      GlassObjectID,
      1,
      MagentaDyeObjectID,
      1,
      MagentaGlassObjectID,
      1
    );
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
    createDoubleInputWithStationRecipe(DyeomaticObjectID, GlassObjectID, 1, TanDyeObjectID, 1, TanGlassObjectID, 1);
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
    createDoubleInputWithStationRecipe(
      DyeomaticObjectID,
      GlassObjectID,
      1,
      SilverDyeObjectID,
      1,
      SilverGlassObjectID,
      1
    );
  }
}
