// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { AirObjectID, SnowObjectID, BasaltObjectID, ClayBrickObjectID, SandObjectID, StoneObjectID, EmberstoneObjectID, CobblestoneObjectID, MoonstoneObjectID, GraniteObjectID, QuartziteObjectID, LimestoneObjectID, SunstoneObjectID, GravelObjectID, ClayObjectID, BedrockObjectID, LavaObjectID, GrassObjectID, MuckGrassObjectID, DirtObjectID, MuckDirtObjectID, MossBlockObjectID } from "../../ObjectTypeIds.sol";
import { CoalOreObjectID, GoldOreObjectID, SilverOreObjectID, DiamondOreObjectID, NeptuniumOreObjectID, CottonBlockObjectID } from "../../ObjectTypeIds.sol";
import { OakLogObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, OakLeafObjectID, BirchLeafObjectID, SakuraLeafObjectID, RubberLeafObjectID } from "../../ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID } from "../../ObjectTypeIds.sol";

contract InitTerrainBlocksSystem is System {
  function createTerrainBlock(bytes32 terrainBlockObjectTypeId, uint16 mass) internal {
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
  }

  function initTerrainBlockObjectTypes() public {
    createTerrainBlock(AirObjectID, 0);
    createTerrainBlock(GrassObjectID, 4);
    createTerrainBlock(MuckGrassObjectID, 4);
    createTerrainBlock(DirtObjectID, 4);
    createTerrainBlock(MuckDirtObjectID, 4);
    createTerrainBlock(MossBlockObjectID, 4);
    createTerrainBlock(GravelObjectID, 5);
    createTerrainBlock(SandObjectID, 2);
    createTerrainBlock(BedrockObjectID, 1000);

    createTerrainBlock(StoneObjectID, 7);
    createTerrainBlock(BasaltObjectID, 9);
    createTerrainBlock(GraniteObjectID, 11);
    createTerrainBlock(QuartziteObjectID, 10);
    createTerrainBlock(LimestoneObjectID, 7);

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

    createTerrainBlock(OakLogObjectID, 4);
    createTerrainBlock(BirchLogObjectID, 4);
    createTerrainBlock(SakuraLogObjectID, 4);
    createTerrainBlock(RubberLogObjectID, 4);
    createTerrainBlock(OakLeafObjectID, 1);
    createTerrainBlock(BirchLeafObjectID, 1);
    createTerrainBlock(SakuraLeafObjectID, 1);
    createTerrainBlock(RubberLeafObjectID, 1);

    createTerrainBlock(CoalOreObjectID, 7);
    createTerrainBlock(GoldOreObjectID, 10);
    createTerrainBlock(SilverOreObjectID, 9);
    createTerrainBlock(DiamondOreObjectID, 15);
    createTerrainBlock(NeptuniumOreObjectID, 20);
  }
}
