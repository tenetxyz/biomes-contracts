// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Object Types

// Note: Do not use 0 as an object ID, as it is reserved
uint8 constant NullObjectTypeId = 0;

// Players
uint8 constant PlayerObjectID = 1;

// Tools
uint8 constant WoodenPickObjectID = 2;
uint8 constant WoodenAxeObjectID = 3;
uint8 constant WoodenWhackerObjectID = 4;
uint8 constant StonePickObjectID = 5;
uint8 constant StoneAxeObjectID = 6;
uint8 constant StoneWhackerObjectID = 7;
uint8 constant SilverPickObjectID = 8;
uint8 constant SilverAxeObjectID = 9;
uint8 constant SilverWhackerObjectID = 10;
uint8 constant GoldPickObjectID = 11;
uint8 constant GoldAxeObjectID = 12;
uint8 constant DiamondPickObjectID = 13;
uint8 constant DiamondAxeObjectID = 14;
uint8 constant NeptuniumPickObjectID = 15;
uint8 constant NeptuniumAxeObjectID = 16;

// Items
uint8 constant GoldBarObjectID = 17;
uint8 constant SilverBarObjectID = 18;
uint8 constant NeptuniumBarObjectID = 19;
uint8 constant DiamondObjectID = 20;

// Dyes
uint8 constant BlueDyeObjectID = 21;
uint8 constant BrownDyeObjectID = 22;
uint8 constant GreenDyeObjectID = 23;
uint8 constant MagentaDyeObjectID = 24;
uint8 constant OrangeDyeObjectID = 25;
uint8 constant PinkDyeObjectID = 26;
uint8 constant PurpleDyeObjectID = 27;
uint8 constant RedDyeObjectID = 28;
uint8 constant TanDyeObjectID = 29;
uint8 constant WhiteDyeObjectID = 30;
uint8 constant YellowDyeObjectID = 31;
uint8 constant BlackDyeObjectID = 32;
uint8 constant SilverDyeObjectID = 33;

// Blocks
uint8 constant AirObjectID = 34;
uint8 constant GrassObjectID = 35;
uint8 constant MuckGrassObjectID = 36; // unused
uint8 constant DirtObjectID = 37;
uint8 constant MuckDirtObjectID = 38; // unused
uint8 constant MossBlockObjectID = 39;
uint8 constant SnowObjectID = 40; // unused
uint8 constant GravelObjectID = 41;
uint8 constant SandObjectID = 42;
uint8 constant GlassObjectID = 43;
uint8 constant BedrockObjectID = 44;

uint8 constant CobblestoneObjectID = 45;
uint8 constant CobblestoneBrickObjectID = 46;
uint8 constant CobblestoneCarvedObjectID = 47;
uint8 constant CobblestonePolishedObjectID = 48;
uint8 constant CobblestoneShinglesObjectID = 49;

uint8 constant StoneObjectID = 50;
uint8 constant StoneBrickObjectID = 51;
uint8 constant StoneCarvedObjectID = 52;
uint8 constant StonePolishedObjectID = 53;
uint8 constant StoneShinglesObjectID = 54;

uint8 constant BasaltObjectID = 55;
uint8 constant BasaltBrickObjectID = 56;
uint8 constant BasaltCarvedObjectID = 57;
uint8 constant BasaltPolishedObjectID = 58;
uint8 constant BasaltShinglesObjectID = 59;

uint8 constant ClayObjectID = 60;
uint8 constant ClayBrickObjectID = 61;
uint8 constant ClayCarvedObjectID = 62;
uint8 constant ClayPolishedObjectID = 63;
uint8 constant ClayShinglesObjectID = 64;

uint8 constant GraniteObjectID = 65;
uint8 constant GraniteBrickObjectID = 66;
uint8 constant GraniteCarvedObjectID = 67;
uint8 constant GranitePolishedObjectID = 68;
uint8 constant GraniteShinglesObjectID = 69;

uint8 constant QuartziteObjectID = 70;
uint8 constant QuartziteBrickObjectID = 71;
uint8 constant QuartziteCarvedObjectID = 72;
uint8 constant QuartzitePolishedObjectID = 73;
uint8 constant QuartziteShinglesObjectID = 74;

uint8 constant LimestoneObjectID = 75;
uint8 constant LimestoneBrickObjectID = 76;
uint8 constant LimestoneCarvedObjectID = 77;
uint8 constant LimestonePolishedObjectID = 78;
uint8 constant LimestoneShinglesObjectID = 79;

// Blocks that glow
uint8 constant EmberstoneObjectID = 80;
uint8 constant MoonstoneObjectID = 81;
uint8 constant SunstoneObjectID = 82;
uint8 constant WaterObjectID = 83;

// Interactable
uint8 constant ChestObjectID = 84;
uint8 constant ThermoblasterObjectID = 85;
uint8 constant WorkbenchObjectID = 86;
uint8 constant DyeomaticObjectID = 87;

// Ores and Cubes
uint8 constant CoalOreObjectID = 88;
uint8 constant GoldOreObjectID = 89;
uint8 constant GoldCubeObjectID = 90;
uint8 constant SilverOreObjectID = 91;
uint8 constant SilverCubeObjectID = 92;
uint8 constant DiamondOreObjectID = 93;
uint8 constant DiamondCubeObjectID = 94;
uint8 constant NeptuniumOreObjectID = 95;
uint8 constant NeptuniumCubeObjectID = 96;

// Lumber
uint8 constant OakLogObjectID = 97;
uint8 constant OakLumberObjectID = 98;
uint8 constant ReinforcedOakLumberObjectID = 99;
uint8 constant SakuraLogObjectID = 100;
uint8 constant SakuraLumberObjectID = 101;
uint8 constant RubberLogObjectID = 102;
uint8 constant RubberLumberObjectID = 103;
uint8 constant ReinforcedRubberLumberObjectID = 104;
uint8 constant BirchLogObjectID = 105;
uint8 constant BirchLumberObjectID = 106;
uint8 constant ReinforcedBirchLumberObjectID = 107;

// Florae blocks
uint8 constant MushroomLeatherBlockObjectID = 108;
uint8 constant CottonBlockObjectID = 109;

// Florae
uint8 constant CactusObjectID = 110;
uint8 constant LilacObjectID = 111;
uint8 constant DandelionObjectID = 112;
uint8 constant RedMushroomObjectID = 113;
uint8 constant BellflowerObjectID = 114;
uint8 constant CottonBushObjectID = 115;
uint8 constant SwitchGrassObjectID = 116; // unused
uint8 constant DaylilyObjectID = 117;
uint8 constant AzaleaObjectID = 118;
uint8 constant RoseObjectID = 119;

// Tree leafs
uint8 constant OakLeafObjectID = 120;
uint8 constant BirchLeafObjectID = 121;
uint8 constant SakuraLeafObjectID = 122;
uint8 constant RubberLeafObjectID = 123;

// Colored Blocks
uint8 constant BlueOakLumberObjectID = 124;
uint8 constant BrownOakLumberObjectID = 125;
uint8 constant GreenOakLumberObjectID = 126;
uint8 constant MagentaOakLumberObjectID = 127;
uint8 constant OrangeOakLumberObjectID = 128;
uint8 constant PinkOakLumberObjectID = 129;
uint8 constant PurpleOakLumberObjectID = 130;
uint8 constant RedOakLumberObjectID = 131;
uint8 constant TanOakLumberObjectID = 132;
uint8 constant WhiteOakLumberObjectID = 133;
uint8 constant YellowOakLumberObjectID = 134;
uint8 constant BlackOakLumberObjectID = 135;
uint8 constant SilverOakLumberObjectID = 136;

uint8 constant BlueCottonBlockObjectID = 137;
uint8 constant BrownCottonBlockObjectID = 138;
uint8 constant GreenCottonBlockObjectID = 139;
uint8 constant MagentaCottonBlockObjectID = 140;
uint8 constant OrangeCottonBlockObjectID = 141;
uint8 constant PinkCottonBlockObjectID = 142;
uint8 constant PurpleCottonBlockObjectID = 143;
uint8 constant RedCottonBlockObjectID = 144;
uint8 constant TanCottonBlockObjectID = 145;
uint8 constant WhiteCottonBlockObjectID = 146;
uint8 constant YellowCottonBlockObjectID = 147;
uint8 constant BlackCottonBlockObjectID = 148;
uint8 constant SilverCottonBlockObjectID = 149;

uint8 constant BlueGlassObjectID = 150;
uint8 constant GreenGlassObjectID = 151;
uint8 constant OrangeGlassObjectID = 152;
uint8 constant PinkGlassObjectID = 153;
uint8 constant PurpleGlassObjectID = 154;
uint8 constant RedGlassObjectID = 155;
uint8 constant WhiteGlassObjectID = 156;
uint8 constant YellowGlassObjectID = 157;
uint8 constant BlackGlassObjectID = 158;

// Used for Recipes only
uint8 constant AnyLogObjectID = 159;
uint8 constant AnyLumberObjectID = 160;
uint8 constant AnyReinforcedLumberObjectID = 161;
uint8 constant AnyGlassObjectID = 165;

uint8 constant ChipObjectID = 162;
uint8 constant ChipBatteryObjectID = 163;
uint8 constant ForceFieldObjectID = 164;
