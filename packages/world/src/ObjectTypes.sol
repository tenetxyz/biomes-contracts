// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ObjectTypeId } from "./ObjectTypeId.sol";

uint8 constant OFFSET_BITS = 11;
uint16 constant CATEGORY_MASK = 0xf800;

// ------------------------------------------------------------
// Object Categories
// ------------------------------------------------------------
uint16 constant Block = 0;
uint16 constant Item = uint16(1) << OFFSET_BITS;
uint16 constant Tool = uint16(2) << OFFSET_BITS;
uint16 constant Misc = uint16(3) << OFFSET_BITS;

// ------------------------------------------------------------
// Object Types
// ------------------------------------------------------------
library ObjectTypes {
  // Note: Do not use 0 as an object type, as it is reserved
  ObjectTypeId constant Null = ObjectTypeId.wrap(0);

  // ------------------------------------------------------------
  // Terrain Blocks (1-255 is reserved for terrain blocks)
  // ------------------------------------------------------------

  // NonSolid
  ObjectTypeId constant Air = ObjectTypeId.wrap(Block | 1);
  ObjectTypeId constant Water = ObjectTypeId.wrap(Block | 2);
  ObjectTypeId constant Lava = ObjectTypeId.wrap(Block | 3);

  // Stone
  ObjectTypeId constant Stone = ObjectTypeId.wrap(Block | 16);
  ObjectTypeId constant Bedrock = ObjectTypeId.wrap(Block | 17);
  ObjectTypeId constant Deepslate = ObjectTypeId.wrap(Block | 18);
  ObjectTypeId constant Granite = ObjectTypeId.wrap(Block | 19);
  ObjectTypeId constant Tuff = ObjectTypeId.wrap(Block | 20);
  ObjectTypeId constant Calcite = ObjectTypeId.wrap(Block | 21);
  ObjectTypeId constant Basalt = ObjectTypeId.wrap(Block | 22);
  ObjectTypeId constant SmoothBasalt = ObjectTypeId.wrap(Block | 23);
  ObjectTypeId constant Andesite = ObjectTypeId.wrap(Block | 24);
  ObjectTypeId constant Diorite = ObjectTypeId.wrap(Block | 25);
  ObjectTypeId constant Cobblestone = ObjectTypeId.wrap(Block | 26);
  ObjectTypeId constant MossyCobblestone = ObjectTypeId.wrap(Block | 27);
  ObjectTypeId constant Obsidian = ObjectTypeId.wrap(Block | 28);
  ObjectTypeId constant Dripstone = ObjectTypeId.wrap(Block | 29);
  ObjectTypeId constant Blackstone = ObjectTypeId.wrap(Block | 30);
  ObjectTypeId constant CobbledDeepslate = ObjectTypeId.wrap(Block | 31);

  // Gemstone
  ObjectTypeId constant Amethyst = ObjectTypeId.wrap(Block | 32);
  ObjectTypeId constant Glowstone = ObjectTypeId.wrap(Block | 33);
  ObjectTypeId constant AnyOre = ObjectTypeId.wrap(Block | 34);

  // Soil
  ObjectTypeId constant Grass = ObjectTypeId.wrap(Block | 48);
  ObjectTypeId constant Dirt = ObjectTypeId.wrap(Block | 49);
  ObjectTypeId constant Moss = ObjectTypeId.wrap(Block | 50);
  ObjectTypeId constant Podzol = ObjectTypeId.wrap(Block | 51);
  ObjectTypeId constant DirtPath = ObjectTypeId.wrap(Block | 52);
  ObjectTypeId constant Farmland = ObjectTypeId.wrap(Block | 53);
  ObjectTypeId constant Mud = ObjectTypeId.wrap(Block | 54);
  ObjectTypeId constant PackedMud = ObjectTypeId.wrap(Block | 55);
  ObjectTypeId constant WetFarmland = ObjectTypeId.wrap(Block | 56);

  // Sand
  ObjectTypeId constant Gravel = ObjectTypeId.wrap(Block | 64);
  ObjectTypeId constant Sand = ObjectTypeId.wrap(Block | 65);
  ObjectTypeId constant RedSand = ObjectTypeId.wrap(Block | 66);
  ObjectTypeId constant Sandstone = ObjectTypeId.wrap(Block | 67);
  ObjectTypeId constant RedSandstone = ObjectTypeId.wrap(Block | 68);

  // Clay
  ObjectTypeId constant Clay = ObjectTypeId.wrap(Block | 80);
  ObjectTypeId constant Terracotta = ObjectTypeId.wrap(Block | 81);
  ObjectTypeId constant BrownTerracotta = ObjectTypeId.wrap(Block | 82);
  ObjectTypeId constant OrangeTerracotta = ObjectTypeId.wrap(Block | 83);
  ObjectTypeId constant WhiteTerracotta = ObjectTypeId.wrap(Block | 84);
  ObjectTypeId constant LightGrayTerracotta = ObjectTypeId.wrap(Block | 85);
  ObjectTypeId constant YellowTerracotta = ObjectTypeId.wrap(Block | 86);
  ObjectTypeId constant RedTerracotta = ObjectTypeId.wrap(Block | 87);
  ObjectTypeId constant LightBlueTerracotta = ObjectTypeId.wrap(Block | 88);
  ObjectTypeId constant CyanTerracotta = ObjectTypeId.wrap(Block | 89);
  ObjectTypeId constant BlackTerracotta = ObjectTypeId.wrap(Block | 90);
  ObjectTypeId constant PurpleTerracotta = ObjectTypeId.wrap(Block | 91);
  ObjectTypeId constant BlueTerracotta = ObjectTypeId.wrap(Block | 92);
  ObjectTypeId constant MagentaTerracotta = ObjectTypeId.wrap(Block | 93);

  // Log
  ObjectTypeId constant OakLog = ObjectTypeId.wrap(Block | 96);
  ObjectTypeId constant BirchLog = ObjectTypeId.wrap(Block | 97);
  ObjectTypeId constant JungleLog = ObjectTypeId.wrap(Block | 98);
  ObjectTypeId constant SakuraLog = ObjectTypeId.wrap(Block | 99);
  ObjectTypeId constant AcaciaLog = ObjectTypeId.wrap(Block | 100);
  ObjectTypeId constant SpruceLog = ObjectTypeId.wrap(Block | 101);
  ObjectTypeId constant DarkOakLog = ObjectTypeId.wrap(Block | 102);
  ObjectTypeId constant MangroveLog = ObjectTypeId.wrap(Block | 103);

  // Leaves
  ObjectTypeId constant OakLeaf = ObjectTypeId.wrap(Block | 112);
  ObjectTypeId constant BirchLeaf = ObjectTypeId.wrap(Block | 113);
  ObjectTypeId constant JungleLeaf = ObjectTypeId.wrap(Block | 114);
  ObjectTypeId constant SakuraLeaf = ObjectTypeId.wrap(Block | 115);
  ObjectTypeId constant SpruceLeaf = ObjectTypeId.wrap(Block | 116);
  ObjectTypeId constant AcaciaLeaf = ObjectTypeId.wrap(Block | 117);
  ObjectTypeId constant DarkOakLeaf = ObjectTypeId.wrap(Block | 118);
  ObjectTypeId constant MangroveLeaf = ObjectTypeId.wrap(Block | 119);
  ObjectTypeId constant MangroveRoots = ObjectTypeId.wrap(Block | 120);
  ObjectTypeId constant MuddyMangroveRoots = ObjectTypeId.wrap(Block | 121);
  ObjectTypeId constant AzaleaLeaf = ObjectTypeId.wrap(Block | 122);
  ObjectTypeId constant FloweringAzaleaLeaf = ObjectTypeId.wrap(Block | 123);

  // Flower
  ObjectTypeId constant AzaleaFlower = ObjectTypeId.wrap(Block | 128);
  ObjectTypeId constant BellFlower = ObjectTypeId.wrap(Block | 129);
  ObjectTypeId constant DandelionFlower = ObjectTypeId.wrap(Block | 130);
  ObjectTypeId constant DaylilyFlower = ObjectTypeId.wrap(Block | 131);
  ObjectTypeId constant LilacFlower = ObjectTypeId.wrap(Block | 132);
  ObjectTypeId constant RoseFlower = ObjectTypeId.wrap(Block | 133);
  ObjectTypeId constant FireFlower = ObjectTypeId.wrap(Block | 134);
  ObjectTypeId constant MarigoldFlower = ObjectTypeId.wrap(Block | 135);
  ObjectTypeId constant MorninggloryFlower = ObjectTypeId.wrap(Block | 136);
  ObjectTypeId constant PeonyFlower = ObjectTypeId.wrap(Block | 137);
  ObjectTypeId constant Ultraviolet = ObjectTypeId.wrap(Block | 138);
  ObjectTypeId constant SunFlower = ObjectTypeId.wrap(Block | 139);
  ObjectTypeId constant FlyTrap = ObjectTypeId.wrap(Block | 140);

  // Greenery
  ObjectTypeId constant FescueGrass = ObjectTypeId.wrap(Block | 144);
  ObjectTypeId constant SwitchGrass = ObjectTypeId.wrap(Block | 145);
  ObjectTypeId constant CottonBush = ObjectTypeId.wrap(Block | 146);
  ObjectTypeId constant BambooBush = ObjectTypeId.wrap(Block | 147);
  ObjectTypeId constant VinesBush = ObjectTypeId.wrap(Block | 148);
  ObjectTypeId constant IvyVine = ObjectTypeId.wrap(Block | 149);
  ObjectTypeId constant HempBush = ObjectTypeId.wrap(Block | 150);

  // Edibles
  ObjectTypeId constant GoldenMushroom = ObjectTypeId.wrap(Block | 160);
  ObjectTypeId constant RedMushroom = ObjectTypeId.wrap(Block | 161);
  ObjectTypeId constant CoffeeBush = ObjectTypeId.wrap(Block | 162);
  ObjectTypeId constant StrawberryBush = ObjectTypeId.wrap(Block | 163);
  ObjectTypeId constant RaspberryBush = ObjectTypeId.wrap(Block | 164);
  ObjectTypeId constant Cactus = ObjectTypeId.wrap(Block | 165);
  ObjectTypeId constant Pumpkin = ObjectTypeId.wrap(Block | 166);
  ObjectTypeId constant Melon = ObjectTypeId.wrap(Block | 167);
  ObjectTypeId constant RedMushroomBlock = ObjectTypeId.wrap(Block | 168);
  ObjectTypeId constant BrownMushroomBlock = ObjectTypeId.wrap(Block | 169);
  ObjectTypeId constant MushroomStem = ObjectTypeId.wrap(Block | 170);
  ObjectTypeId constant Wheat = ObjectTypeId.wrap(Block | 171);

  // UnderwaterPlant
  ObjectTypeId constant Coral = ObjectTypeId.wrap(Block | 176);
  ObjectTypeId constant SeaAnemone = ObjectTypeId.wrap(Block | 177);
  ObjectTypeId constant Algae = ObjectTypeId.wrap(Block | 178);
  ObjectTypeId constant HornCoralBlock = ObjectTypeId.wrap(Block | 179);
  ObjectTypeId constant FireCoralBlock = ObjectTypeId.wrap(Block | 180);
  ObjectTypeId constant TubeCoralBlock = ObjectTypeId.wrap(Block | 181);
  ObjectTypeId constant BubbleCoralBlock = ObjectTypeId.wrap(Block | 182);
  ObjectTypeId constant BrainCoralBlock = ObjectTypeId.wrap(Block | 183);

  // Other
  ObjectTypeId constant Snow = ObjectTypeId.wrap(Block | 240);
  ObjectTypeId constant Ice = ObjectTypeId.wrap(Block | 241);
  ObjectTypeId constant SpiderWeb = ObjectTypeId.wrap(Block | 242);
  ObjectTypeId constant Bone = ObjectTypeId.wrap(Block | 243);

  // ------------------------------------------------------------
  // Non-Terrain Blocks (256 and above)
  // ------------------------------------------------------------
  ObjectTypeId constant OakPlanks = ObjectTypeId.wrap(Block | 256);
  ObjectTypeId constant BirchPlanks = ObjectTypeId.wrap(Block | 257);
  ObjectTypeId constant JunglePlanks = ObjectTypeId.wrap(Block | 258);
  ObjectTypeId constant SakuraPlanks = ObjectTypeId.wrap(Block | 259);
  ObjectTypeId constant SprucePlanks = ObjectTypeId.wrap(Block | 260);
  ObjectTypeId constant AcaciaPlanks = ObjectTypeId.wrap(Block | 261);
  ObjectTypeId constant DarkOakPlanks = ObjectTypeId.wrap(Block | 262);
  ObjectTypeId constant Thermoblaster = ObjectTypeId.wrap(Block | 263);
  ObjectTypeId constant Workbench = ObjectTypeId.wrap(Block | 264);
  ObjectTypeId constant Dyeomatic = ObjectTypeId.wrap(Block | 265);
  ObjectTypeId constant Powerstone = ObjectTypeId.wrap(Block | 266);
  ObjectTypeId constant CoalOre = ObjectTypeId.wrap(Block | 267);
  ObjectTypeId constant SilverOre = ObjectTypeId.wrap(Block | 268);
  ObjectTypeId constant GoldOre = ObjectTypeId.wrap(Block | 269);
  ObjectTypeId constant DiamondOre = ObjectTypeId.wrap(Block | 270);
  ObjectTypeId constant NeptuniumOre = ObjectTypeId.wrap(Block | 271);
  ObjectTypeId constant ForceField = ObjectTypeId.wrap(Block | 600);
  ObjectTypeId constant Chest = ObjectTypeId.wrap(Block | 601);
  ObjectTypeId constant SmartChest = ObjectTypeId.wrap(Block | 602);
  ObjectTypeId constant TextSign = ObjectTypeId.wrap(Block | 603);
  ObjectTypeId constant SmartTextSign = ObjectTypeId.wrap(Block | 604);
  ObjectTypeId constant Pipe = ObjectTypeId.wrap(Block | 605);
  ObjectTypeId constant SpawnTile = ObjectTypeId.wrap(Block | 606);
  ObjectTypeId constant Bed = ObjectTypeId.wrap(Block | 607);

  // ------------------------------------------------------------
  // Tool
  // ------------------------------------------------------------
  ObjectTypeId constant WoodenPick = ObjectTypeId.wrap(Tool | 0);
  ObjectTypeId constant WoodenAxe = ObjectTypeId.wrap(Tool | 1);
  ObjectTypeId constant WoodenWhacker = ObjectTypeId.wrap(Tool | 2);
  ObjectTypeId constant StonePick = ObjectTypeId.wrap(Tool | 3);
  ObjectTypeId constant StoneAxe = ObjectTypeId.wrap(Tool | 4);
  ObjectTypeId constant StoneWhacker = ObjectTypeId.wrap(Tool | 5);
  ObjectTypeId constant SilverPick = ObjectTypeId.wrap(Tool | 6);
  ObjectTypeId constant SilverAxe = ObjectTypeId.wrap(Tool | 7);
  ObjectTypeId constant SilverWhacker = ObjectTypeId.wrap(Tool | 8);
  ObjectTypeId constant GoldPick = ObjectTypeId.wrap(Tool | 9);
  ObjectTypeId constant GoldAxe = ObjectTypeId.wrap(Tool | 10);
  ObjectTypeId constant DiamondPick = ObjectTypeId.wrap(Tool | 11);
  ObjectTypeId constant DiamondAxe = ObjectTypeId.wrap(Tool | 12);
  ObjectTypeId constant NeptuniumPick = ObjectTypeId.wrap(Tool | 13);
  ObjectTypeId constant NeptuniumAxe = ObjectTypeId.wrap(Tool | 14);
  ObjectTypeId constant SilverHoe = ObjectTypeId.wrap(Tool | 15);

  // ------------------------------------------------------------
  // Item
  // ------------------------------------------------------------
  ObjectTypeId constant GoldBar = ObjectTypeId.wrap(Item | 0);
  ObjectTypeId constant SilverBar = ObjectTypeId.wrap(Item | 1);
  ObjectTypeId constant Diamond = ObjectTypeId.wrap(Item | 2);
  ObjectTypeId constant NeptuniumBar = ObjectTypeId.wrap(Item | 3);
  ObjectTypeId constant ChipBattery = ObjectTypeId.wrap(Item | 4);

  ObjectTypeId constant Bucket = ObjectTypeId.wrap(Item | 5);
  ObjectTypeId constant WaterBucket = ObjectTypeId.wrap(Item | 6);

  // ------------------------------------------------------------
  // Misc
  // ------------------------------------------------------------
  ObjectTypeId constant Player = ObjectTypeId.wrap(Misc | 0);
  ObjectTypeId constant ForceFieldFragment = ObjectTypeId.wrap(Misc | 1);
  ObjectTypeId constant AnyLog = ObjectTypeId.wrap(Misc | 2046);
  ObjectTypeId constant AnyPlanks = ObjectTypeId.wrap(Misc | 2047);
}
