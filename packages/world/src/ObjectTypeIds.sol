// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Note: Do not use 0 as an object ID, as it is reserved
uint16 constant NullObjectTypeId = 0;

// ------------------------------------------------------------
// Terrain Blocks (1-255 is reserved for terrain blocks)
// ------------------------------------------------------------
uint16 constant AirObjectID = 1;
uint16 constant WaterObjectID = 2;
uint16 constant LavaObjectID = 3;
uint16 constant GrassObjectID = 4;
uint16 constant DirtObjectID = 5;
uint16 constant MossBlockObjectID = 6;
uint16 constant SnowObjectID = 7;
uint16 constant GravelObjectID = 8;
uint16 constant SandObjectID = 9;
uint16 constant BedrockObjectID = 10;

uint16 constant StoneObjectID = 11;
uint16 constant BasaltObjectID = 12;
uint16 constant GraniteObjectID = 13;
uint16 constant QuartziteObjectID = 14;
uint16 constant LimestoneObjectID = 15;

// Ores
uint16 constant AnyOreObjectID = 16;
uint16 constant CoalOreObjectID = 17;
uint16 constant GoldOreObjectID = 18;
uint16 constant SilverOreObjectID = 19;
uint16 constant DiamondOreObjectID = 20;
uint16 constant NeptuniumOreObjectID = 21;

// Logs
uint16 constant OakLogObjectID = 22;
uint16 constant SakuraLogObjectID = 23;
uint16 constant RubberLogObjectID = 24;
uint16 constant BirchLogObjectID = 25;

// Tree leafs
uint16 constant OakLeafObjectID = 26;
uint16 constant BirchLeafObjectID = 27;
uint16 constant SakuraLeafObjectID = 28;
uint16 constant RubberLeafObjectID = 29;

// Florae
uint16 constant CactusObjectID = 30;
uint16 constant LilacObjectID = 31;
uint16 constant DandelionObjectID = 32;
uint16 constant RedMushroomObjectID = 33;
uint16 constant BellflowerObjectID = 34;
uint16 constant CottonBushObjectID = 35;
uint16 constant SwitchGrassObjectID = 36;
uint16 constant DaylilyObjectID = 37;
uint16 constant AzaleaObjectID = 38;
uint16 constant RoseObjectID = 39;

// ------------------------------------------------------------
// Non-Terrain Blocks
// ------------------------------------------------------------
uint16 constant PlayerObjectID = 256;

uint16 constant GlassObjectID = 257;
uint16 constant ClayObjectID = 258;
uint16 constant CobblestoneObjectID = 259;

uint16 constant CobblestoneBrickObjectID = 260;
uint16 constant CobblestoneCarvedObjectID = 261;
uint16 constant CobblestonePolishedObjectID = 262;
uint16 constant CobblestoneShinglesObjectID = 263;

uint16 constant StoneBrickObjectID = 264;
uint16 constant StoneCarvedObjectID = 265;
uint16 constant StonePolishedObjectID = 266;
uint16 constant StoneShinglesObjectID = 267;

uint16 constant BasaltBrickObjectID = 268;
uint16 constant BasaltCarvedObjectID = 269;
uint16 constant BasaltPolishedObjectID = 270;
uint16 constant BasaltShinglesObjectID = 271;

uint16 constant ClayBrickObjectID = 272;
uint16 constant ClayCarvedObjectID = 273;
uint16 constant ClayPolishedObjectID = 274;
uint16 constant ClayShinglesObjectID = 275;

uint16 constant GraniteBrickObjectID = 276;
uint16 constant GraniteCarvedObjectID = 277;
uint16 constant GranitePolishedObjectID = 278;
uint16 constant GraniteShinglesObjectID = 279;

uint16 constant QuartziteBrickObjectID = 280;
uint16 constant QuartziteCarvedObjectID = 281;
uint16 constant QuartzitePolishedObjectID = 282;
uint16 constant QuartziteShinglesObjectID = 283;

uint16 constant LimestoneBrickObjectID = 284;
uint16 constant LimestoneCarvedObjectID = 285;
uint16 constant LimestonePolishedObjectID = 286;
uint16 constant LimestoneShinglesObjectID = 287;

// Blocks that glow
uint16 constant EmberstoneObjectID = 288;
uint16 constant MoonstoneObjectID = 289;
uint16 constant SunstoneObjectID = 290;

// Ore blocks
uint16 constant GoldBarObjectID = 291;
uint16 constant SilverBarObjectID = 292;
uint16 constant DiamondObjectID = 293;
uint16 constant NeptuniumBarObjectID = 294;

uint16 constant GoldCubeObjectID = 295;
uint16 constant SilverCubeObjectID = 296;
uint16 constant DiamondCubeObjectID = 297;
uint16 constant NeptuniumCubeObjectID = 298;

// Florae blocks
uint16 constant MushroomLeatherBlockObjectID = 299;
uint16 constant CottonBlockObjectID = 300;

// Crafting stations
uint16 constant ThermoblasterObjectID = 301;
uint16 constant WorkbenchObjectID = 302;
uint16 constant DyeomaticObjectID = 303;
uint16 constant PowerStoneObjectID = 304;

// Smart objects
uint16 constant ChipObjectID = 305;
uint16 constant ChipBatteryObjectID = 306;

uint16 constant ForceFieldObjectID = 307;

uint16 constant ChestObjectID = 308;
uint16 constant SmartChestObjectID = 309;
uint16 constant TextSignObjectID = 310;
uint16 constant SmartTextSignObjectID = 311;
uint16 constant PipeObjectID = 312;

// Lumber
uint16 constant OakLumberObjectID = 313;
uint16 constant SakuraLumberObjectID = 314;
uint16 constant RubberLumberObjectID = 315;
uint16 constant BirchLumberObjectID = 316;
uint16 constant ReinforcedOakLumberObjectID = 317;
uint16 constant ReinforcedRubberLumberObjectID = 318;
uint16 constant ReinforcedBirchLumberObjectID = 319;

// Tools
uint16 constant WoodenPickObjectID = 320;
uint16 constant WoodenAxeObjectID = 321;
uint16 constant WoodenWhackerObjectID = 322;
uint16 constant StonePickObjectID = 323;
uint16 constant StoneAxeObjectID = 324;
uint16 constant StoneWhackerObjectID = 325;
uint16 constant SilverPickObjectID = 326;
uint16 constant SilverAxeObjectID = 327;
uint16 constant SilverWhackerObjectID = 328;
uint16 constant GoldPickObjectID = 329;
uint16 constant GoldAxeObjectID = 330;
uint16 constant DiamondPickObjectID = 331;
uint16 constant DiamondAxeObjectID = 332;
uint16 constant NeptuniumPickObjectID = 333;
uint16 constant NeptuniumAxeObjectID = 334;

// Dyes
uint16 constant BlueDyeObjectID = 335;
uint16 constant BrownDyeObjectID = 336;
uint16 constant GreenDyeObjectID = 337;
uint16 constant MagentaDyeObjectID = 338;
uint16 constant OrangeDyeObjectID = 339;
uint16 constant PinkDyeObjectID = 340;
uint16 constant PurpleDyeObjectID = 341;
uint16 constant RedDyeObjectID = 342;
uint16 constant TanDyeObjectID = 343;
uint16 constant WhiteDyeObjectID = 344;
uint16 constant YellowDyeObjectID = 345;
uint16 constant BlackDyeObjectID = 346;
uint16 constant SilverDyeObjectID = 347;

// Dyed Blocks
uint16 constant BlueOakLumberObjectID = 348;
uint16 constant BrownOakLumberObjectID = 349;
uint16 constant GreenOakLumberObjectID = 350;
uint16 constant MagentaOakLumberObjectID = 351;
uint16 constant OrangeOakLumberObjectID = 352;
uint16 constant PinkOakLumberObjectID = 353;
uint16 constant PurpleOakLumberObjectID = 354;
uint16 constant RedOakLumberObjectID = 355;
uint16 constant TanOakLumberObjectID = 356;
uint16 constant WhiteOakLumberObjectID = 357;
uint16 constant YellowOakLumberObjectID = 358;
uint16 constant BlackOakLumberObjectID = 359;
uint16 constant SilverOakLumberObjectID = 360;

uint16 constant BlueCottonBlockObjectID = 361;
uint16 constant BrownCottonBlockObjectID = 362;
uint16 constant GreenCottonBlockObjectID = 363;
uint16 constant MagentaCottonBlockObjectID = 364;
uint16 constant OrangeCottonBlockObjectID = 365;
uint16 constant PinkCottonBlockObjectID = 366;
uint16 constant PurpleCottonBlockObjectID = 367;
uint16 constant RedCottonBlockObjectID = 368;
uint16 constant TanCottonBlockObjectID = 369;
uint16 constant WhiteCottonBlockObjectID = 370;
uint16 constant YellowCottonBlockObjectID = 371;
uint16 constant BlackCottonBlockObjectID = 372;
uint16 constant SilverCottonBlockObjectID = 373;

uint16 constant BlueGlassObjectID = 374;
uint16 constant GreenGlassObjectID = 375;
uint16 constant OrangeGlassObjectID = 376;
uint16 constant PinkGlassObjectID = 377;
uint16 constant PurpleGlassObjectID = 378;
uint16 constant RedGlassObjectID = 379;
uint16 constant WhiteGlassObjectID = 380;
uint16 constant YellowGlassObjectID = 381;
uint16 constant BlackGlassObjectID = 382;

// ------------------------------------------------------------
// Special Object IDs
// ------------------------------------------------------------

// Used for Recipes only
uint16 constant AnyLogObjectID = 65_535;
uint16 constant AnyLumberObjectID = 65_534;
uint16 constant AnyReinforcedLumberObjectID = 65_533;
uint16 constant AnyCottonBlockObjectID = 65_532;
uint16 constant AnyGlassObjectID = 65_531;
