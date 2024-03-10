// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { AirObjectID, SnowObjectID, AsphaltObjectID, BasaltObjectID, ClayBrickObjectID, SandObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, SoilObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, LavaObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID } from "../../ObjectTypeIds.sol";
import { CoalOreObjectID, GoldOreObjectID, SilverOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../../ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, MossGrassObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID } from "../../ObjectTypeIds.sol";

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
        hardness: 1,
        occurence: terrainSelector
      })
    );
  }

  function initTerrainBlockObjectTypes() public {
    // TODO: replace any block selector with the one for the block to save gas
    bytes4 terrainBlocksSelector = IWorld(_world()).TerrainBlocks.selector;
    bytes4 treeSelector = IWorld(_world()).Trees.selector;
    bytes4 floraSelector = IWorld(_world()).Flora.selector;
    bytes4 oresSelector = IWorld(_world()).Ores.selector;

    createTerrainBlock(AirObjectID, 0, IWorld(_world()).Air.selector);
    createTerrainBlock(GrassObjectID, 4, terrainBlocksSelector);
    createTerrainBlock(MuckGrassObjectID, 4, terrainBlocksSelector);
    createTerrainBlock(DirtObjectID, 4, terrainBlocksSelector);
    createTerrainBlock(MuckDirtObjectID, 4, terrainBlocksSelector);
    createTerrainBlock(MossBlockObjectID, 4, terrainBlocksSelector);
    createTerrainBlock(GravelObjectID, 5, terrainBlocksSelector);
    createTerrainBlock(SandObjectID, 2, terrainBlocksSelector);
    createTerrainBlock(BedrockObjectID, 1000, terrainBlocksSelector);

    createTerrainBlock(StoneObjectID, 7, terrainBlocksSelector);
    createTerrainBlock(BasaltObjectID, 9, terrainBlocksSelector);
    createTerrainBlock(GraniteObjectID, 11, terrainBlocksSelector);
    createTerrainBlock(QuartziteObjectID, 10, terrainBlocksSelector);
    createTerrainBlock(LimestoneObjectID, 7, terrainBlocksSelector);

    createTerrainBlock(CactusObjectID, 1, floraSelector);
    createTerrainBlock(LilacObjectID, 1, floraSelector);
    createTerrainBlock(DandelionObjectID, 1, floraSelector);
    createTerrainBlock(RedMushroomObjectID, 1, floraSelector);
    createTerrainBlock(BellflowerObjectID, 1, floraSelector);
    createTerrainBlock(CottonBushObjectID, 1, floraSelector);
    createTerrainBlock(MossGrassObjectID, 1, floraSelector);
    createTerrainBlock(SwitchGrassObjectID, 1, floraSelector);
    createTerrainBlock(DaylilyObjectID, 1, floraSelector);
    createTerrainBlock(AzaleaObjectID, 1, floraSelector);
    createTerrainBlock(RoseObjectID, 1, floraSelector);

    createTerrainBlock(OakLogObjectID, 4, treeSelector);
    createTerrainBlock(BirchLogObjectID, 4, treeSelector);
    createTerrainBlock(SakuraLogObjectID, 4, treeSelector);
    createTerrainBlock(RubberLogObjectID, 4, treeSelector);
    createTerrainBlock(OakLeafObjectID, 1, treeSelector);
    createTerrainBlock(BirchLeafObjectID, 1, treeSelector);
    createTerrainBlock(SakuraLeafObjectID, 1, treeSelector);
    createTerrainBlock(RubberLeafObjectID, 1, treeSelector);

    createTerrainBlock(CoalOreObjectID, 7, oresSelector);
    createTerrainBlock(GoldOreObjectID, 10, oresSelector);
    createTerrainBlock(SilverOreObjectID, 9, oresSelector);
    createTerrainBlock(DiamondOreObjectID, 15, oresSelector);
    createTerrainBlock(NeptuniumOreObjectID, 20, oresSelector);
  }
}
