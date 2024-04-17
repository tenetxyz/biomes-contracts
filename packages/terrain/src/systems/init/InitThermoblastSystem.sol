// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { CobblestoneObjectID, CobblestoneBrickObjectID, CobblestoneCarvedObjectID, CobblestonePolishedObjectID, CobblestoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { StoneObjectID, StoneBrickObjectID, StoneCarvedObjectID, StonePolishedObjectID, StoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { BasaltObjectID, BasaltBrickObjectID, BasaltCarvedObjectID, BasaltPolishedObjectID, BasaltShinglesObjectID } from "../../ObjectTypeIds.sol";
import { ClayObjectID, ClayBrickObjectID, ClayCarvedObjectID, ClayPolishedObjectID, ClayShinglesObjectID } from "../../ObjectTypeIds.sol";
import { GraniteObjectID, GraniteBrickObjectID, GraniteCarvedObjectID, GraniteShinglesObjectID, GranitePolishedObjectID } from "../../ObjectTypeIds.sol";
import { QuartziteObjectID, QuartziteBrickObjectID, QuartziteCarvedObjectID, QuartzitePolishedObjectID, QuartziteShinglesObjectID } from "../../ObjectTypeIds.sol";
import { LimestoneObjectID, LimestoneBrickObjectID, LimestoneCarvedObjectID, LimestonePolishedObjectID, LimestoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { EmberstoneObjectID, SunstoneObjectID, MoonstoneObjectID, GlassObjectID, SandObjectID, DirtObjectID, CoalOreObjectID, MushroomLeatherBlockObjectID, RedMushroomObjectID } from "../../ObjectTypeIds.sol";
import { GoldBarObjectID, SilverBarObjectID, DiamondObjectID, NeptuniumBarObjectID } from "../../ObjectTypeIds.sol";
import { SilverOreObjectID, GoldOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID } from "../../ObjectTypeIds.sol";
import { GoldCubeObjectID, SilverCubeObjectID, DiamondCubeObjectID, NeptuniumCubeObjectID } from "../../ObjectTypeIds.sol";

import { ThermoblasterObjectID } from "../../ObjectTypeIds.sol";
import { createSingleInputWithStationRecipe, createDoubleInputWithStationRecipe } from "../../utils/RecipeUtils.sol";

contract InitThermoblastSystem is System {
  function createBlock(uint8 terrainBlockObjectTypeId, uint16 miningDifficulty) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: true,
        miningDifficulty: miningDifficulty,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0
      })
    );
  }

  function createItem(uint8 itemObjectTypeId) internal {
    ObjectTypeMetadata._set(
      itemObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: false,
        miningDifficulty: 0,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0
      })
    );
  }

  function initThermoblastObjectTypes() public {
    createBlock(CobblestoneBrickObjectID, 84);
    createBlock(CobblestoneCarvedObjectID, 84);
    createBlock(CobblestonePolishedObjectID, 84);
    createBlock(CobblestoneShinglesObjectID, 84);

    createBlock(StoneBrickObjectID, 84);
    createBlock(StoneCarvedObjectID, 84);
    createBlock(StonePolishedObjectID, 84);
    createBlock(StoneShinglesObjectID, 84);

    createBlock(BasaltBrickObjectID, 132);
    createBlock(BasaltCarvedObjectID, 132);
    createBlock(BasaltPolishedObjectID, 132);
    createBlock(BasaltShinglesObjectID, 132);

    createBlock(ClayBrickObjectID, 192);
    createBlock(ClayCarvedObjectID, 192);
    createBlock(ClayPolishedObjectID, 192);
    createBlock(ClayShinglesObjectID, 192);

    createBlock(GraniteBrickObjectID, 132);
    createBlock(GraniteCarvedObjectID, 132);
    createBlock(GranitePolishedObjectID, 132);
    createBlock(GraniteShinglesObjectID, 132);

    createBlock(QuartziteBrickObjectID, 120);
    createBlock(QuartziteCarvedObjectID, 120);
    createBlock(QuartzitePolishedObjectID, 120);
    createBlock(QuartziteShinglesObjectID, 120);

    createBlock(LimestoneBrickObjectID, 84);
    createBlock(LimestoneCarvedObjectID, 84);
    createBlock(LimestonePolishedObjectID, 84);
    createBlock(LimestoneShinglesObjectID, 84);

    createBlock(EmberstoneObjectID, 14);
    createBlock(MoonstoneObjectID, 17);
    createBlock(SunstoneObjectID, 14);

    createBlock(GlassObjectID, 11);
    createBlock(MushroomLeatherBlockObjectID, 8);

    createItem(SilverBarObjectID);
    createItem(GoldBarObjectID);
    createItem(DiamondObjectID);
    createItem(NeptuniumBarObjectID);

    createBlock(SilverCubeObjectID, 4608);
    createBlock(GoldCubeObjectID, 6400);
    createBlock(DiamondCubeObjectID, 11520);
    createBlock(NeptuniumCubeObjectID, 17920);
  }

  function initThermoblastRecipes() public {
    createSingleInputWithStationRecipe(ThermoblasterObjectID, CobblestoneObjectID, 4, CobblestoneBrickObjectID, 4);
    createSingleInputWithStationRecipe(
      ThermoblasterObjectID,
      CobblestoneBrickObjectID,
      4,
      CobblestoneCarvedObjectID,
      4
    );
    createSingleInputWithStationRecipe(
      ThermoblasterObjectID,
      CobblestoneBrickObjectID,
      4,
      CobblestonePolishedObjectID,
      4
    );
    createSingleInputWithStationRecipe(
      ThermoblasterObjectID,
      CobblestoneBrickObjectID,
      4,
      CobblestoneShinglesObjectID,
      4
    );

    createSingleInputWithStationRecipe(ThermoblasterObjectID, StoneObjectID, 4, StoneBrickObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, StoneObjectID, 4, StoneCarvedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, StoneObjectID, 4, StonePolishedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, StoneBrickObjectID, 4, StoneShinglesObjectID, 4);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, BasaltObjectID, 4, BasaltBrickObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, BasaltBrickObjectID, 4, BasaltCarvedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, BasaltBrickObjectID, 4, BasaltPolishedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, BasaltBrickObjectID, 4, BasaltShinglesObjectID, 4);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, ClayObjectID, 4, ClayBrickObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, ClayBrickObjectID, 4, ClayCarvedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, ClayBrickObjectID, 4, ClayPolishedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, ClayBrickObjectID, 4, ClayShinglesObjectID, 4);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, GraniteObjectID, 4, GraniteBrickObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, GraniteBrickObjectID, 4, GraniteCarvedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, GraniteBrickObjectID, 4, GraniteShinglesObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, GraniteBrickObjectID, 4, GranitePolishedObjectID, 4);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, QuartziteObjectID, 4, QuartziteBrickObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, QuartziteBrickObjectID, 4, QuartziteCarvedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, QuartziteBrickObjectID, 4, QuartzitePolishedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, QuartziteBrickObjectID, 4, QuartziteShinglesObjectID, 4);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, LimestoneObjectID, 4, LimestoneBrickObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, LimestoneBrickObjectID, 4, LimestoneCarvedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, LimestoneBrickObjectID, 4, LimestonePolishedObjectID, 4);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, LimestoneBrickObjectID, 4, LimestoneShinglesObjectID, 4);

    createDoubleInputWithStationRecipe(
      ThermoblasterObjectID,
      CoalOreObjectID,
      4,
      StoneObjectID,
      4,
      EmberstoneObjectID,
      4
    );
    createDoubleInputWithStationRecipe(
      ThermoblasterObjectID,
      CoalOreObjectID,
      4,
      QuartziteObjectID,
      4,
      MoonstoneObjectID,
      4
    );
    createDoubleInputWithStationRecipe(
      ThermoblasterObjectID,
      CoalOreObjectID,
      4,
      LimestoneObjectID,
      4,
      SunstoneObjectID,
      4
    );

    createDoubleInputWithStationRecipe(ThermoblasterObjectID, SandObjectID, 2, CoalOreObjectID, 1, GlassObjectID, 1);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, RedMushroomObjectID, 4, MushroomLeatherBlockObjectID, 1);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, SilverOreObjectID, 4, SilverBarObjectID, 1);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, GoldOreObjectID, 4, GoldBarObjectID, 1);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, DiamondOreObjectID, 4, DiamondObjectID, 1);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, NeptuniumOreObjectID, 4, NeptuniumBarObjectID, 1);

    createSingleInputWithStationRecipe(ThermoblasterObjectID, GoldBarObjectID, 8, GoldCubeObjectID, 1);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, SilverBarObjectID, 8, SilverCubeObjectID, 1);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, DiamondObjectID, 8, DiamondCubeObjectID, 1);
    createSingleInputWithStationRecipe(ThermoblasterObjectID, NeptuniumBarObjectID, 8, NeptuniumCubeObjectID, 1);
  }
}
