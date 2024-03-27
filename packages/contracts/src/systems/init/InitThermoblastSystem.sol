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
  function createBlock(bytes32 terrainBlockObjectTypeId, uint16 mass, uint16 hardness) internal {
    ObjectTypeMetadata.set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        hardness: hardness
      })
    );
  }

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
        hardness: 0
      })
    );
  }

  function initThermoblastObjectTypes() public {
    createBlock(CobblestoneBrickObjectID, 7, 12);
    createBlock(CobblestoneCarvedObjectID, 7, 12);
    createBlock(CobblestonePolishedObjectID, 7, 12);
    createBlock(CobblestoneShinglesObjectID, 7, 12);

    createBlock(StoneBrickObjectID, 7, 12);
    createBlock(StoneCarvedObjectID, 7, 12);
    createBlock(StonePolishedObjectID, 7, 12);
    createBlock(StoneShinglesObjectID, 7, 12);

    createBlock(BasaltBrickObjectID, 10, 12);
    createBlock(BasaltCarvedObjectID, 11, 12);
    createBlock(BasaltPolishedObjectID, 11, 12);
    createBlock(BasaltShinglesObjectID, 11, 12);

    createBlock(ClayBrickObjectID, 16, 12);
    createBlock(ClayCarvedObjectID, 16, 12);
    createBlock(ClayPolishedObjectID, 16, 12);
    createBlock(ClayShinglesObjectID, 16, 12);

    createBlock(GraniteBrickObjectID, 11, 12);
    createBlock(GraniteCarvedObjectID, 11, 12);
    createBlock(GranitePolishedObjectID, 11, 12);
    createBlock(GraniteShinglesObjectID, 11, 12);

    createBlock(QuartziteBrickObjectID, 10, 12);
    createBlock(QuartziteCarvedObjectID, 10, 12);
    createBlock(QuartzitePolishedObjectID, 10, 12);
    createBlock(QuartziteShinglesObjectID, 10, 12);

    createBlock(LimestoneBrickObjectID, 7, 12);
    createBlock(LimestoneCarvedObjectID, 7, 12);
    createBlock(LimestonePolishedObjectID, 7, 12);
    createBlock(LimestoneShinglesObjectID, 7, 12);

    createBlock(EmberstoneObjectID, 14, 1);
    createBlock(MoonstoneObjectID, 17, 1);
    createBlock(SunstoneObjectID, 14, 1);

    createBlock(GlassObjectID, 11, 1);
    createBlock(MushroomLeatherBlockObjectID, 8, 1);

    createItem(SilverBarObjectID, 36);
    createItem(GoldBarObjectID, 40);
    createItem(DiamondObjectID, 60);
    createItem(NeptuniumBarObjectID, 80);

    createBlock(SilverCubeObjectID, 288, 16);
    createBlock(GoldCubeObjectID, 320, 20);
    createBlock(DiamondCubeObjectID, 480, 24);
    createBlock(NeptuniumCubeObjectID, 640, 28);
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
