// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MinedOreCount } from "./codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "./codegen/tables/TotalBurnedOreCount.sol";

type ObjectTypeId is uint16;

uint8 constant OFFSET_BITS = 11;

// ------------------------------------------------------------
// Object Categories
// ------------------------------------------------------------
uint16 constant Block = 0;
uint16 constant Item = uint16(1) << OFFSET_BITS;
uint16 constant Tool = uint16(2) << OFFSET_BITS;
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
ObjectTypeId constant AirObjectID = ObjectTypeId.wrap(Block | 1);
ObjectTypeId constant WaterObjectID = ObjectTypeId.wrap(Block | 2);
ObjectTypeId constant LavaObjectID = ObjectTypeId.wrap(Block | 3);
ObjectTypeId constant GrassObjectID = ObjectTypeId.wrap(Block | 4);
ObjectTypeId constant DirtObjectID = ObjectTypeId.wrap(Block | 5);
ObjectTypeId constant MossBlockObjectID = ObjectTypeId.wrap(Block | 6);
ObjectTypeId constant SnowObjectID = ObjectTypeId.wrap(Block | 7);
ObjectTypeId constant GravelObjectID = ObjectTypeId.wrap(Block | 8);
ObjectTypeId constant SandObjectID = ObjectTypeId.wrap(Block | 9);
ObjectTypeId constant BedrockObjectID = ObjectTypeId.wrap(Block | 10);

ObjectTypeId constant StoneObjectID = ObjectTypeId.wrap(Block | 11);
ObjectTypeId constant BasaltObjectID = ObjectTypeId.wrap(Block | 12);
ObjectTypeId constant GraniteObjectID = ObjectTypeId.wrap(Block | 13);
ObjectTypeId constant QuartziteObjectID = ObjectTypeId.wrap(Block | 14);
ObjectTypeId constant LimestoneObjectID = ObjectTypeId.wrap(Block | 15);

// Ores
ObjectTypeId constant AnyOreObjectID = ObjectTypeId.wrap(Block | 16);
ObjectTypeId constant CoalOreObjectID = ObjectTypeId.wrap(Block | 17);
ObjectTypeId constant SilverOreObjectID = ObjectTypeId.wrap(Block | 18);
ObjectTypeId constant GoldOreObjectID = ObjectTypeId.wrap(Block | 19);
ObjectTypeId constant DiamondOreObjectID = ObjectTypeId.wrap(Block | 20);
ObjectTypeId constant NeptuniumOreObjectID = ObjectTypeId.wrap(Block | 21);

// Logs
ObjectTypeId constant OakLogObjectID = ObjectTypeId.wrap(Block | 22);
ObjectTypeId constant SakuraLogObjectID = ObjectTypeId.wrap(Block | 23);
ObjectTypeId constant RubberLogObjectID = ObjectTypeId.wrap(Block | 24);
ObjectTypeId constant BirchLogObjectID = ObjectTypeId.wrap(Block | 25);

// Tree leafs
ObjectTypeId constant OakLeafObjectID = ObjectTypeId.wrap(Block | 26);
ObjectTypeId constant BirchLeafObjectID = ObjectTypeId.wrap(Block | 27);
ObjectTypeId constant SakuraLeafObjectID = ObjectTypeId.wrap(Block | 28);
ObjectTypeId constant RubberLeafObjectID = ObjectTypeId.wrap(Block | 29);

// Florae
ObjectTypeId constant CactusObjectID = ObjectTypeId.wrap(Block | 30);
ObjectTypeId constant LilacObjectID = ObjectTypeId.wrap(Block | 31);
ObjectTypeId constant DandelionObjectID = ObjectTypeId.wrap(Block | 32);
ObjectTypeId constant RedMushroomObjectID = ObjectTypeId.wrap(Block | 33);
ObjectTypeId constant BellflowerObjectID = ObjectTypeId.wrap(Block | 34);
ObjectTypeId constant CottonBushObjectID = ObjectTypeId.wrap(Block | 35);
ObjectTypeId constant SwitchGrassObjectID = ObjectTypeId.wrap(Block | 36);
ObjectTypeId constant DaylilyObjectID = ObjectTypeId.wrap(Block | 37);
ObjectTypeId constant AzaleaObjectID = ObjectTypeId.wrap(Block | 38);
ObjectTypeId constant RoseObjectID = ObjectTypeId.wrap(Block | 39);

// ------------------------------------------------------------
// Non-Terrain Blocks
// ------------------------------------------------------------

ObjectTypeId constant GlassObjectID = ObjectTypeId.wrap(Block | 256);
ObjectTypeId constant ClayObjectID = ObjectTypeId.wrap(Block | 257);
ObjectTypeId constant CobblestoneObjectID = ObjectTypeId.wrap(Block | 258);

ObjectTypeId constant CobblestoneBrickObjectID = ObjectTypeId.wrap(Block | 259);
ObjectTypeId constant CobblestoneCarvedObjectID = ObjectTypeId.wrap(Block | 260);
ObjectTypeId constant CobblestonePolishedObjectID = ObjectTypeId.wrap(Block | 261);
ObjectTypeId constant CobblestoneShinglesObjectID = ObjectTypeId.wrap(Block | 262);

ObjectTypeId constant StoneBrickObjectID = ObjectTypeId.wrap(Block | 263);
ObjectTypeId constant StoneCarvedObjectID = ObjectTypeId.wrap(Block | 264);
ObjectTypeId constant StonePolishedObjectID = ObjectTypeId.wrap(Block | 265);
ObjectTypeId constant StoneShinglesObjectID = ObjectTypeId.wrap(Block | 266);

ObjectTypeId constant BasaltBrickObjectID = ObjectTypeId.wrap(Block | 267);
ObjectTypeId constant BasaltCarvedObjectID = ObjectTypeId.wrap(Block | 268);
ObjectTypeId constant BasaltPolishedObjectID = ObjectTypeId.wrap(Block | 269);
ObjectTypeId constant BasaltShinglesObjectID = ObjectTypeId.wrap(Block | 270);

ObjectTypeId constant ClayBrickObjectID = ObjectTypeId.wrap(Block | 271);
ObjectTypeId constant ClayCarvedObjectID = ObjectTypeId.wrap(Block | 272);
ObjectTypeId constant ClayPolishedObjectID = ObjectTypeId.wrap(Block | 273);
ObjectTypeId constant ClayShinglesObjectID = ObjectTypeId.wrap(Block | 274);

ObjectTypeId constant GraniteBrickObjectID = ObjectTypeId.wrap(Block | 275);
ObjectTypeId constant GraniteCarvedObjectID = ObjectTypeId.wrap(Block | 276);
ObjectTypeId constant GranitePolishedObjectID = ObjectTypeId.wrap(Block | 277);
ObjectTypeId constant GraniteShinglesObjectID = ObjectTypeId.wrap(Block | 278);

ObjectTypeId constant QuartziteBrickObjectID = ObjectTypeId.wrap(Block | 279);
ObjectTypeId constant QuartziteCarvedObjectID = ObjectTypeId.wrap(Block | 280);
ObjectTypeId constant QuartzitePolishedObjectID = ObjectTypeId.wrap(Block | 281);
ObjectTypeId constant QuartziteShinglesObjectID = ObjectTypeId.wrap(Block | 282);

ObjectTypeId constant LimestoneBrickObjectID = ObjectTypeId.wrap(Block | 283);
ObjectTypeId constant LimestoneCarvedObjectID = ObjectTypeId.wrap(Block | 284);
ObjectTypeId constant LimestonePolishedObjectID = ObjectTypeId.wrap(Block | 285);
ObjectTypeId constant LimestoneShinglesObjectID = ObjectTypeId.wrap(Block | 286);

// Blocks that glow
ObjectTypeId constant EmberstoneObjectID = ObjectTypeId.wrap(Block | 287);
ObjectTypeId constant MoonstoneObjectID = ObjectTypeId.wrap(Block | 288);
ObjectTypeId constant SunstoneObjectID = ObjectTypeId.wrap(Block | 289);

// Ore blocks
ObjectTypeId constant GoldCubeObjectID = ObjectTypeId.wrap(Block | 294);
ObjectTypeId constant SilverCubeObjectID = ObjectTypeId.wrap(Block | 295);
ObjectTypeId constant DiamondCubeObjectID = ObjectTypeId.wrap(Block | 296);
ObjectTypeId constant NeptuniumCubeObjectID = ObjectTypeId.wrap(Block | 297);

// Florae blocks
ObjectTypeId constant MushroomLeatherBlockObjectID = ObjectTypeId.wrap(Block | 298);
ObjectTypeId constant CottonBlockObjectID = ObjectTypeId.wrap(Block | 299);

// Crafting stations
ObjectTypeId constant ThermoblasterObjectID = ObjectTypeId.wrap(Block | 300);
ObjectTypeId constant WorkbenchObjectID = ObjectTypeId.wrap(Block | 301);
ObjectTypeId constant DyeomaticObjectID = ObjectTypeId.wrap(Block | 302);
ObjectTypeId constant PowerStoneObjectID = ObjectTypeId.wrap(Block | 303);

// Lumber
ObjectTypeId constant OakLumberObjectID = ObjectTypeId.wrap(Block | 312);
ObjectTypeId constant SakuraLumberObjectID = ObjectTypeId.wrap(Block | 313);
ObjectTypeId constant RubberLumberObjectID = ObjectTypeId.wrap(Block | 314);
ObjectTypeId constant BirchLumberObjectID = ObjectTypeId.wrap(Block | 315);
ObjectTypeId constant ReinforcedOakLumberObjectID = ObjectTypeId.wrap(Block | 316);
ObjectTypeId constant ReinforcedRubberLumberObjectID = ObjectTypeId.wrap(Block | 317);
ObjectTypeId constant ReinforcedBirchLumberObjectID = ObjectTypeId.wrap(Block | 318);

// Dyed Blocks
ObjectTypeId constant BlueOakLumberObjectID = ObjectTypeId.wrap(Block | 347);
ObjectTypeId constant BrownOakLumberObjectID = ObjectTypeId.wrap(Block | 348);
ObjectTypeId constant GreenOakLumberObjectID = ObjectTypeId.wrap(Block | 349);
ObjectTypeId constant MagentaOakLumberObjectID = ObjectTypeId.wrap(Block | 350);
ObjectTypeId constant OrangeOakLumberObjectID = ObjectTypeId.wrap(Block | 351);
ObjectTypeId constant PinkOakLumberObjectID = ObjectTypeId.wrap(Block | 352);
ObjectTypeId constant PurpleOakLumberObjectID = ObjectTypeId.wrap(Block | 353);
ObjectTypeId constant RedOakLumberObjectID = ObjectTypeId.wrap(Block | 354);
ObjectTypeId constant TanOakLumberObjectID = ObjectTypeId.wrap(Block | 355);
ObjectTypeId constant WhiteOakLumberObjectID = ObjectTypeId.wrap(Block | 356);
ObjectTypeId constant YellowOakLumberObjectID = ObjectTypeId.wrap(Block | 357);
ObjectTypeId constant BlackOakLumberObjectID = ObjectTypeId.wrap(Block | 358);
ObjectTypeId constant SilverOakLumberObjectID = ObjectTypeId.wrap(Block | 359);

ObjectTypeId constant BlueCottonBlockObjectID = ObjectTypeId.wrap(Block | 360);
ObjectTypeId constant BrownCottonBlockObjectID = ObjectTypeId.wrap(Block | 361);
ObjectTypeId constant GreenCottonBlockObjectID = ObjectTypeId.wrap(Block | 362);
ObjectTypeId constant MagentaCottonBlockObjectID = ObjectTypeId.wrap(Block | 363);
ObjectTypeId constant OrangeCottonBlockObjectID = ObjectTypeId.wrap(Block | 364);
ObjectTypeId constant PinkCottonBlockObjectID = ObjectTypeId.wrap(Block | 365);
ObjectTypeId constant PurpleCottonBlockObjectID = ObjectTypeId.wrap(Block | 366);
ObjectTypeId constant RedCottonBlockObjectID = ObjectTypeId.wrap(Block | 367);
ObjectTypeId constant TanCottonBlockObjectID = ObjectTypeId.wrap(Block | 368);
ObjectTypeId constant WhiteCottonBlockObjectID = ObjectTypeId.wrap(Block | 369);
ObjectTypeId constant YellowCottonBlockObjectID = ObjectTypeId.wrap(Block | 370);
ObjectTypeId constant BlackCottonBlockObjectID = ObjectTypeId.wrap(Block | 371);
ObjectTypeId constant SilverCottonBlockObjectID = ObjectTypeId.wrap(Block | 372);

ObjectTypeId constant BlueGlassObjectID = ObjectTypeId.wrap(Block | 373);
ObjectTypeId constant GreenGlassObjectID = ObjectTypeId.wrap(Block | 374);
ObjectTypeId constant OrangeGlassObjectID = ObjectTypeId.wrap(Block | 375);
ObjectTypeId constant PinkGlassObjectID = ObjectTypeId.wrap(Block | 376);
ObjectTypeId constant PurpleGlassObjectID = ObjectTypeId.wrap(Block | 377);
ObjectTypeId constant RedGlassObjectID = ObjectTypeId.wrap(Block | 378);
ObjectTypeId constant WhiteGlassObjectID = ObjectTypeId.wrap(Block | 379);
ObjectTypeId constant YellowGlassObjectID = ObjectTypeId.wrap(Block | 380);
ObjectTypeId constant BlackGlassObjectID = ObjectTypeId.wrap(Block | 381);

// Smart objects
// TODO: should these be their own category? for now just leaving some space between previous blocks and these
ObjectTypeId constant ForceFieldObjectID = ObjectTypeId.wrap(Block | 600);
ObjectTypeId constant ChestObjectID = ObjectTypeId.wrap(Block | 601);
ObjectTypeId constant SmartChestObjectID = ObjectTypeId.wrap(Block | 602);
ObjectTypeId constant TextSignObjectID = ObjectTypeId.wrap(Block | 603);
ObjectTypeId constant SmartTextSignObjectID = ObjectTypeId.wrap(Block | 604);
ObjectTypeId constant PipeObjectID = ObjectTypeId.wrap(Block | 605);
ObjectTypeId constant SpawnTileObjectID = ObjectTypeId.wrap(Block | 606);

// ------------------------------------------------------------
// Tools
// ------------------------------------------------------------

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

// ------------------------------------------------------------
// Items
// ------------------------------------------------------------

// Dyes
ObjectTypeId constant BlueDyeObjectID = ObjectTypeId.wrap(Item | 0);
ObjectTypeId constant BrownDyeObjectID = ObjectTypeId.wrap(Item | 1);
ObjectTypeId constant GreenDyeObjectID = ObjectTypeId.wrap(Item | 2);
ObjectTypeId constant MagentaDyeObjectID = ObjectTypeId.wrap(Item | 3);
ObjectTypeId constant OrangeDyeObjectID = ObjectTypeId.wrap(Item | 4);
ObjectTypeId constant PinkDyeObjectID = ObjectTypeId.wrap(Item | 5);
ObjectTypeId constant PurpleDyeObjectID = ObjectTypeId.wrap(Item | 6);
ObjectTypeId constant RedDyeObjectID = ObjectTypeId.wrap(Item | 7);
ObjectTypeId constant TanDyeObjectID = ObjectTypeId.wrap(Item | 8);
ObjectTypeId constant WhiteDyeObjectID = ObjectTypeId.wrap(Item | 9);
ObjectTypeId constant YellowDyeObjectID = ObjectTypeId.wrap(Item | 10);
ObjectTypeId constant BlackDyeObjectID = ObjectTypeId.wrap(Item | 11);
ObjectTypeId constant SilverDyeObjectID = ObjectTypeId.wrap(Item | 12);

// Ore bars
ObjectTypeId constant GoldBarObjectID = ObjectTypeId.wrap(Item | 13);
ObjectTypeId constant SilverBarObjectID = ObjectTypeId.wrap(Item | 14);
ObjectTypeId constant DiamondObjectID = ObjectTypeId.wrap(Item | 15);
ObjectTypeId constant NeptuniumBarObjectID = ObjectTypeId.wrap(Item | 16);

// TODO: should chips be their own category or misc or smart object?
ObjectTypeId constant ChipObjectID = ObjectTypeId.wrap(Item | 17);
ObjectTypeId constant ChipBatteryObjectID = ObjectTypeId.wrap(Item | 18);

// ------------------------------------------------------------
// Special Object IDs
// ------------------------------------------------------------

ObjectTypeId constant PlayerObjectID = ObjectTypeId.wrap(Misc | 0);

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

library ObjectTypeIdLib {
  struct ObjectAmount {
    ObjectTypeId objectTypeId;
    uint16 amount;
  }

  function unwrap(ObjectTypeId self) internal pure returns (uint16) {
    return ObjectTypeId.unwrap(self);
  }

  function isBlock(ObjectTypeId id) internal pure returns (bool) {
    return !id.isNull() && ObjectTypeId.unwrap(id) >> OFFSET_BITS == Block;
  }

  function isMineable(ObjectTypeId self) internal pure returns (bool) {
    return self.isBlock() && self != AirObjectID && self != WaterObjectID;
  }

  function isTool(ObjectTypeId id) internal pure returns (bool) {
    return ObjectTypeId.unwrap(id) >> OFFSET_BITS == Tool;
  }

  function isItem(ObjectTypeId id) internal pure returns (bool) {
    return ObjectTypeId.unwrap(id) >> OFFSET_BITS == Item;
  }

  function isOre(ObjectTypeId objectTypeId) internal pure returns (bool) {
    return
      objectTypeId == CoalOreObjectID ||
      objectTypeId == SilverOreObjectID ||
      objectTypeId == GoldOreObjectID ||
      objectTypeId == DiamondOreObjectID ||
      objectTypeId == NeptuniumOreObjectID ||
      objectTypeId == AnyOreObjectID;
  }

  function isNull(ObjectTypeId self) internal pure returns (bool) {
    return self == NullObjectTypeId;
  }

  function isAny(ObjectTypeId self) internal pure returns (bool) {
    return
      self == AnyLogObjectID ||
      self == AnyLumberObjectID ||
      self == AnyGlassObjectID ||
      self == AnyReinforcedLumberObjectID ||
      self == AnyCottonBlockObjectID;
  }

  function getObjectTypes(ObjectTypeId self) internal pure returns (ObjectTypeId[] memory) {
    if (self == AnyLogObjectID) {
      return getLogObjectTypes();
    }

    if (self == AnyLumberObjectID) {
      return getLumberObjectTypes();
    }

    if (self == AnyGlassObjectID) {
      return getGlassObjectTypes();
    }

    if (self == AnyCottonBlockObjectID) {
      return getCottonBlockObjectTypes();
    }

    if (self == AnyReinforcedLumberObjectID) {
      return getReinforcedLumberObjectTypes();
    }

    // Return empty array for non-Any types
    return new ObjectTypeId[](0);
  }

  /// @dev Get ore amounts that should be burned when this object is burned
  /// Currently it only supports tools, and assumes that only a single type of ore is used
  function getOreAmount(ObjectTypeId self) internal pure returns (ObjectAmount memory) {
    // Silver tools
    if (self == SilverPickObjectID || self == SilverAxeObjectID) {
      return ObjectAmount(SilverOreObjectID, 4); // 4 silver bars = 4 ores
    }
    if (self == SilverWhackerObjectID) {
      return ObjectAmount(SilverOreObjectID, 6); // 6 silver bars = 6 ores
    }

    // Gold tools
    if (self == GoldPickObjectID || self == GoldAxeObjectID) {
      return ObjectAmount(GoldOreObjectID, 4); // 4 gold bars = 4 ores
    }

    // Diamond tools
    if (self == DiamondPickObjectID || self == DiamondAxeObjectID) {
      return ObjectAmount(DiamondOreObjectID, 4); // 4 diamonds
    }

    // Neptunium tools
    if (self == NeptuniumPickObjectID || self == NeptuniumAxeObjectID) {
      return ObjectAmount(NeptuniumOreObjectID, 4); // 4 neptunium bars = 4 ores
    }

    // Return zero amount for any other tool
    return ObjectAmount(NullObjectTypeId, 0);
  }

  function burnOres(ObjectTypeId self) internal {
    ObjectAmount memory ores = self.getOreAmount();
    ObjectTypeId objectTypeId = ores.objectTypeId;
    if (objectTypeId != NullObjectTypeId) {
      uint256 amount = ores.amount;
      // This increases the availability of the ores being burned
      MinedOreCount._set(objectTypeId, MinedOreCount._get(objectTypeId) - amount);
      // This allows the same amount of ores to respawn
      TotalBurnedOreCount._set(TotalBurnedOreCount._get() + amount);
    }
  }
}

function getLogObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](4);
  result[0] = OakLogObjectID;
  result[1] = SakuraLogObjectID;
  result[2] = BirchLogObjectID;
  result[3] = RubberLogObjectID;
  return result;
}

function getReinforcedLumberObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](3);
  result[0] = ReinforcedOakLumberObjectID;
  result[1] = ReinforcedRubberLumberObjectID;
  result[2] = ReinforcedBirchLumberObjectID;
  return result;
}

function getCottonBlockObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](13);
  result[0] = CottonBlockObjectID;
  result[1] = BlueCottonBlockObjectID;
  result[2] = BrownCottonBlockObjectID;
  result[3] = GreenCottonBlockObjectID;
  result[4] = MagentaCottonBlockObjectID;
  result[5] = OrangeCottonBlockObjectID;
  result[6] = PinkCottonBlockObjectID;
  result[7] = PurpleCottonBlockObjectID;
  result[8] = RedCottonBlockObjectID;
  result[9] = TanCottonBlockObjectID;
  result[10] = WhiteCottonBlockObjectID;
  result[11] = YellowCottonBlockObjectID;
  result[12] = BlackCottonBlockObjectID;
  return result;
}

function getLumberObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](17);
  result[0] = OakLumberObjectID;
  result[1] = SakuraLumberObjectID;
  result[2] = RubberLumberObjectID;
  result[3] = BirchLumberObjectID;
  result[4] = BlueOakLumberObjectID;
  result[5] = BrownOakLumberObjectID;
  result[6] = GreenOakLumberObjectID;
  result[7] = MagentaOakLumberObjectID;
  result[8] = OrangeOakLumberObjectID;
  result[9] = PinkOakLumberObjectID;
  result[10] = PurpleOakLumberObjectID;
  result[11] = RedOakLumberObjectID;
  result[12] = TanOakLumberObjectID;
  result[13] = WhiteOakLumberObjectID;
  result[14] = YellowOakLumberObjectID;
  result[15] = BlackOakLumberObjectID;
  result[16] = SilverOakLumberObjectID;
  return result;
}

function getGlassObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](10);
  result[0] = GlassObjectID;
  result[1] = BlueGlassObjectID;
  result[2] = GreenGlassObjectID;
  result[3] = OrangeGlassObjectID;
  result[4] = PinkGlassObjectID;
  result[5] = PurpleGlassObjectID;
  result[6] = RedGlassObjectID;
  result[7] = WhiteGlassObjectID;
  result[8] = YellowGlassObjectID;
  result[9] = BlackGlassObjectID;
  return result;
}

using ObjectTypeIdLib for ObjectTypeId global;
using { eq as ==, neq as != } for ObjectTypeId global;
