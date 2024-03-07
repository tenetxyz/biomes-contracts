// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { CobblestoneObjectID, CobblestoneBrickObjectID, StoneObjectID, StoneBrickObjectID, StoneCarvedObjectID, StonePolishedObjectID, StoneShinglesObjectID } from "../../ObjectTypeIds.sol";
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
  function createBlock(bytes32 terrainBlockObjectTypeId, uint16 mass) internal {
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

  function initThermoblastObjectTypes() public {
    createBlock(CobblestoneBrickObjectID, 7);

    createBlock(StoneBrickObjectID, 7);
    createBlock(StoneCarvedObjectID, 7);
    createBlock(StonePolishedObjectID, 7);
    createBlock(StoneShinglesObjectID, 7);

    createBlock(BasaltBrickObjectID, 10);
    createBlock(BasaltCarvedObjectID, 11);
    createBlock(BasaltPolishedObjectID, 11);
    createBlock(BasaltShinglesObjectID, 11);

    createBlock(ClayBrickObjectID, 16);
    createBlock(ClayCarvedObjectID, 16);
    createBlock(ClayPolishedObjectID, 16);
    createBlock(ClayShinglesObjectID, 16);

    createBlock(GraniteBrickObjectID, 11);
    createBlock(GraniteCarvedObjectID, 11);
    createBlock(GranitePolishedObjectID, 11);
    createBlock(GraniteShinglesObjectID, 11);

    createBlock(QuartziteBrickObjectID, 10);
    createBlock(QuartziteCarvedObjectID, 10);
    createBlock(QuartzitePolishedObjectID, 10);
    createBlock(QuartziteShinglesObjectID, 10);

    createBlock(LimestoneBrickObjectID, 7);
    createBlock(LimestoneCarvedObjectID, 7);
    createBlock(LimestonePolishedObjectID, 7);
    createBlock(LimestoneShinglesObjectID, 7);

    createBlock(EmberstoneObjectID, 14);
    createBlock(MoonstoneObjectID, 17);
    createBlock(SunstoneObjectID, 14);

    createBlock(GlassObjectID, 11);
    createBlock(MushroomLeatherBlockObjectID, 8);

    createItem(SilverBarObjectID, 36);
    createItem(GoldBarObjectID, 40);
    createItem(DiamondObjectID, 60);
    createItem(NeptuniumBarObjectID, 80);

    createBlock(SilverCubeObjectID, 288);
    createBlock(GoldCubeObjectID, 320);
    createBlock(DiamondCubeObjectID, 480);
    createBlock(NeptuniumCubeObjectID, 640);
  }

  function initThermoblastRecipes() public {
    createSingleInputWithStationRecipe(ThermoblasterObjectID, CobblestoneObjectID, 4, CobblestoneBrickObjectID, 4);

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
