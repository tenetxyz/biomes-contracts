// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { AirObjectID, WaterObjectID, SnowObjectID, BasaltObjectID, ClayBrickObjectID, SandObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID, LavaObjectID } from "../../ObjectTypeIds.sol";
import { CoalOreObjectID, GoldOreObjectID, SilverOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../../ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID } from "../../ObjectTypeIds.sol";

contract InitTerrainBlocksSystem is System {
  function createTerrainBlock(uint8 terrainBlockObjectTypeId, uint16 miningDifficulty) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isBlock: true,
        isTool: false,
        miningDifficulty: miningDifficulty,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0
      })
    );
  }

  function initTerrainBlockObjectTypes() public {
    createTerrainBlock(AirObjectID, 0);
    createTerrainBlock(WaterObjectID, 0);
    createTerrainBlock(LavaObjectID, 115);
    createTerrainBlock(GrassObjectID, 12);
    // createTerrainBlock(MuckGrassObjectID, 4);
    createTerrainBlock(DirtObjectID, 40);
    // createTerrainBlock(MuckDirtObjectID, 4);
    createTerrainBlock(MossBlockObjectID, 35);
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
    // createTerrainBlock(SwitchGrassObjectID, 1);
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
