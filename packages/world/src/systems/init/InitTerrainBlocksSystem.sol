// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { AirObjectID, WaterObjectID, SnowObjectID, BasaltObjectID, ClayBrickObjectID, SandObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, GrassObjectID, DirtObjectID, MossBlockObjectID, LavaObjectID } from "../../ObjectTypeIds.sol";
import { CoalOreObjectID, GoldOreObjectID, SilverOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../../ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID } from "../../ObjectTypeIds.sol";
import { ObjectTypeId } from "../../ObjectTypeIds.sol";

contract InitTerrainBlocksSystem is System {
  function createTerrainBlock(ObjectTypeId terrainBlockObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        stackable: MAX_BLOCK_STACKABLE,
        maxInventorySlots: 0,
        mass: mass,
        energy: 0,
        canPassThrough: false
      })
    );
  }

  function createPassableTerrainBlock(ObjectTypeId terrainBlockObjectTypeId, uint32 mass) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        stackable: MAX_BLOCK_STACKABLE,
        maxInventorySlots: type(uint16).max,
        mass: mass,
        energy: 0,
        canPassThrough: true
      })
    );
  }

  function initTerrainBlockObjectTypes() public {
    createPassableTerrainBlock(AirObjectID, 0);
    createPassableTerrainBlock(WaterObjectID, 0);
    createTerrainBlock(LavaObjectID, 115);
    createTerrainBlock(GrassObjectID, 12);
    createTerrainBlock(DirtObjectID, 40);
    createTerrainBlock(MossBlockObjectID, 35);
    createTerrainBlock(SnowObjectID, 40);
    createTerrainBlock(GravelObjectID, 5);
    createTerrainBlock(SandObjectID, 35);
    createTerrainBlock(BedrockObjectID, 1000);

    createTerrainBlock(StoneObjectID, 50);
    createTerrainBlock(BasaltObjectID, 60);
    createTerrainBlock(GraniteObjectID, 65);
    createTerrainBlock(QuartziteObjectID, 70);
    createTerrainBlock(LimestoneObjectID, 35);

    createTerrainBlock(CactusObjectID, 1);
    createTerrainBlock(LilacObjectID, 1);
    createTerrainBlock(DandelionObjectID, 1);
    createTerrainBlock(RedMushroomObjectID, 1);
    createTerrainBlock(BellflowerObjectID, 1);
    createTerrainBlock(CottonBushObjectID, 1);
    createTerrainBlock(SwitchGrassObjectID, 1);
    createTerrainBlock(DaylilyObjectID, 1);
    createTerrainBlock(AzaleaObjectID, 1);
    createTerrainBlock(RoseObjectID, 1);

    createTerrainBlock(OakLogObjectID, 20);
    createTerrainBlock(BirchLogObjectID, 20);
    createTerrainBlock(SakuraLogObjectID, 20);
    createTerrainBlock(RubberLogObjectID, 20);
    createTerrainBlock(OakLeafObjectID, 1);
    createTerrainBlock(BirchLeafObjectID, 1);
    createTerrainBlock(SakuraLeafObjectID, 1);
    createTerrainBlock(RubberLeafObjectID, 1);

    createTerrainBlock(CoalOreObjectID, 80);
    createTerrainBlock(GoldOreObjectID, 200);
    createTerrainBlock(SilverOreObjectID, 120);
    createTerrainBlock(DiamondOreObjectID, 350);
    createTerrainBlock(NeptuniumOreObjectID, 500);
  }
}
