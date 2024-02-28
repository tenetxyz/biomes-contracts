// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { CobblestoneBrickObjectID, StoneObjectID, StoneBrickObjectID, StoneCarvedObjectID, StonePolishedObjectID, StoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { BasaltObjectID, BasaltBrickObjectID, BasaltCarvedObjectID, BasaltPolishedObjectID, BasaltShinglesObjectID } from "../../ObjectTypeIds.sol";
import { ClayBrickObjectID, ClayCarvedObjectID, ClayPolishedObjectID, ClayShinglesObjectID } from "../../ObjectTypeIds.sol";
import { GraniteObjectID, GraniteBrickObjectID, GraniteCarvedObjectID, GraniteShinglesObjectID, GranitePolishedObjectID } from "../../ObjectTypeIds.sol";
import { QuartziteObjectID, QuartziteBrickObjectID, QuartziteCarvedObjectID, QuartzitePolishedObjectID, QuartziteShinglesObjectID } from "../../ObjectTypeIds.sol";
import { LimestoneObjectID, LimestoneBrickObjectID, LimestoneCarvedObjectID, LimestonePolishedObjectID, LimestoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { EmberstoneObjectID, SunstoneObjectID, MoonstoneObjectID, GlassObjectID, SandObjectID, DirtObjectID, CoalOreObjectID, MushroomLeatherBlockObjectID, RedMushroomObjectID } from "../../ObjectTypeIds.sol";
import { GoldBarObjectID, SilverBarObjectID, DiamondObjectID, NeptuniumBarObjectID } from "../../ObjectTypeIds.sol";
import { SilverOreObjectID, GoldOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID } from "../../ObjectTypeIds.sol";
import { GoldCubeObjectID, SilverCubeObjectID, DiamondCubeObjectID, NeptuniumCubeObjectID } from "../../ObjectTypeIds.sol";


import { createSingleInputRecipe, createDoubleInputRecipe } from "../../Utils.sol";

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
    createBlock(GraniteShinglesObjectID, 11);
    createBlock(GranitePolishedObjectID, 11);

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

    createBlock(GoldCubeObjectID, 320);
    createBlock(SilverCubeObjectID, 288);
    createBlock(DiamondCubeObjectID, 480);
    createBlock(NeptuniumCubeObjectID, 640);
  }

  function initThermoblastRecipes() public {
    createSingleInputRecipe(CobblestoneObjectID, 4, CobblestoneBrickObjectID, 4);

    createSingleInputRecipe(StoneObjectID, 4, StoneBrickObjectID, 4);
    createSingleInputRecipe(StoneObjectID, 4, StoneCarvedObjectID, 4);
    createSingleInputRecipe(StoneObjectID, 4, StonePolishedObjectID, 4);
    createSingleInputRecipe(StoneBrickObjectID, 4, StoneShinglesObjectID, 4);

    createSingleInputRecipe(BasaltObjectID, 4, BasaltBrickObjectID, 4);
    createSingleInputRecipe(BasaltBrickObjectID, 4, BasaltCarvedObjectID, 4);
    createSingleInputRecipe(BasaltBrickObjectID, 4, BasaltPolishedObjectID, 4);
    createSingleInputRecipe(BasaltBrickObjectID, 4, BasaltShinglesObjectID, 4);

    createSingleInputRecipe(ClayObjectID, 4, ClayBrickObjectID, 4);
    createSingleInputRecipe(ClayBrickObjectID, 4, ClayCarvedObjectID, 4);
    createSingleInputRecipe(ClayBrickObjectID, 4, ClayPolishedObjectID, 4);
    createSingleInputRecipe(ClayBrickObjectID, 4, ClayShinglesObjectID, 4);

    createSingleInputRecipe(GraniteObjectID, 4, GraniteBrickObjectID, 4);
    createSingleInputRecipe(GraniteBrickObjectID, 4, GraniteCarvedObjectID, 4);
    createSingleInputRecipe(GraniteBrickObjectID, 4, GraniteShinglesObjectID, 4);
    createSingleInputRecipe(GraniteBrickObjectID, 4, GranitePolishedObjectID, 4);

    createSingleInputRecipe(QuartziteObjectID, 4, QuartziteBrickObjectID, 4);
    createSingleInputRecipe(QuartziteBrickObjectID, 4, QuartziteCarvedObjectID, 4);
    createSingleInputRecipe(QuartziteBrickObjectID, 4, QuartzitePolishedObjectID, 4);
    createSingleInputRecipe(QuartziteBrickObjectID, 4, QuartziteShinglesObjectID, 4);

    createSingleInputRecipe(LimestoneObjectID, 4, LimestoneBrickObjectID, 4);
    createSingleInputRecipe(LimestoneBrickObjectID, 4, LimestoneCarvedObjectID, 4);
    createSingleInputRecipe(LimestoneBrickObjectID, 4, LimestonePolishedObjectID, 4);
    createSingleInputRecipe(LimestoneBrickObjectID, 4, LimestoneShinglesObjectID, 4);

    createDoubleInputRecipe(CoalOreObjectID, 4, StoneObjectID, 4, EmberstoneObjectID, 4);
    createDoubleInputRecipe(CoalOreObjectID, 4, QuartziteObjectID, 4, MoonstoneObjectID, 4);
    createDoubleInputRecipe(CoalOreObjectID, 4, LimestoneObjectID, 4, SunstoneObjectID, 4);

    createDoubleInputRecipe(SandObjectID, 2, CoalOreObjectID, 1, GlassObjectID, 1);

    createSingleInputRecipe(RedMushroomObjectID, 4, MushroomLeatherBlockObjectID, 1);

    createSingleInputRecipe(SilverOreObjectID, 4, SilverBarObjectID, 1);
    createSingleInputRecipe(GoldOreObjectID, 4, GoldBarObjectID, 1);
    createSingleInputRecipe(DiamondOreObjectID, 4, DiamondObjectID, 1);
    createSingleInputRecipe(NeptuniumOreObjectID, 4, NeptuniumBarObjectID, 1);

    createSingleInputRecipe(GoldBarObjectID, 8, GoldCubeObjectID, 1);
    createSingleInputRecipe(SilverBarObjectID, 8, SilverCubeObjectID, 1);
    createSingleInputRecipe(DiamondObjectID, 8, DiamondCubeObjectID, 1);
    createSingleInputRecipe(NeptuniumBarObjectID, 8, NeptuniumCubeObjectID, 1);
  }
}
