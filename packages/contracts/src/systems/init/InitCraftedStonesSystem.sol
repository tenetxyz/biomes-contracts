// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { CobblestoneObjectID, CobblestoneBrickObjectID, StoneObjectID, StoneBrickObjectID, StoneCarvedObjectID, StonePolishedObjectID, StoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { BasaltObjectID, BasaltBrickObjectID, BasaltCarvedObjectID, BasaltPolishedObjectID, BasaltShinglesObjectID } from "../../ObjectTypeIds.sol";
import { ClayObjectID, ClayBrickObjectID, ClayCarvedObjectID, ClayPolishedObjectID, ClayShinglesObjectID } from "../../ObjectTypeIds.sol";
import { GraniteObjectID, GraniteBrickObjectID, GraniteCarvedObjectID, GraniteShinglesObjectID, GranitePolishedObjectID } from "../../ObjectTypeIds.sol";
import { QuartziteObjectID, QuartziteBrickObjectID, QuartziteCarvedObjectID, QuartzitePolishedObjectID, QuartziteShinglesObjectID } from "../../ObjectTypeIds.sol";
import { LimestoneObjectID, LimestoneBrickObjectID, LimestoneCarvedObjectID, LimestonePolishedObjectID, LimestoneShinglesObjectID } from "../../ObjectTypeIds.sol";
import { EmberstoneObjectID, SunstoneObjectID, MoonstoneObjectID, GlassObjectID, SandObjectID, DirtObjectID, CoalOreObjectID, MushroomLeatherBlockObjectID, RedMushroomObjectID } from "../../ObjectTypeIds.sol";

import { createSingleInputRecipe, createDoubleInputRecipe } from "../../Utils.sol";

contract InitCraftedStonesSystem is System {
  function createCraftedBlock(bytes32 terrainBlockObjectTypeId, uint16 mass) internal {
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

  function initCraftedStoneObjectTypes() public {
    createCraftedBlock(CobblestoneBrickObjectID, 7);

    createCraftedBlock(StoneBrickObjectID, 7);
    createCraftedBlock(StoneCarvedObjectID, 7);
    createCraftedBlock(StonePolishedObjectID, 7);
    createCraftedBlock(StoneShinglesObjectID, 7);

    createCraftedBlock(BasaltBrickObjectID, 10);
    createCraftedBlock(BasaltCarvedObjectID, 11);
    createCraftedBlock(BasaltPolishedObjectID, 11);
    createCraftedBlock(BasaltShinglesObjectID, 11);

    createCraftedBlock(ClayBrickObjectID, 16);
    createCraftedBlock(ClayCarvedObjectID, 16);
    createCraftedBlock(ClayPolishedObjectID, 16);
    createCraftedBlock(ClayShinglesObjectID, 16);

    createCraftedBlock(GraniteBrickObjectID, 11);
    createCraftedBlock(GraniteCarvedObjectID, 11);
    createCraftedBlock(GraniteShinglesObjectID, 11);
    createCraftedBlock(GranitePolishedObjectID, 11);

    createCraftedBlock(QuartziteBrickObjectID, 10);
    createCraftedBlock(QuartziteCarvedObjectID, 10);
    createCraftedBlock(QuartzitePolishedObjectID, 10);
    createCraftedBlock(QuartziteShinglesObjectID, 10);

    createCraftedBlock(LimestoneBrickObjectID, 7);
    createCraftedBlock(LimestoneCarvedObjectID, 7);
    createCraftedBlock(LimestonePolishedObjectID, 7);
    createCraftedBlock(LimestoneShinglesObjectID, 7);
  }

  function initCraftedStoneRecipes() public {
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
    createDoubleInputRecipe(SandObjectID, 2, CoalOreObjectID, 1, GlassObjectID, 1);
    createDoubleInputRecipe(CoalOreObjectID, 4, QuartziteObjectID, 4, MoonstoneObjectID, 4);
    createDoubleInputRecipe(CoalOreObjectID, 4, LimestoneObjectID, 4, SunstoneObjectID, 4);

    createSingleInputRecipe(DirtObjectID, 4, ClayObjectID, 4);
    createSingleInputRecipe(StoneObjectID, 1, CobbleStoneObjectID, 4);
    createSingleInputRecipe(RedMushroomObjectID, 4, MushroomLeatherBlockObjectID, 1);
  }
}
