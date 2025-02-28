// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { MinedOreCount } from "./codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "./codegen/tables/TotalBurnedOreCount.sol";

type ObjectType is uint16;

uint8 constant OFFSET_BITS = 11;
// First 5 bits set to 11111
uint16 constant CATEGORY_MASK = 0xF800;

// ------------------------------------------------------------
// Object Categories
// ------------------------------------------------------------
uint16 constant Block = 0;
uint16 constant Item = uint16(1) << OFFSET_BITS;
uint16 constant Tool = uint16(2) << OFFSET_BITS;
// TODO: placeholder
uint16 constant Misc = uint16(3) << OFFSET_BITS;

// ------------------------------------------------------------
// Object Types
// ------------------------------------------------------------

library ObjectTypes {
  // Note: Do not use 0 as an object type, as it is reserved
  ObjectType constant Null = ObjectType.wrap(0);

  // ------------------------------------------------------------
  // Terrain Blocks (1-255 is reserved for terrain blocks)
  // ------------------------------------------------------------
  ObjectType constant Air = ObjectType.wrap(Block | 1);
  ObjectType constant Water = ObjectType.wrap(Block | 2);
  ObjectType constant Lava = ObjectType.wrap(Block | 3);
  ObjectType constant Grass = ObjectType.wrap(Block | 4);
  ObjectType constant Dirt = ObjectType.wrap(Block | 5);
  ObjectType constant MossBlock = ObjectType.wrap(Block | 6);
  ObjectType constant Snow = ObjectType.wrap(Block | 7);
  ObjectType constant Gravel = ObjectType.wrap(Block | 8);
  ObjectType constant Sand = ObjectType.wrap(Block | 9);
  ObjectType constant Bedrock = ObjectType.wrap(Block | 10);

  ObjectType constant Stone = ObjectType.wrap(Block | 11);
  ObjectType constant Basalt = ObjectType.wrap(Block | 12);
  ObjectType constant Granite = ObjectType.wrap(Block | 13);
  ObjectType constant Quartzite = ObjectType.wrap(Block | 14);
  ObjectType constant Limestone = ObjectType.wrap(Block | 15);

  // Ores
  ObjectType constant AnyOre = ObjectType.wrap(Block | 16);
  ObjectType constant CoalOre = ObjectType.wrap(Block | 17);
  ObjectType constant SilverOre = ObjectType.wrap(Block | 18);
  ObjectType constant GoldOre = ObjectType.wrap(Block | 19);
  ObjectType constant DiamondOre = ObjectType.wrap(Block | 20);
  ObjectType constant NeptuniumOre = ObjectType.wrap(Block | 21);

  // Logs
  ObjectType constant OakLog = ObjectType.wrap(Block | 22);
  ObjectType constant SakuraLog = ObjectType.wrap(Block | 23);
  ObjectType constant RubberLog = ObjectType.wrap(Block | 24);
  ObjectType constant BirchLog = ObjectType.wrap(Block | 25);

  // Tree leafs
  ObjectType constant OakLeaf = ObjectType.wrap(Block | 26);
  ObjectType constant BirchLeaf = ObjectType.wrap(Block | 27);
  ObjectType constant SakuraLeaf = ObjectType.wrap(Block | 28);
  ObjectType constant RubberLeaf = ObjectType.wrap(Block | 29);

  // Florae
  ObjectType constant Cactus = ObjectType.wrap(Block | 30);
  ObjectType constant Lilac = ObjectType.wrap(Block | 31);
  ObjectType constant Dandelion = ObjectType.wrap(Block | 32);
  ObjectType constant RedMushroom = ObjectType.wrap(Block | 33);
  ObjectType constant Bellflower = ObjectType.wrap(Block | 34);
  ObjectType constant CottonBush = ObjectType.wrap(Block | 35);
  ObjectType constant SwitchGrass = ObjectType.wrap(Block | 36);
  ObjectType constant Daylily = ObjectType.wrap(Block | 37);
  ObjectType constant Azalea = ObjectType.wrap(Block | 38);
  ObjectType constant Rose = ObjectType.wrap(Block | 39);

  // ------------------------------------------------------------
  // Non-Terrain Blocks
  // ------------------------------------------------------------

  ObjectType constant Glass = ObjectType.wrap(Block | 256);
  ObjectType constant Clay = ObjectType.wrap(Block | 257);
  ObjectType constant Cobblestone = ObjectType.wrap(Block | 258);

  ObjectType constant CobblestoneBrick = ObjectType.wrap(Block | 259);
  ObjectType constant CobblestoneCarved = ObjectType.wrap(Block | 260);
  ObjectType constant CobblestonePolished = ObjectType.wrap(Block | 261);
  ObjectType constant CobblestoneShingles = ObjectType.wrap(Block | 262);

  ObjectType constant StoneBrick = ObjectType.wrap(Block | 263);
  ObjectType constant StoneCarved = ObjectType.wrap(Block | 264);
  ObjectType constant StonePolished = ObjectType.wrap(Block | 265);
  ObjectType constant StoneShingles = ObjectType.wrap(Block | 266);

  ObjectType constant BasaltBrick = ObjectType.wrap(Block | 267);
  ObjectType constant BasaltCarved = ObjectType.wrap(Block | 268);
  ObjectType constant BasaltPolished = ObjectType.wrap(Block | 269);
  ObjectType constant BasaltShingles = ObjectType.wrap(Block | 270);

  ObjectType constant ClayBrick = ObjectType.wrap(Block | 271);
  ObjectType constant ClayCarved = ObjectType.wrap(Block | 272);
  ObjectType constant ClayPolished = ObjectType.wrap(Block | 273);
  ObjectType constant ClayShingles = ObjectType.wrap(Block | 274);

  ObjectType constant GraniteBrick = ObjectType.wrap(Block | 275);
  ObjectType constant GraniteCarved = ObjectType.wrap(Block | 276);
  ObjectType constant GranitePolished = ObjectType.wrap(Block | 277);
  ObjectType constant GraniteShingles = ObjectType.wrap(Block | 278);

  ObjectType constant QuartziteBrick = ObjectType.wrap(Block | 279);
  ObjectType constant QuartziteCarved = ObjectType.wrap(Block | 280);
  ObjectType constant QuartzitePolished = ObjectType.wrap(Block | 281);
  ObjectType constant QuartziteShingles = ObjectType.wrap(Block | 282);

  ObjectType constant LimestoneBrick = ObjectType.wrap(Block | 283);
  ObjectType constant LimestoneCarved = ObjectType.wrap(Block | 284);
  ObjectType constant LimestonePolished = ObjectType.wrap(Block | 285);
  ObjectType constant LimestoneShingles = ObjectType.wrap(Block | 286);

  // Blocks that glow
  ObjectType constant Emberstone = ObjectType.wrap(Block | 287);
  ObjectType constant Moonstone = ObjectType.wrap(Block | 288);
  ObjectType constant Sunstone = ObjectType.wrap(Block | 289);

  // Ore blocks
  ObjectType constant GoldCube = ObjectType.wrap(Block | 294);
  ObjectType constant SilverCube = ObjectType.wrap(Block | 295);
  ObjectType constant DiamondCube = ObjectType.wrap(Block | 296);
  ObjectType constant NeptuniumCube = ObjectType.wrap(Block | 297);

  // Florae blocks
  ObjectType constant MushroomLeatherBlock = ObjectType.wrap(Block | 298);
  ObjectType constant CottonBlock = ObjectType.wrap(Block | 299);

  // Crafting stations
  ObjectType constant Thermoblaster = ObjectType.wrap(Block | 300);
  ObjectType constant Workbench = ObjectType.wrap(Block | 301);
  ObjectType constant Dyeomatic = ObjectType.wrap(Block | 302);
  ObjectType constant PowerStone = ObjectType.wrap(Block | 303);

  // Lumber
  ObjectType constant OakLumber = ObjectType.wrap(Block | 312);
  ObjectType constant SakuraLumber = ObjectType.wrap(Block | 313);
  ObjectType constant RubberLumber = ObjectType.wrap(Block | 314);
  ObjectType constant BirchLumber = ObjectType.wrap(Block | 315);
  ObjectType constant ReinforcedOakLumber = ObjectType.wrap(Block | 316);
  ObjectType constant ReinforcedRubberLumber = ObjectType.wrap(Block | 317);
  ObjectType constant ReinforcedBirchLumber = ObjectType.wrap(Block | 318);

  // Dyed Blocks
  ObjectType constant BlueOakLumber = ObjectType.wrap(Block | 347);
  ObjectType constant BrownOakLumber = ObjectType.wrap(Block | 348);
  ObjectType constant GreenOakLumber = ObjectType.wrap(Block | 349);
  ObjectType constant MagentaOakLumber = ObjectType.wrap(Block | 350);
  ObjectType constant OrangeOakLumber = ObjectType.wrap(Block | 351);
  ObjectType constant PinkOakLumber = ObjectType.wrap(Block | 352);
  ObjectType constant PurpleOakLumber = ObjectType.wrap(Block | 353);
  ObjectType constant RedOakLumber = ObjectType.wrap(Block | 354);
  ObjectType constant TanOakLumber = ObjectType.wrap(Block | 355);
  ObjectType constant WhiteOakLumber = ObjectType.wrap(Block | 356);
  ObjectType constant YellowOakLumber = ObjectType.wrap(Block | 357);
  ObjectType constant BlackOakLumber = ObjectType.wrap(Block | 358);
  ObjectType constant SilverOakLumber = ObjectType.wrap(Block | 359);

  ObjectType constant BlueCottonBlock = ObjectType.wrap(Block | 360);
  ObjectType constant BrownCottonBlock = ObjectType.wrap(Block | 361);
  ObjectType constant GreenCottonBlock = ObjectType.wrap(Block | 362);
  ObjectType constant MagentaCottonBlock = ObjectType.wrap(Block | 363);
  ObjectType constant OrangeCottonBlock = ObjectType.wrap(Block | 364);
  ObjectType constant PinkCottonBlock = ObjectType.wrap(Block | 365);
  ObjectType constant PurpleCottonBlock = ObjectType.wrap(Block | 366);
  ObjectType constant RedCottonBlock = ObjectType.wrap(Block | 367);
  ObjectType constant TanCottonBlock = ObjectType.wrap(Block | 368);
  ObjectType constant WhiteCottonBlock = ObjectType.wrap(Block | 369);
  ObjectType constant YellowCottonBlock = ObjectType.wrap(Block | 370);
  ObjectType constant BlackCottonBlock = ObjectType.wrap(Block | 371);
  ObjectType constant SilverCottonBlock = ObjectType.wrap(Block | 372);

  ObjectType constant BlueGlass = ObjectType.wrap(Block | 373);
  ObjectType constant GreenGlass = ObjectType.wrap(Block | 374);
  ObjectType constant OrangeGlass = ObjectType.wrap(Block | 375);
  ObjectType constant PinkGlass = ObjectType.wrap(Block | 376);
  ObjectType constant PurpleGlass = ObjectType.wrap(Block | 377);
  ObjectType constant RedGlass = ObjectType.wrap(Block | 378);
  ObjectType constant WhiteGlass = ObjectType.wrap(Block | 379);
  ObjectType constant YellowGlass = ObjectType.wrap(Block | 380);
  ObjectType constant BlackGlass = ObjectType.wrap(Block | 381);

  // Smart objects
  // TODO: should these be their own category? for now just leaving some space between previous blocks and these
  ObjectType constant ForceField = ObjectType.wrap(Block | 600);
  ObjectType constant Chest = ObjectType.wrap(Block | 601);
  ObjectType constant SmartChest = ObjectType.wrap(Block | 602);
  ObjectType constant TextSign = ObjectType.wrap(Block | 603);
  ObjectType constant SmartTextSign = ObjectType.wrap(Block | 604);
  ObjectType constant Pipe = ObjectType.wrap(Block | 605);
  ObjectType constant SpawnTile = ObjectType.wrap(Block | 606);
  ObjectType constant Bed = ObjectType.wrap(Block | 607);

  // ------------------------------------------------------------
  // Tools
  // ------------------------------------------------------------

  ObjectType constant WoodenPick = ObjectType.wrap(Tool | 0);
  ObjectType constant WoodenAxe = ObjectType.wrap(Tool | 1);
  ObjectType constant WoodenWhacker = ObjectType.wrap(Tool | 2);
  ObjectType constant StonePick = ObjectType.wrap(Tool | 3);
  ObjectType constant StoneAxe = ObjectType.wrap(Tool | 4);
  ObjectType constant StoneWhacker = ObjectType.wrap(Tool | 5);
  ObjectType constant SilverPick = ObjectType.wrap(Tool | 6);
  ObjectType constant SilverAxe = ObjectType.wrap(Tool | 7);
  ObjectType constant SilverWhacker = ObjectType.wrap(Tool | 8);
  ObjectType constant GoldPick = ObjectType.wrap(Tool | 9);
  ObjectType constant GoldAxe = ObjectType.wrap(Tool | 10);
  ObjectType constant DiamondPick = ObjectType.wrap(Tool | 11);
  ObjectType constant DiamondAxe = ObjectType.wrap(Tool | 12);
  ObjectType constant NeptuniumPick = ObjectType.wrap(Tool | 13);
  ObjectType constant NeptuniumAxe = ObjectType.wrap(Tool | 14);

  // ------------------------------------------------------------
  // Items
  // ------------------------------------------------------------

  // Dyes
  ObjectType constant BlueDye = ObjectType.wrap(Item | 0);
  ObjectType constant BrownDye = ObjectType.wrap(Item | 1);
  ObjectType constant GreenDye = ObjectType.wrap(Item | 2);
  ObjectType constant MagentaDye = ObjectType.wrap(Item | 3);
  ObjectType constant OrangeDye = ObjectType.wrap(Item | 4);
  ObjectType constant PinkDye = ObjectType.wrap(Item | 5);
  ObjectType constant PurpleDye = ObjectType.wrap(Item | 6);
  ObjectType constant RedDye = ObjectType.wrap(Item | 7);
  ObjectType constant TanDye = ObjectType.wrap(Item | 8);
  ObjectType constant WhiteDye = ObjectType.wrap(Item | 9);
  ObjectType constant YellowDye = ObjectType.wrap(Item | 10);
  ObjectType constant BlackDye = ObjectType.wrap(Item | 11);
  ObjectType constant SilverDye = ObjectType.wrap(Item | 12);

  // Ore bars
  ObjectType constant GoldBar = ObjectType.wrap(Item | 13);
  ObjectType constant SilverBar = ObjectType.wrap(Item | 14);
  ObjectType constant Diamond = ObjectType.wrap(Item | 15);
  ObjectType constant NeptuniumBar = ObjectType.wrap(Item | 16);

  // TODO: should chips be their own category or misc or smart object?
  ObjectType constant Chip = ObjectType.wrap(Item | 17);
  ObjectType constant ChipBattery = ObjectType.wrap(Item | 18);

  // ------------------------------------------------------------
  // Special Object Types
  // ------------------------------------------------------------

  ObjectType constant Player = ObjectType.wrap(Misc | 0);

  // Used for Recipes only
  ObjectType constant AnyLog = ObjectType.wrap(Misc | 65_535);
  ObjectType constant AnyLumber = ObjectType.wrap(Misc | 65_534);
  ObjectType constant AnyReinforcedLumber = ObjectType.wrap(Misc | 65_533);
  ObjectType constant AnyCottonBlock = ObjectType.wrap(Misc | 65_532);
  ObjectType constant AnyGlass = ObjectType.wrap(Misc | 65_531);
}

// ------------------------------------------------------------
// ObjectType functions
// ------------------------------------------------------------

struct ObjectAmount {
  ObjectType objectType;
  uint16 amount;
}

library ObjectTypeLib {
  function unwrap(ObjectType self) internal pure returns (uint16) {
    return ObjectType.unwrap(self);
  }

  function getCategory(ObjectType self) internal pure returns (uint16) {
    return ObjectType.unwrap(self) & CATEGORY_MASK;
  }

  function isBlock(ObjectType self) internal pure returns (bool) {
    return !self.isNull() && self.getCategory() == Block;
  }

  function isMineable(ObjectType self) internal pure returns (bool) {
    return self.isBlock() && self != Air && self != Water;
  }

  function isTool(ObjectType self) internal pure returns (bool) {
    return self.getCategory() == Tool;
  }

  function isItem(ObjectType self) internal pure returns (bool) {
    return self.getCategory() == Item;
  }

  function isOre(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == CoalOre ||
      objectType == SilverOre ||
      objectType == GoldOre ||
      objectType == DiamondOre ||
      objectType == NeptuniumOre ||
      objectType == AnyOre;
  }

  function isNull(ObjectType self) internal pure returns (bool) {
    return self == NullObjectType;
  }

  function isAny(ObjectType self) internal pure returns (bool) {
    return
      self == AnyLog || self == AnyLumber || self == AnyGlass || self == AnyReinforcedLumber || self == AnyCottonBlock;
  }

  function isPick(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == WoodenAxe ||
      objectType == StonePick ||
      objectType == SilverPick ||
      objectType == GoldPick ||
      objectType == NeptuniumPick ||
      objectType == DiamondPick;
  }

  function isAxe(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == WoodenAxe ||
      objectType == StoneAxe ||
      objectType == SilverAxe ||
      objectType == GoldAxe ||
      objectType == NeptuniumAxe ||
      objectType == DiamondAxe;
  }

  function isWhacker(ObjectType objectType) internal pure returns (bool) {
    return objectType == WoodenWhacker || objectType == StoneWhacker || objectType == SilverWhacker;
  }

  function isLog(ObjectType objectType) internal pure returns (bool) {
    return objectType == OakLog || objectType == SakuraLog || objectType == BirchLog || objectType == RubberLog;
  }

  function isLumber(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == OakLumber ||
      objectType == SakuraLumber ||
      objectType == RubberLumber ||
      objectType == BirchLumber ||
      objectType == BlueOakLumber ||
      objectType == BrownOakLumber ||
      objectType == GreenOakLumber ||
      objectType == MagentaOakLumber ||
      objectType == OrangeOakLumber ||
      objectType == PinkOakLumber ||
      objectType == PurpleOakLumber ||
      objectType == RedOakLumber ||
      objectType == TanOakLumber ||
      objectType == WhiteOakLumber ||
      objectType == YellowOakLumber ||
      objectType == BlackOakLumber ||
      objectType == SilverOakLumber;
  }

  function isGlass(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == Glass ||
      objectType == BlueGlass ||
      objectType == GreenGlass ||
      objectType == OrangeGlass ||
      objectType == PinkGlass ||
      objectType == PurpleGlass ||
      objectType == RedGlass ||
      objectType == WhiteGlass ||
      objectType == YellowGlass ||
      objectType == BlackGlass;
  }

  function isCottonBlock(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == CottonBlock ||
      objectType == BlueCottonBlock ||
      objectType == BrownCottonBlock ||
      objectType == GreenCottonBlock ||
      objectType == MagentaCottonBlock ||
      objectType == OrangeCottonBlock ||
      objectType == PinkCottonBlock ||
      objectType == PurpleCottonBlock ||
      objectType == RedCottonBlock ||
      objectType == TanCottonBlock ||
      objectType == WhiteCottonBlock ||
      objectType == YellowCottonBlock ||
      objectType == BlackCottonBlock ||
      objectType == SilverCottonBlock;
  }

  function isReinforcedLumber(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == ReinforcedOakLumber || objectType == ReinforcedRubberLumber || objectType == ReinforcedBirchLumber;
  }

  function isStone(ObjectType objectType) internal pure returns (bool) {
    return
      objectType == Stone ||
      objectType == Cobblestone ||
      objectType == Basalt ||
      objectType == Clay ||
      objectType == Granite ||
      objectType == Quartzite ||
      objectType == Limestone;
  }

  function isStorageContainer(ObjectType objectType) internal pure returns (bool) {
    return objectType == Chest || objectType == SmartChest;
  }

  function isBasicDisplay(ObjectType objectType) internal pure returns (bool) {
    return objectType == TextSign;
  }

  function isSmartItem(ObjectType objectType) internal pure returns (bool) {
    return objectType == SmartChest || objectType == SmartTextSign;
  }

  function getObjectTypes(ObjectType self) internal pure returns (ObjectType[] memory) {
    if (self == AnyLog) {
      return getLogObjectTypes();
    }

    if (self == AnyLumber) {
      return getLumberObjectTypes();
    }

    if (self == AnyGlass) {
      return getGlassObjectTypes();
    }

    if (self == AnyCottonBlock) {
      return getCottonBlockObjectTypes();
    }

    if (self == AnyReinforcedLumber) {
      return getReinforcedLumberObjectTypes();
    }

    // Return empty array for non-Any types
    return new ObjectType[](0);
  }

  /// @dev Get ore amounts that should be burned when this object is burned
  /// Currently it only supports tools, and assumes that only a single type of ore is used
  function getOreAmount(ObjectType self) internal pure returns (ObjectAmount memory) {
    // Silver tools
    if (self == SilverPick || self == SilverAxe) {
      return ObjectAmount(SilverOre, 4); // 4 silver bars = 4 ores
    }
    if (self == SilverWhacker) {
      return ObjectAmount(SilverOre, 6); // 6 silver bars = 6 ores
    }

    // Gold tools
    if (self == GoldPick || self == GoldAxe) {
      return ObjectAmount(GoldOre, 4); // 4 gold bars = 4 ores
    }

    // Diamond tools
    if (self == DiamondPick || self == DiamondAxe) {
      return ObjectAmount(DiamondOre, 4); // 4 diamonds
    }

    // Neptunium tools
    if (self == NeptuniumPick || self == NeptuniumAxe) {
      return ObjectAmount(NeptuniumOre, 4); // 4 neptunium bars = 4 ores
    }

    // Return zero amount for any other tool
    return ObjectAmount(NullObjectType, 0);
  }

  function burnOres(ObjectType self) internal {
    ObjectAmount memory ores = self.getOreAmount();
    ObjectType objectType = ores.objectType;
    if (objectType != NullObjectType) {
      uint256 amount = ores.amount;
      // This increases the availability of the ores being burned
      MinedOreCount._set(objectType, MinedOreCount._get(objectType) - amount);
      // This allows the same amount of ores to respawn
      TotalBurnedOreCount._set(TotalBurnedOreCount._get() + amount);
    }
  }
}

function getLogObjectTypes() pure returns (ObjectType[] memory) {
  ObjectType[] memory result = new ObjectType[](4);
  result[0] = OakLog;
  result[1] = SakuraLog;
  result[2] = BirchLog;
  result[3] = RubberLog;
  return result;
}

function getReinforcedLumberObjectTypes() pure returns (ObjectType[] memory) {
  ObjectType[] memory result = new ObjectType[](3);
  result[0] = ReinforcedOakLumber;
  result[1] = ReinforcedRubberLumber;
  result[2] = ReinforcedBirchLumber;
  return result;
}

function getCottonBlockObjectTypes() pure returns (ObjectType[] memory) {
  ObjectType[] memory result = new ObjectType[](13);
  result[0] = CottonBlock;
  result[1] = BlueCottonBlock;
  result[2] = BrownCottonBlock;
  result[3] = GreenCottonBlock;
  result[4] = MagentaCottonBlock;
  result[5] = OrangeCottonBlock;
  result[6] = PinkCottonBlock;
  result[7] = PurpleCottonBlock;
  result[8] = RedCottonBlock;
  result[9] = TanCottonBlock;
  result[10] = WhiteCottonBlock;
  result[11] = YellowCottonBlock;
  result[12] = BlackCottonBlock;
  return result;
}

function getLumberObjectTypes() pure returns (ObjectType[] memory) {
  ObjectType[] memory result = new ObjectType[](17);
  result[0] = OakLumber;
  result[1] = SakuraLumber;
  result[2] = RubberLumber;
  result[3] = BirchLumber;
  result[4] = BlueOakLumber;
  result[5] = BrownOakLumber;
  result[6] = GreenOakLumber;
  result[7] = MagentaOakLumber;
  result[8] = OrangeOakLumber;
  result[9] = PinkOakLumber;
  result[10] = PurpleOakLumber;
  result[11] = RedOakLumber;
  result[12] = TanOakLumber;
  result[13] = WhiteOakLumber;
  result[14] = YellowOakLumber;
  result[15] = BlackOakLumber;
  result[16] = SilverOakLumber;
  return result;
}

function getGlassObjectTypes() pure returns (ObjectType[] memory) {
  ObjectType[] memory result = new ObjectType[](10);
  result[0] = Glass;
  result[1] = BlueGlass;
  result[2] = GreenGlass;
  result[3] = OrangeGlass;
  result[4] = PinkGlass;
  result[5] = PurpleGlass;
  result[6] = RedGlass;
  result[7] = WhiteGlass;
  result[8] = YellowGlass;
  result[9] = BlackGlass;
  return result;
}

function getOreObjectTypes() pure returns (ObjectType[] memory) {
  ObjectType[] memory result = new ObjectType[](5);
  result[0] = CoalOre;
  result[1] = SilverOre;
  result[2] = GoldOre;
  result[3] = DiamondOre;
  result[4] = NeptuniumOre;
  return result;
}

function eq(ObjectType self, ObjectType other) pure returns (bool) {
  return ObjectType.unwrap(self) == ObjectType.unwrap(other);
}

function neq(ObjectType self, ObjectType other) pure returns (bool) {
  return ObjectType.unwrap(self) != ObjectType.unwrap(other);
}

using ObjectTypeLib for ObjectType global;
using { eq as ==, neq as != } for ObjectType global;
