// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { TerrainMetadata, TerrainMetadataData } from "../../codegen/tables/TerrainMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { AirObjectID, SnowObjectID, AsphaltObjectID, BasaltObjectID, ClayBrickObjectID, SandObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, SoilObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, LavaObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID } from "../../ObjectTypeIds.sol";
import { CoalOreObjectID, GoldOreObjectID, SilverOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../../ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, MossGrassObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID } from "../../ObjectTypeIds.sol";

contract InitTerrainBlocksSystem is System {
  function createTerrainBlock(
    bytes32 terrainBlockObjectTypeId,
    uint16 mass,
    address systemAddress,
    bytes4 terrainSelector
  ) internal {
    ObjectTypeMetadata._set(
      terrainBlockObjectTypeId,
      ObjectTypeMetadataData({
        isPlayer: false,
        isBlock: true,
        mass: mass,
        stackable: MAX_BLOCK_STACKABLE,
        durability: 0,
        damage: 0,
        hardness: 1
      })
    );

    TerrainMetadata._set(
      terrainBlockObjectTypeId,
      TerrainMetadataData({ occurenceAddress: systemAddress, occurenceSelector: terrainSelector })
    );
  }

  function initTerrainBlockObjectTypes() public {
    // TODO: replace any block selector with the one for the block to save gas
    bytes4 terrainBlocksWorldSelector = IWorld(_world()).TerrainBlocks.selector;
    ResourceId terrainSystemId = FunctionSelectors._getSystemId(terrainBlocksWorldSelector);
    bytes4 terrainBlocksSelector = FunctionSelectors._getSystemFunctionSelector(terrainBlocksWorldSelector);
    address terrainSystemAddress = Systems._getSystem(terrainSystemId);

    bytes4 treeWorldSelector = IWorld(_world()).Trees.selector;
    bytes4 treeSelector = FunctionSelectors._getSystemFunctionSelector(treeWorldSelector);
    bytes4 floraWorldSelector = IWorld(_world()).Flora.selector;
    bytes4 floraSelector = FunctionSelectors._getSystemFunctionSelector(floraWorldSelector);

    bytes4 oresWorldSelector = IWorld(_world()).Ores.selector;
    ResourceId terrainOreSystemId = FunctionSelectors._getSystemId(oresWorldSelector);
    address terrainOreSystemAddress = Systems._getSystem(terrainOreSystemId);
    bytes4 oresSelector = FunctionSelectors._getSystemFunctionSelector(oresWorldSelector);

    createTerrainBlock(AirObjectID, 0, terrainSystemAddress, IWorld(_world()).Air.selector);
    createTerrainBlock(GrassObjectID, 4, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(MuckGrassObjectID, 4, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(DirtObjectID, 4, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(MuckDirtObjectID, 4, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(MossBlockObjectID, 4, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(GravelObjectID, 5, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(SandObjectID, 2, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(BedrockObjectID, 1000, terrainSystemAddress, terrainBlocksSelector);

    createTerrainBlock(StoneObjectID, 7, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(BasaltObjectID, 9, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(GraniteObjectID, 11, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(QuartziteObjectID, 10, terrainSystemAddress, terrainBlocksSelector);
    createTerrainBlock(LimestoneObjectID, 7, terrainSystemAddress, terrainBlocksSelector);

    createTerrainBlock(CactusObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(LilacObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(DandelionObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(RedMushroomObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(BellflowerObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(CottonBushObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(MossGrassObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(SwitchGrassObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(DaylilyObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(AzaleaObjectID, 1, terrainSystemAddress, floraSelector);
    createTerrainBlock(RoseObjectID, 1, terrainSystemAddress, floraSelector);

    createTerrainBlock(OakLogObjectID, 4, terrainSystemAddress, treeSelector);
    createTerrainBlock(BirchLogObjectID, 4, terrainSystemAddress, treeSelector);
    createTerrainBlock(SakuraLogObjectID, 4, terrainSystemAddress, treeSelector);
    createTerrainBlock(RubberLogObjectID, 4, terrainSystemAddress, treeSelector);
    createTerrainBlock(OakLeafObjectID, 1, terrainSystemAddress, treeSelector);
    createTerrainBlock(BirchLeafObjectID, 1, terrainSystemAddress, treeSelector);
    createTerrainBlock(SakuraLeafObjectID, 1, terrainSystemAddress, treeSelector);
    createTerrainBlock(RubberLeafObjectID, 1, terrainSystemAddress, treeSelector);

    createTerrainBlock(CoalOreObjectID, 7, terrainOreSystemAddress, oresSelector);
    createTerrainBlock(GoldOreObjectID, 10, terrainOreSystemAddress, oresSelector);
    createTerrainBlock(SilverOreObjectID, 9, terrainOreSystemAddress, oresSelector);
    createTerrainBlock(DiamondOreObjectID, 15, terrainOreSystemAddress, oresSelector);
    createTerrainBlock(NeptuniumOreObjectID, 20, terrainOreSystemAddress, oresSelector);
  }
}
