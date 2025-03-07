// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_BLOCK_STACKABLE } from "../../Constants.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
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
    createPassableTerrainBlock(ObjectTypes.Air, 0);
    createPassableTerrainBlock(ObjectTypes.Water, 0);
    createTerrainBlock(ObjectTypes.Stone, 100);
    createTerrainBlock(ObjectTypes.Bedrock, 100);
    createTerrainBlock(ObjectTypes.Deepslate, 100);
    createTerrainBlock(ObjectTypes.Granite, 100);
    createTerrainBlock(ObjectTypes.Tuff, 100);
    createTerrainBlock(ObjectTypes.Calcite, 100);
    createTerrainBlock(ObjectTypes.SmoothBasalt, 100);
    createTerrainBlock(ObjectTypes.Andesite, 100);
    createTerrainBlock(ObjectTypes.Diorite, 100);
    createTerrainBlock(ObjectTypes.Cobblestone, 100);
    createTerrainBlock(ObjectTypes.MossyCobblestone, 100);
    createTerrainBlock(ObjectTypes.Obsidian, 100);
    createTerrainBlock(ObjectTypes.Dripstone, 100);
    createTerrainBlock(ObjectTypes.Amethyst, 100);
    createTerrainBlock(ObjectTypes.Glowstone, 100);
    createTerrainBlock(ObjectTypes.Grass, 100);
    createTerrainBlock(ObjectTypes.Dirt, 100);
    createTerrainBlock(ObjectTypes.Moss, 100);
    createTerrainBlock(ObjectTypes.Podzol, 100);
    createTerrainBlock(ObjectTypes.Gravel, 100);
    createTerrainBlock(ObjectTypes.Sand, 100);
    createTerrainBlock(ObjectTypes.RedSand, 100);
    createTerrainBlock(ObjectTypes.Sandstone, 100);
    createTerrainBlock(ObjectTypes.Clay, 100);
    createTerrainBlock(ObjectTypes.Terracotta, 100);
    createTerrainBlock(ObjectTypes.BrownTerracotta, 100);
    createTerrainBlock(ObjectTypes.OrangeTerracotta, 100);
    createTerrainBlock(ObjectTypes.WhiteTerracotta, 100);
    createTerrainBlock(ObjectTypes.LightGrayTerracotta, 100);
    createTerrainBlock(ObjectTypes.YellowTerracotta, 100);
    createTerrainBlock(ObjectTypes.RedTerracotta, 100);
    createTerrainBlock(ObjectTypes.OakLog, 100);
    createTerrainBlock(ObjectTypes.BirchLog, 100);
    createTerrainBlock(ObjectTypes.JungleLog, 100);
    createTerrainBlock(ObjectTypes.SakuraLog, 100);
    createTerrainBlock(ObjectTypes.AcaciaLog, 100);
    createTerrainBlock(ObjectTypes.SpruceLog, 100);
    createTerrainBlock(ObjectTypes.DarkOakLog, 100);
    createTerrainBlock(ObjectTypes.OakLeaf, 100);
    createTerrainBlock(ObjectTypes.BirchLeaf, 100);
    createTerrainBlock(ObjectTypes.JungleLeaf, 100);
    createTerrainBlock(ObjectTypes.SakuraLeaf, 100);
    createTerrainBlock(ObjectTypes.AcaciaLeaf, 100);
    createTerrainBlock(ObjectTypes.SpruceLeaf, 100);
    createTerrainBlock(ObjectTypes.DarkOakLeaf, 100);
    createPassableTerrainBlock(ObjectTypes.AzaleaFlower, 100);
    createPassableTerrainBlock(ObjectTypes.BellFlower, 100);
    createPassableTerrainBlock(ObjectTypes.DandelionFlower, 100);
    createPassableTerrainBlock(ObjectTypes.DaylilyFlower, 100);
    createPassableTerrainBlock(ObjectTypes.LilacFlower, 100);
    createPassableTerrainBlock(ObjectTypes.RoseFlower, 100);
    createPassableTerrainBlock(ObjectTypes.FireFlower, 100);
    createPassableTerrainBlock(ObjectTypes.MarigoldFlower, 100);
    createPassableTerrainBlock(ObjectTypes.MorninggloryFlower, 100);
    createPassableTerrainBlock(ObjectTypes.PeonyFlower, 100);
    createPassableTerrainBlock(ObjectTypes.Ultraviolet, 100);
    createPassableTerrainBlock(ObjectTypes.SunFlower, 100);
    createPassableTerrainBlock(ObjectTypes.FescueGrass, 100);
    createPassableTerrainBlock(ObjectTypes.SwitchGrass, 100);
    createPassableTerrainBlock(ObjectTypes.CottonBush, 100);
    createPassableTerrainBlock(ObjectTypes.BambooBush, 100);
    createPassableTerrainBlock(ObjectTypes.VinesBush, 100);
    createPassableTerrainBlock(ObjectTypes.IvyVine, 100);
    createPassableTerrainBlock(ObjectTypes.HempBush, 100);
    createPassableTerrainBlock(ObjectTypes.GoldenMushroom, 100);
    createPassableTerrainBlock(ObjectTypes.RedMushroom, 100);
    createPassableTerrainBlock(ObjectTypes.CoffeeBush, 100);
    createPassableTerrainBlock(ObjectTypes.StrawberryBush, 100);
    createPassableTerrainBlock(ObjectTypes.RaspberryBush, 100);
    createTerrainBlock(ObjectTypes.Cactus, 100);
    createTerrainBlock(ObjectTypes.Pumpkin, 100);
    createTerrainBlock(ObjectTypes.Melon, 100);
    createTerrainBlock(ObjectTypes.RedMushroomBlock, 100);
    createTerrainBlock(ObjectTypes.BrownMushroomBlock, 100);
    createTerrainBlock(ObjectTypes.MushroomStem, 100);
    createTerrainBlock(ObjectTypes.Coral, 100);
    createPassableTerrainBlock(ObjectTypes.SeaAnemone, 100);
    createPassableTerrainBlock(ObjectTypes.Algae, 100);
    createTerrainBlock(ObjectTypes.HornCoralBlock, 100);
    createTerrainBlock(ObjectTypes.FireCoralBlock, 100);
    createTerrainBlock(ObjectTypes.TubeCoralBlock, 100);
    createTerrainBlock(ObjectTypes.BubbleCoralBlock, 100);
    createTerrainBlock(ObjectTypes.BrainCoralBlock, 100);
    createTerrainBlock(ObjectTypes.Snow, 100);
    createTerrainBlock(ObjectTypes.Ice, 100);
    createTerrainBlock(ObjectTypes.SpiderWeb, 100);
    createTerrainBlock(ObjectTypes.Bone, 100);
    createTerrainBlock(ObjectTypes.OakPlanks, 100);
    createTerrainBlock(ObjectTypes.BirchPlanks, 100);
    createTerrainBlock(ObjectTypes.JunglePlanks, 100);
    createTerrainBlock(ObjectTypes.SakuraPlanks, 100);
    createTerrainBlock(ObjectTypes.AcaciaPlanks, 100);
    createTerrainBlock(ObjectTypes.SprucePlanks, 100);
    createTerrainBlock(ObjectTypes.DarkOakPlanks, 100);

    createTerrainBlock(ObjectTypes.CoalOre, 100);
    createTerrainBlock(ObjectTypes.SilverOre, 100);
    createTerrainBlock(ObjectTypes.GoldOre, 100);
    createTerrainBlock(ObjectTypes.DiamondOre, 100);
    createTerrainBlock(ObjectTypes.NeptuniumOre, 100);
  }
}
