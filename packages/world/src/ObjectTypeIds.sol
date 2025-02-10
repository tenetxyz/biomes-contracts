// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Object Types

// Note: Do not use 0 as an object ID, as it is reserved
uint16 constant NullObjectTypeId = 0;

// Players
uint16 constant PlayerObjectID = 1;

// Tools
uint16 constant WoodenPickObjectID = 2;
uint16 constant WoodenAxeObjectID = 3;
uint16 constant WoodenWhackerObjectID = 4;
uint16 constant StonePickObjectID = 5;
uint16 constant StoneAxeObjectID = 6;
uint16 constant StoneWhackerObjectID = 7;
uint16 constant SilverPickObjectID = 8;
uint16 constant SilverAxeObjectID = 9;
uint16 constant SilverWhackerObjectID = 10;
uint16 constant GoldPickObjectID = 11;
uint16 constant GoldAxeObjectID = 12;
uint16 constant DiamondPickObjectID = 13;
uint16 constant DiamondAxeObjectID = 14;
uint16 constant NeptuniumPickObjectID = 15;
uint16 constant NeptuniumAxeObjectID = 16;

// Items
uint16 constant GoldBarObjectID = 17;
uint16 constant SilverBarObjectID = 18;
uint16 constant NeptuniumBarObjectID = 19;
uint16 constant DiamondObjectID = 20;

// Dyes
uint16 constant BlueDyeObjectID = 21;
uint16 constant BrownDyeObjectID = 22;
uint16 constant GreenDyeObjectID = 23;
uint16 constant MagentaDyeObjectID = 24;
uint16 constant OrangeDyeObjectID = 25;
uint16 constant PinkDyeObjectID = 26;
uint16 constant PurpleDyeObjectID = 27;
uint16 constant RedDyeObjectID = 28;
uint16 constant TanDyeObjectID = 29;
uint16 constant WhiteDyeObjectID = 30;
uint16 constant YellowDyeObjectID = 31;
uint16 constant BlackDyeObjectID = 32;
uint16 constant SilverDyeObjectID = 33;

// Blocks
uint16 constant AirObjectID = 34;
uint16 constant GrassObjectID = 35;
uint16 constant MuckGrassObjectID = 36; // unused
uint16 constant DirtObjectID = 37;
uint16 constant MuckDirtObjectID = 38; // unused
uint16 constant MossBlockObjectID = 39;
uint16 constant SnowObjectID = 40; // unused
uint16 constant GravelObjectID = 41;
uint16 constant SandObjectID = 42;
uint16 constant GlassObjectID = 43;
uint16 constant BedrockObjectID = 44;

uint16 constant CobblestoneObjectID = 45;
uint16 constant CobblestoneBrickObjectID = 46;
uint16 constant CobblestoneCarvedObjectID = 47;
uint16 constant CobblestonePolishedObjectID = 48;
uint16 constant CobblestoneShinglesObjectID = 49;

uint16 constant StoneObjectID = 50;
uint16 constant StoneBrickObjectID = 51;
uint16 constant StoneCarvedObjectID = 52;
uint16 constant StonePolishedObjectID = 53;
uint16 constant StoneShinglesObjectID = 54;

uint16 constant BasaltObjectID = 55;
uint16 constant BasaltBrickObjectID = 56;
uint16 constant BasaltCarvedObjectID = 57;
uint16 constant BasaltPolishedObjectID = 58;
uint16 constant BasaltShinglesObjectID = 59;

uint16 constant ClayObjectID = 60;
uint16 constant ClayBrickObjectID = 61;
uint16 constant ClayCarvedObjectID = 62;
uint16 constant ClayPolishedObjectID = 63;
uint16 constant ClayShinglesObjectID = 64;

uint16 constant GraniteObjectID = 65;
uint16 constant GraniteBrickObjectID = 66;
uint16 constant GraniteCarvedObjectID = 67;
uint16 constant GranitePolishedObjectID = 68;
uint16 constant GraniteShinglesObjectID = 69;

uint16 constant QuartziteObjectID = 70;
uint16 constant QuartziteBrickObjectID = 71;
uint16 constant QuartziteCarvedObjectID = 72;
uint16 constant QuartzitePolishedObjectID = 73;
uint16 constant QuartziteShinglesObjectID = 74;

uint16 constant LimestoneObjectID = 75;
uint16 constant LimestoneBrickObjectID = 76;
uint16 constant LimestoneCarvedObjectID = 77;
uint16 constant LimestonePolishedObjectID = 78;
uint16 constant LimestoneShinglesObjectID = 79;

// Blocks that glow
uint16 constant EmberstoneObjectID = 80;
uint16 constant MoonstoneObjectID = 81;
uint16 constant SunstoneObjectID = 82;
uint16 constant WaterObjectID = 83;

// Interactable
uint16 constant ChestObjectID = 84;
uint16 constant ThermoblasterObjectID = 85;
uint16 constant WorkbenchObjectID = 86;
uint16 constant DyeomaticObjectID = 87;

// Ores and Cubes
uint16 constant CoalOreObjectID = 88;
uint16 constant GoldOreObjectID = 89;
uint16 constant GoldCubeObjectID = 90;
uint16 constant SilverOreObjectID = 91;
uint16 constant SilverCubeObjectID = 92;
uint16 constant DiamondOreObjectID = 93;
uint16 constant DiamondCubeObjectID = 94;
uint16 constant NeptuniumOreObjectID = 95;
uint16 constant NeptuniumCubeObjectID = 96;

// Lumber
uint16 constant OakLogObjectID = 97;
uint16 constant OakLumberObjectID = 98;
uint16 constant ReinforcedOakLumberObjectID = 99;
uint16 constant SakuraLogObjectID = 100;
uint16 constant SakuraLumberObjectID = 101;
uint16 constant RubberLogObjectID = 102;
uint16 constant RubberLumberObjectID = 103;
uint16 constant ReinforcedRubberLumberObjectID = 104;
uint16 constant BirchLogObjectID = 105;
uint16 constant BirchLumberObjectID = 106;
uint16 constant ReinforcedBirchLumberObjectID = 107;

// Florae blocks
uint16 constant MushroomLeatherBlockObjectID = 108;
uint16 constant CottonBlockObjectID = 109;

// Florae
uint16 constant CactusObjectID = 110;
uint16 constant LilacObjectID = 111;
uint16 constant DandelionObjectID = 112;
uint16 constant RedMushroomObjectID = 113;
uint16 constant BellflowerObjectID = 114;
uint16 constant CottonBushObjectID = 115;
uint16 constant SwitchGrassObjectID = 116; // unused
uint16 constant DaylilyObjectID = 117;
uint16 constant AzaleaObjectID = 118;
uint16 constant RoseObjectID = 119;

// Tree leafs
uint16 constant OakLeafObjectID = 120;
uint16 constant BirchLeafObjectID = 121;
uint16 constant SakuraLeafObjectID = 122;
uint16 constant RubberLeafObjectID = 123;

// Colored Blocks
uint16 constant BlueOakLumberObjectID = 124;
uint16 constant BrownOakLumberObjectID = 125;
uint16 constant GreenOakLumberObjectID = 126;
uint16 constant MagentaOakLumberObjectID = 127;
uint16 constant OrangeOakLumberObjectID = 128;
uint16 constant PinkOakLumberObjectID = 129;
uint16 constant PurpleOakLumberObjectID = 130;
uint16 constant RedOakLumberObjectID = 131;
uint16 constant TanOakLumberObjectID = 132;
uint16 constant WhiteOakLumberObjectID = 133;
uint16 constant YellowOakLumberObjectID = 134;
uint16 constant BlackOakLumberObjectID = 135;
uint16 constant SilverOakLumberObjectID = 136;

uint16 constant BlueCottonBlockObjectID = 137;
uint16 constant BrownCottonBlockObjectID = 138;
uint16 constant GreenCottonBlockObjectID = 139;
uint16 constant MagentaCottonBlockObjectID = 140;
uint16 constant OrangeCottonBlockObjectID = 141;
uint16 constant PinkCottonBlockObjectID = 142;
uint16 constant PurpleCottonBlockObjectID = 143;
uint16 constant RedCottonBlockObjectID = 144;
uint16 constant TanCottonBlockObjectID = 145;
uint16 constant WhiteCottonBlockObjectID = 146;
uint16 constant YellowCottonBlockObjectID = 147;
uint16 constant BlackCottonBlockObjectID = 148;
uint16 constant SilverCottonBlockObjectID = 149;

uint16 constant BlueGlassObjectID = 150;
uint16 constant GreenGlassObjectID = 151;
uint16 constant OrangeGlassObjectID = 152;
uint16 constant PinkGlassObjectID = 153;
uint16 constant PurpleGlassObjectID = 154;
uint16 constant RedGlassObjectID = 155;
uint16 constant WhiteGlassObjectID = 156;
uint16 constant YellowGlassObjectID = 157;
uint16 constant BlackGlassObjectID = 158;

// Used for Recipes only
uint16 constant AnyLogObjectID = 159;
uint16 constant AnyLumberObjectID = 160;
uint16 constant AnyReinforcedLumberObjectID = 161;
uint16 constant AnyCottonBlockObjectID = 162;
uint16 constant AnyGlassObjectID = 163;

uint16 constant ChipObjectID = 164;
uint16 constant ChipBatteryObjectID = 165;
uint16 constant ForceFieldObjectID = 166;
uint16 constant PowerStoneObjectID = 167;
uint16 constant TextSignObjectID = 168;

// Used for Procedural Terrain Only
uint16 constant AnyOreObjectID = 169;

uint16 constant LavaObjectID = 170;
uint16 constant SmartChestObjectID = 171;
uint16 constant SmartTextSignObjectID = 172;
uint16 constant PipeObjectID = 173;
