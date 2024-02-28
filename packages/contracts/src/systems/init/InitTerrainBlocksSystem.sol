// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { AirObjectID, SnowObjectID, AsphaltObjectID, BasaltObjectID, ClayBrickObjectID, SandObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, SoilObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, LavaObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID } from "../../ObjectTypeIds.sol";
import { CoalOreObjectID, GoldOreObjectID, SilverOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID, CottonObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../../ObjectTypeIds.sol";
import { HempObjectID, LilacObjectID, DandelionObjectID, MuckshroomObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, MossGrassObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID } from "../../ObjectTypeIds.sol";

contract InitTerrainBlocksSystem is System {
  function createTerrainBlock(bytes32 terrainBlockObjectTypeId, uint16 mass, bytes4 terrainSelector) internal {
    ObjectTypeMetadata.set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        occurence: terrainSelector
      })
    );
  }

  function initTerrainBlockObjectTypes() public {
    // TODO: replace any block selector with the one for the block to save gas
    bytes4 anyBlockSelector = IWorld(_world()).getTerrainBlock.selector;

    createTerrainBlock(AirObjectID, 0, anyBlockSelector);
    createTerrainBlock(GrassObjectID, 4, anyBlockSelector);
    createTerrainBlock(MuckGrassObjectID, 4, anyBlockSelector);
    createTerrainBlock(DirtObjectID, 4, anyBlockSelector);
    createTerrainBlock(MuckDirtObjectID, 4, anyBlockSelector);
    createTerrainBlock(MossBlockObjectID, 4, anyBlockSelector);
    createTerrainBlock(SnowObjectID, 1, anyBlockSelector);
    createTerrainBlock(GravelObjectID, 5, anyBlockSelector);
    createTerrainBlock(AsphaltObjectID, 8, anyBlockSelector);
    createTerrainBlock(SoilObjectID, 3, anyBlockSelector);
    createTerrainBlock(SandObjectID, 2, anyBlockSelector);
    createTerrainBlock(BedrockObjectID, 1000, anyBlockSelector);

    createTerrainBlock(StoneObjectID, 7, anyBlockSelector);
    createTerrainBlock(BasaltObjectID, 9, anyBlockSelector);
    createTerrainBlock(GraniteObjectID, 11, anyBlockSelector);
    createTerrainBlock(QuartziteObjectID, 10, anyBlockSelector);
    createTerrainBlock(LimestoneObjectID, 7, anyBlockSelector);

    createTerrainBlock(CottonObjectID, 1, anyBlockSelector);
    createTerrainBlock(LavaObjectID, 2, anyBlockSelector);

    createTerrainBlock(HempObjectID, 1, anyBlockSelector);
    createTerrainBlock(LilacObjectID, 1, anyBlockSelector);
    createTerrainBlock(DandelionObjectID, 1, anyBlockSelector);
    createTerrainBlock(MuckshroomObjectID, 1, anyBlockSelector);
    createTerrainBlock(RedMushroomObjectID, 1, anyBlockSelector);
    createTerrainBlock(BellflowerObjectID, 1, anyBlockSelector);
    createTerrainBlock(CottonBushObjectID, 1, anyBlockSelector);
    createTerrainBlock(MossGrassObjectID, 1, anyBlockSelector);
    createTerrainBlock(SwitchGrassObjectID, 1, anyBlockSelector);
    createTerrainBlock(DaylilyObjectID, 1, anyBlockSelector);
    createTerrainBlock(AzaleaObjectID, 1, anyBlockSelector);
    createTerrainBlock(RoseObjectID, 1, anyBlockSelector);

    createTerrainBlock(OakLogObjectID, 4, anyBlockSelector);
    createTerrainBlock(BirchLogObjectID, 4, anyBlockSelector);
    createTerrainBlock(SakuraLogObjectID, 4, anyBlockSelector);
    createTerrainBlock(RubberLogObjectID, 4, anyBlockSelector);
    createTerrainBlock(OakLeafObjectID, 1, anyBlockSelector);
    createTerrainBlock(BirchLeafObjectID, 1, anyBlockSelector);
    createTerrainBlock(SakuraLeafObjectID, 1, anyBlockSelector);
    createTerrainBlock(RubberLeafObjectID, 1, anyBlockSelector);

    createTerrainBlock(CoalOreObjectID, 7, anyBlockSelector);
    createTerrainBlock(GoldOreObjectID, 10, anyBlockSelector);
    createTerrainBlock(SilverOreObjectID, 9, anyBlockSelector);
    createTerrainBlock(DiamondOreObjectID, 15, anyBlockSelector);
    createTerrainBlock(NeptuniumOreObjectID, 20, anyBlockSelector);
  }
}
