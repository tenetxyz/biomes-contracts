// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

type ObjectTypeId is uint16;

uint8 constant OFFSET_BITS = 11;

// ------------------------------------------------------------
// Object Categories
// ------------------------------------------------------------
uint16 constant Terrain = 0;
uint16 constant Tool = uint16(1) << OFFSET_BITS;
uint16 constant SmartObject = uint16(2) << OFFSET_BITS;
// TODO: placeholder
uint16 constant Misc = uint16(3) << OFFSET_BITS;

// ------------------------------------------------------------
// Object Type Ids
// ------------------------------------------------------------

// Note: Do not use 0 as an object ID, as it is reserved
ObjectTypeId constant NullObjectTypeId = ObjectTypeId.wrap(0);

// ------------------------------------------------------------
// Terrain Blocks (1-255 is reserved for terrain blocks)
// ------------------------------------------------------------
ObjectTypeId constant AirObjectID = ObjectTypeId.wrap(Terrain | 1);
ObjectTypeId constant WaterObjectID = ObjectTypeId.wrap(Terrain | 2);
ObjectTypeId constant LavaObjectID = ObjectTypeId.wrap(Terrain | 3);
ObjectTypeId constant GrassObjectID = ObjectTypeId.wrap(Terrain | 4);
ObjectTypeId constant DirtObjectID = ObjectTypeId.wrap(Terrain | 5);
ObjectTypeId constant MossBlockObjectID = ObjectTypeId.wrap(Terrain | 6);
ObjectTypeId constant SnowObjectID = ObjectTypeId.wrap(Terrain | 7);
ObjectTypeId constant GravelObjectID = ObjectTypeId.wrap(Terrain | 8);
ObjectTypeId constant SandObjectID = ObjectTypeId.wrap(Terrain | 9);
ObjectTypeId constant BedrockObjectID = ObjectTypeId.wrap(Terrain | 10);

ObjectTypeId constant StoneObjectID = ObjectTypeId.wrap(Terrain | 11);
ObjectTypeId constant BasaltObjectID = ObjectTypeId.wrap(Terrain | 12);
ObjectTypeId constant GraniteObjectID = ObjectTypeId.wrap(Terrain | 13);
ObjectTypeId constant QuartziteObjectID = ObjectTypeId.wrap(Terrain | 14);
ObjectTypeId constant LimestoneObjectID = ObjectTypeId.wrap(Terrain | 15);

// Ores
ObjectTypeId constant AnyOreObjectID = ObjectTypeId.wrap(Terrain | 16);
ObjectTypeId constant CoalOreObjectID = ObjectTypeId.wrap(Terrain | 17);
ObjectTypeId constant GoldOreObjectID = ObjectTypeId.wrap(Terrain | 18);
ObjectTypeId constant SilverOreObjectID = ObjectTypeId.wrap(Terrain | 19);
ObjectTypeId constant DiamondOreObjectID = ObjectTypeId.wrap(Terrain | 20);
ObjectTypeId constant NeptuniumOreObjectID = ObjectTypeId.wrap(Terrain | 21);

// Logs
ObjectTypeId constant OakLogObjectID = ObjectTypeId.wrap(Terrain | 22);
ObjectTypeId constant SakuraLogObjectID = ObjectTypeId.wrap(Terrain | 23);
ObjectTypeId constant RubberLogObjectID = ObjectTypeId.wrap(Terrain | 24);
ObjectTypeId constant BirchLogObjectID = ObjectTypeId.wrap(Terrain | 25);

// Tree leafs
ObjectTypeId constant OakLeafObjectID = ObjectTypeId.wrap(Terrain | 26);
ObjectTypeId constant BirchLeafObjectID = ObjectTypeId.wrap(Terrain | 27);
ObjectTypeId constant SakuraLeafObjectID = ObjectTypeId.wrap(Terrain | 28);
ObjectTypeId constant RubberLeafObjectID = ObjectTypeId.wrap(Terrain | 29);

// Florae
ObjectTypeId constant CactusObjectID = ObjectTypeId.wrap(Terrain | 30);
ObjectTypeId constant LilacObjectID = ObjectTypeId.wrap(Terrain | 31);
ObjectTypeId constant DandelionObjectID = ObjectTypeId.wrap(Terrain | 32);
ObjectTypeId constant RedMushroomObjectID = ObjectTypeId.wrap(Terrain | 33);
ObjectTypeId constant BellflowerObjectID = ObjectTypeId.wrap(Terrain | 34);
ObjectTypeId constant CottonBushObjectID = ObjectTypeId.wrap(Terrain | 35);
ObjectTypeId constant SwitchGrassObjectID = ObjectTypeId.wrap(Terrain | 36);
ObjectTypeId constant DaylilyObjectID = ObjectTypeId.wrap(Terrain | 37);
ObjectTypeId constant AzaleaObjectID = ObjectTypeId.wrap(Terrain | 38);
ObjectTypeId constant RoseObjectID = ObjectTypeId.wrap(Terrain | 39);

// ------------------------------------------------------------
// Non-Terrain Blocks
// ------------------------------------------------------------

// Tools
ObjectTypeId constant WoodenPickObjectID = ObjectTypeId.wrap(Tool | 0);
ObjectTypeId constant WoodenAxeObjectID = ObjectTypeId.wrap(Tool | 1);
ObjectTypeId constant WoodenWhackerObjectID = ObjectTypeId.wrap(Tool | 2);
ObjectTypeId constant StonePickObjectID = ObjectTypeId.wrap(Tool | 3);
ObjectTypeId constant StoneAxeObjectID = ObjectTypeId.wrap(Tool | 4);
ObjectTypeId constant StoneWhackerObjectID = ObjectTypeId.wrap(Tool | 5);
ObjectTypeId constant SilverPickObjectID = ObjectTypeId.wrap(Tool | 6);
ObjectTypeId constant SilverAxeObjectID = ObjectTypeId.wrap(Tool | 7);
ObjectTypeId constant SilverWhackerObjectID = ObjectTypeId.wrap(Tool | 8);
ObjectTypeId constant GoldPickObjectID = ObjectTypeId.wrap(Tool | 9);
ObjectTypeId constant GoldAxeObjectID = ObjectTypeId.wrap(Tool | 10);
ObjectTypeId constant DiamondPickObjectID = ObjectTypeId.wrap(Tool | 11);
ObjectTypeId constant DiamondAxeObjectID = ObjectTypeId.wrap(Tool | 12);
ObjectTypeId constant NeptuniumPickObjectID = ObjectTypeId.wrap(Tool | 13);
ObjectTypeId constant NeptuniumAxeObjectID = ObjectTypeId.wrap(Tool | 14);

// Smart objects
ObjectTypeId constant ForceFieldObjectID = ObjectTypeId.wrap(SmartObject | 0);
ObjectTypeId constant ChestObjectID = ObjectTypeId.wrap(SmartObject | 1);
ObjectTypeId constant SmartChestObjectID = ObjectTypeId.wrap(SmartObject | 2);
ObjectTypeId constant TextSignObjectID = ObjectTypeId.wrap(SmartObject | 3);
ObjectTypeId constant SmartTextSignObjectID = ObjectTypeId.wrap(SmartObject | 4);
ObjectTypeId constant PipeObjectID = ObjectTypeId.wrap(SmartObject | 5);

ObjectTypeId constant PlayerObjectID = ObjectTypeId.wrap(Misc | 0);

// TODO: should chips be their own category or misc or smart object?
ObjectTypeId constant ChipObjectID = ObjectTypeId.wrap(Misc | 1);
ObjectTypeId constant ChipBatteryObjectID = ObjectTypeId.wrap(Misc | 2);

ObjectTypeId constant GlassObjectID = ObjectTypeId.wrap(Misc | 257);
ObjectTypeId constant ClayObjectID = ObjectTypeId.wrap(Misc | 258);
ObjectTypeId constant CobblestoneObjectID = ObjectTypeId.wrap(Misc | 259);

ObjectTypeId constant CobblestoneBrickObjectID = ObjectTypeId.wrap(Misc | 260);
ObjectTypeId constant CobblestoneCarvedObjectID = ObjectTypeId.wrap(Misc | 261);
ObjectTypeId constant CobblestonePolishedObjectID = ObjectTypeId.wrap(Misc | 262);
ObjectTypeId constant CobblestoneShinglesObjectID = ObjectTypeId.wrap(Misc | 263);

ObjectTypeId constant StoneBrickObjectID = ObjectTypeId.wrap(Misc | 264);
ObjectTypeId constant StoneCarvedObjectID = ObjectTypeId.wrap(Misc | 265);
ObjectTypeId constant StonePolishedObjectID = ObjectTypeId.wrap(Misc | 266);
ObjectTypeId constant StoneShinglesObjectID = ObjectTypeId.wrap(Misc | 267);

ObjectTypeId constant BasaltBrickObjectID = ObjectTypeId.wrap(Misc | 268);
ObjectTypeId constant BasaltCarvedObjectID = ObjectTypeId.wrap(Misc | 269);
ObjectTypeId constant BasaltPolishedObjectID = ObjectTypeId.wrap(Misc | 270);
ObjectTypeId constant BasaltShinglesObjectID = ObjectTypeId.wrap(Misc | 271);

ObjectTypeId constant ClayBrickObjectID = ObjectTypeId.wrap(Misc | 272);
ObjectTypeId constant ClayCarvedObjectID = ObjectTypeId.wrap(Misc | 273);
ObjectTypeId constant ClayPolishedObjectID = ObjectTypeId.wrap(Misc | 274);
ObjectTypeId constant ClayShinglesObjectID = ObjectTypeId.wrap(Misc | 275);

ObjectTypeId constant GraniteBrickObjectID = ObjectTypeId.wrap(Misc | 276);
ObjectTypeId constant GraniteCarvedObjectID = ObjectTypeId.wrap(Misc | 277);
ObjectTypeId constant GranitePolishedObjectID = ObjectTypeId.wrap(Misc | 278);
ObjectTypeId constant GraniteShinglesObjectID = ObjectTypeId.wrap(Misc | 279);

ObjectTypeId constant QuartziteBrickObjectID = ObjectTypeId.wrap(Misc | 280);
ObjectTypeId constant QuartziteCarvedObjectID = ObjectTypeId.wrap(Misc | 281);
ObjectTypeId constant QuartzitePolishedObjectID = ObjectTypeId.wrap(Misc | 282);
ObjectTypeId constant QuartziteShinglesObjectID = ObjectTypeId.wrap(Misc | 283);

ObjectTypeId constant LimestoneBrickObjectID = ObjectTypeId.wrap(Misc | 284);
ObjectTypeId constant LimestoneCarvedObjectID = ObjectTypeId.wrap(Misc | 285);
ObjectTypeId constant LimestonePolishedObjectID = ObjectTypeId.wrap(Misc | 286);
ObjectTypeId constant LimestoneShinglesObjectID = ObjectTypeId.wrap(Misc | 287);

// Blocks that glow
ObjectTypeId constant EmberstoneObjectID = ObjectTypeId.wrap(Misc | 288);
ObjectTypeId constant MoonstoneObjectID = ObjectTypeId.wrap(Misc | 289);
ObjectTypeId constant SunstoneObjectID = ObjectTypeId.wrap(Misc | 290);

// Ore blocks
ObjectTypeId constant GoldBarObjectID = ObjectTypeId.wrap(Misc | 291);
ObjectTypeId constant SilverBarObjectID = ObjectTypeId.wrap(Misc | 292);
ObjectTypeId constant DiamondObjectID = ObjectTypeId.wrap(Misc | 293);
ObjectTypeId constant NeptuniumBarObjectID = ObjectTypeId.wrap(Misc | 294);

ObjectTypeId constant GoldCubeObjectID = ObjectTypeId.wrap(Misc | 295);
ObjectTypeId constant SilverCubeObjectID = ObjectTypeId.wrap(Misc | 296);
ObjectTypeId constant DiamondCubeObjectID = ObjectTypeId.wrap(Misc | 297);
ObjectTypeId constant NeptuniumCubeObjectID = ObjectTypeId.wrap(Misc | 298);

// Florae blocks
ObjectTypeId constant MushroomLeatherBlockObjectID = ObjectTypeId.wrap(Misc | 299);
ObjectTypeId constant CottonBlockObjectID = ObjectTypeId.wrap(Misc | 300);

// Crafting stations
ObjectTypeId constant ThermoblasterObjectID = ObjectTypeId.wrap(Misc | 301);
ObjectTypeId constant WorkbenchObjectID = ObjectTypeId.wrap(Misc | 302);
ObjectTypeId constant DyeomaticObjectID = ObjectTypeId.wrap(Misc | 303);
ObjectTypeId constant PowerStoneObjectID = ObjectTypeId.wrap(Misc | 304);

// Lumber
ObjectTypeId constant OakLumberObjectID = ObjectTypeId.wrap(Misc | 313);
ObjectTypeId constant SakuraLumberObjectID = ObjectTypeId.wrap(Misc | 314);
ObjectTypeId constant RubberLumberObjectID = ObjectTypeId.wrap(Misc | 315);
ObjectTypeId constant BirchLumberObjectID = ObjectTypeId.wrap(Misc | 316);
ObjectTypeId constant ReinforcedOakLumberObjectID = ObjectTypeId.wrap(Misc | 317);
ObjectTypeId constant ReinforcedRubberLumberObjectID = ObjectTypeId.wrap(Misc | 318);
ObjectTypeId constant ReinforcedBirchLumberObjectID = ObjectTypeId.wrap(Misc | 319);

// Dyes
ObjectTypeId constant BlueDyeObjectID = ObjectTypeId.wrap(Misc | 335);
ObjectTypeId constant BrownDyeObjectID = ObjectTypeId.wrap(Misc | 336);
ObjectTypeId constant GreenDyeObjectID = ObjectTypeId.wrap(Misc | 337);
ObjectTypeId constant MagentaDyeObjectID = ObjectTypeId.wrap(Misc | 338);
ObjectTypeId constant OrangeDyeObjectID = ObjectTypeId.wrap(Misc | 339);
ObjectTypeId constant PinkDyeObjectID = ObjectTypeId.wrap(Misc | 340);
ObjectTypeId constant PurpleDyeObjectID = ObjectTypeId.wrap(Misc | 341);
ObjectTypeId constant RedDyeObjectID = ObjectTypeId.wrap(Misc | 342);
ObjectTypeId constant TanDyeObjectID = ObjectTypeId.wrap(Misc | 343);
ObjectTypeId constant WhiteDyeObjectID = ObjectTypeId.wrap(Misc | 344);
ObjectTypeId constant YellowDyeObjectID = ObjectTypeId.wrap(Misc | 345);
ObjectTypeId constant BlackDyeObjectID = ObjectTypeId.wrap(Misc | 346);
ObjectTypeId constant SilverDyeObjectID = ObjectTypeId.wrap(Misc | 347);

// Dyed Blocks
ObjectTypeId constant BlueOakLumberObjectID = ObjectTypeId.wrap(Misc | 348);
ObjectTypeId constant BrownOakLumberObjectID = ObjectTypeId.wrap(Misc | 349);
ObjectTypeId constant GreenOakLumberObjectID = ObjectTypeId.wrap(Misc | 350);
ObjectTypeId constant MagentaOakLumberObjectID = ObjectTypeId.wrap(Misc | 351);
ObjectTypeId constant OrangeOakLumberObjectID = ObjectTypeId.wrap(Misc | 352);
ObjectTypeId constant PinkOakLumberObjectID = ObjectTypeId.wrap(Misc | 353);
ObjectTypeId constant PurpleOakLumberObjectID = ObjectTypeId.wrap(Misc | 354);
ObjectTypeId constant RedOakLumberObjectID = ObjectTypeId.wrap(Misc | 355);
ObjectTypeId constant TanOakLumberObjectID = ObjectTypeId.wrap(Misc | 356);
ObjectTypeId constant WhiteOakLumberObjectID = ObjectTypeId.wrap(Misc | 357);
ObjectTypeId constant YellowOakLumberObjectID = ObjectTypeId.wrap(Misc | 358);
ObjectTypeId constant BlackOakLumberObjectID = ObjectTypeId.wrap(Misc | 359);
ObjectTypeId constant SilverOakLumberObjectID = ObjectTypeId.wrap(Misc | 360);

ObjectTypeId constant BlueCottonBlockObjectID = ObjectTypeId.wrap(Misc | 361);
ObjectTypeId constant BrownCottonBlockObjectID = ObjectTypeId.wrap(Misc | 362);
ObjectTypeId constant GreenCottonBlockObjectID = ObjectTypeId.wrap(Misc | 363);
ObjectTypeId constant MagentaCottonBlockObjectID = ObjectTypeId.wrap(Misc | 364);
ObjectTypeId constant OrangeCottonBlockObjectID = ObjectTypeId.wrap(Misc | 365);
ObjectTypeId constant PinkCottonBlockObjectID = ObjectTypeId.wrap(Misc | 366);
ObjectTypeId constant PurpleCottonBlockObjectID = ObjectTypeId.wrap(Misc | 367);
ObjectTypeId constant RedCottonBlockObjectID = ObjectTypeId.wrap(Misc | 368);
ObjectTypeId constant TanCottonBlockObjectID = ObjectTypeId.wrap(Misc | 369);
ObjectTypeId constant WhiteCottonBlockObjectID = ObjectTypeId.wrap(Misc | 370);
ObjectTypeId constant YellowCottonBlockObjectID = ObjectTypeId.wrap(Misc | 371);
ObjectTypeId constant BlackCottonBlockObjectID = ObjectTypeId.wrap(Misc | 372);
ObjectTypeId constant SilverCottonBlockObjectID = ObjectTypeId.wrap(Misc | 373);

ObjectTypeId constant BlueGlassObjectID = ObjectTypeId.wrap(Misc | 374);
ObjectTypeId constant GreenGlassObjectID = ObjectTypeId.wrap(Misc | 375);
ObjectTypeId constant OrangeGlassObjectID = ObjectTypeId.wrap(Misc | 376);
ObjectTypeId constant PinkGlassObjectID = ObjectTypeId.wrap(Misc | 377);
ObjectTypeId constant PurpleGlassObjectID = ObjectTypeId.wrap(Misc | 378);
ObjectTypeId constant RedGlassObjectID = ObjectTypeId.wrap(Misc | 379);
ObjectTypeId constant WhiteGlassObjectID = ObjectTypeId.wrap(Misc | 380);
ObjectTypeId constant YellowGlassObjectID = ObjectTypeId.wrap(Misc | 381);
ObjectTypeId constant BlackGlassObjectID = ObjectTypeId.wrap(Misc | 382);

// TODO: move to smart objects section and adjust all ids
uint16 constant SpawnTileObjectID = 383;

// ------------------------------------------------------------
// Special Object IDs
// ------------------------------------------------------------

// Used for Recipes only
ObjectTypeId constant AnyLogObjectID = ObjectTypeId.wrap(Misc | 65_535);
ObjectTypeId constant AnyLumberObjectID = ObjectTypeId.wrap(Misc | 65_534);
ObjectTypeId constant AnyReinforcedLumberObjectID = ObjectTypeId.wrap(Misc | 65_533);
ObjectTypeId constant AnyCottonBlockObjectID = ObjectTypeId.wrap(Misc | 65_532);
ObjectTypeId constant AnyGlassObjectID = ObjectTypeId.wrap(Misc | 65_531);

// ------------------------------------------------------------
// ObjectTypeId functions
// ------------------------------------------------------------

function eq(ObjectTypeId self, ObjectTypeId other) pure returns (bool) {
  return ObjectTypeId.unwrap(self) == ObjectTypeId.unwrap(other);
}

function neq(ObjectTypeId self, ObjectTypeId other) pure returns (bool) {
  return ObjectTypeId.unwrap(self) != ObjectTypeId.unwrap(other);
}

function isTerrain(ObjectTypeId id) pure returns (bool) {
  return ObjectTypeId.unwrap(id) >> OFFSET_BITS == Terrain;
}

using { isTerrain, eq as ==, neq as != } for ObjectTypeId global;
