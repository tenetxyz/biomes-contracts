// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Direction } from "./codegen/common.sol";
import { ResourceCount } from "./codegen/tables/ResourceCount.sol";
import { BurnedResourceCount } from "./codegen/tables/BurnedResourceCount.sol";

import { IMachineSystem } from "./codegen/world/IMachineSystem.sol";
import { ITransferSystem } from "./codegen/world/ITransferSystem.sol";

import { ObjectTypeId } from "./ObjectTypeId.sol";
import { Block, CATEGORY_MASK, Item, Misc, ObjectTypes, Tool } from "./ObjectTypes.sol";
import { Vec3, vec3 } from "./Vec3.sol";

struct ObjectAmount {
  ObjectTypeId objectTypeId;
  uint16 amount;
}

struct TreeData {
  ObjectTypeId logType;
  ObjectTypeId leafType;
  uint32 trunkHeight;
  uint32 canopyStart;
  uint32 canopyEnd;
  uint32 canopyWidth;
  uint32 stretchFactor;
  int32 centerOffset;
}

library ObjectTypeLib {
  function unwrap(ObjectTypeId self) internal pure returns (uint16) {
    return ObjectTypeId.unwrap(self);
  }

  function getObjectTypeSchema(ObjectTypeId self) internal pure returns (Vec3[] memory) {
    if (self == ObjectTypes.Player) {
      Vec3[] memory playerRelativePositions = new Vec3[](1);
      playerRelativePositions[0] = vec3(0, 1, 0);
      return playerRelativePositions;
    }

    if (self == ObjectTypes.Bed) {
      Vec3[] memory bedRelativePositions = new Vec3[](1);
      bedRelativePositions[0] = vec3(0, 0, 1);
      return bedRelativePositions;
    }

    if (self == ObjectTypes.TextSign || self == ObjectTypes.SmartTextSign) {
      Vec3[] memory textSignRelativePositions = new Vec3[](1);
      textSignRelativePositions[0] = vec3(0, 1, 0);
      return textSignRelativePositions;
    }

    return new Vec3[](0);
  }

  /// @dev Get relative schema coords, including base coord
  function getRelativeCoords(ObjectTypeId self, Vec3 baseCoord, Direction direction)
    internal
    pure
    returns (Vec3[] memory)
  {
    Vec3[] memory schemaCoords = getObjectTypeSchema(self);
    Vec3[] memory coords = new Vec3[](schemaCoords.length + 1);

    coords[0] = baseCoord;

    for (uint256 i = 0; i < schemaCoords.length; i++) {
      coords[i + 1] = baseCoord + schemaCoords[i].rotate(direction);
    }

    return coords;
  }

  function getRelativeCoords(ObjectTypeId self, Vec3 baseCoord) internal pure returns (Vec3[] memory) {
    return getRelativeCoords(self, baseCoord, Direction.PositiveZ);
  }

  function getCategory(ObjectTypeId self) internal pure returns (uint16) {
    return ObjectTypeId.unwrap(self) & CATEGORY_MASK;
  }

  function isBlock(ObjectTypeId self) internal pure returns (bool) {
    return !self.isNull() && self.getCategory() == Block;
  }

  function isMineable(ObjectTypeId self) internal pure returns (bool) {
    return self.isBlock() && self != ObjectTypes.Air && self != ObjectTypes.Water && self != ObjectTypes.Lava;
  }

  function isTool(ObjectTypeId self) internal pure returns (bool) {
    return self.getCategory() == Tool;
  }

  function isItem(ObjectTypeId self) internal pure returns (bool) {
    return self.getCategory() == Item;
  }

  function isNull(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.Null;
  }

  function isAny(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.AnyLog || self == ObjectTypes.AnyPlanks;
  }

  function isWhacker(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.WoodenWhacker || self == ObjectTypes.StoneWhacker || self == ObjectTypes.SilverWhacker;
  }

  function isHoe(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.WoodenHoe;
  }

  function isMachine(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.ForceField;
  }

  function canHoldDisplay(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.TextSign || self == ObjectTypes.SmartTextSign;
  }

  function isSmartDisplay(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.SmartTextSign;
  }

  function isFood(ObjectTypeId self) internal pure returns (bool) {
    return self.isCrop();
  }

  function isSeed(ObjectTypeId self) internal pure returns (bool) {
    return isCropSeed(self) || isTreeSeed(self);
  }

  function isCropSeed(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.WheatSeed;
  }

  function isTreeSeed(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.OakSeed || self == ObjectTypes.SpruceSeed;
  }

  function isCrop(ObjectTypeId self) internal pure returns (bool) {
    return self == ObjectTypes.Wheat;
  }

  // TODO: one possible way to optimize is to follow some kind of schema for crops and their seeds
  function getCrop(ObjectTypeId self) internal pure returns (ObjectTypeId) {
    if (self == ObjectTypes.WheatSeed) {
      return ObjectTypes.Wheat;
    }

    revert("Invalid crop seed type");
  }

  function getTreeData(ObjectTypeId seedType) internal pure returns (TreeData memory) {
    if (seedType == ObjectTypes.OakSeed) {
      return TreeData({
        logType: ObjectTypes.OakLog,
        leafType: ObjectTypes.OakLeaf,
        trunkHeight: 5,
        canopyStart: 3,
        canopyEnd: 7,
        canopyWidth: 2,
        stretchFactor: 2,
        centerOffset: -2
      });
    } else if (seedType == ObjectTypes.SpruceSeed) {
      return TreeData({
        logType: ObjectTypes.SpruceLog,
        leafType: ObjectTypes.SpruceLeaf,
        trunkHeight: 7,
        canopyStart: 2,
        canopyEnd: 10,
        canopyWidth: 2,
        stretchFactor: 3,
        centerOffset: -5
      });
    }

    revert("Invalid tree seed type");
  }

  // TODO: one possible way to optimize is to follow some kind of schema for crops and their seeds
  function getSeedDrop(ObjectTypeId self) internal pure returns (ObjectTypeId) {
    if (self == ObjectTypes.Wheat) {
      return ObjectTypes.WheatSeed;
    }

    return ObjectTypes.Null;
  }

  function timeToGrow(ObjectTypeId self) internal pure returns (uint128) {
    // TODO: different times for different seeds
    if (self.isSeed()) {
      return 15 minutes;
    }

    return 0;
  }

  function getObjectTypes(ObjectTypeId self) internal pure returns (ObjectTypeId[] memory) {
    if (self == ObjectTypes.AnyLog) {
      return getLogObjectTypes();
    }

    if (self == ObjectTypes.AnyPlanks) {
      return getPlanksObjectTypes();
    }

    // Return empty array for non-Any types
    return new ObjectTypeId[](0);
  }

  /// @dev Get ore amounts that should be burned when this object is burned
  /// Currently it only supports tools, and assumes that only a single type of ore is used
  function getOreAmount(ObjectTypeId self) internal pure returns (ObjectAmount memory) {
    // Silver tools
    if (self == ObjectTypes.SilverPick || self == ObjectTypes.SilverAxe) {
      return ObjectAmount(ObjectTypes.SilverOre, 4); // 4 silver bars = 4 ores
    }
    if (self == ObjectTypes.SilverWhacker) {
      return ObjectAmount(ObjectTypes.SilverOre, 6); // 6 silver bars = 6 ores
    }

    // Gold tools
    if (self == ObjectTypes.GoldPick || self == ObjectTypes.GoldAxe) {
      return ObjectAmount(ObjectTypes.GoldOre, 4); // 4 gold bars = 4 ores
    }

    // Diamond tools
    if (self == ObjectTypes.DiamondPick || self == ObjectTypes.DiamondAxe) {
      return ObjectAmount(ObjectTypes.DiamondOre, 4); // 4 diamonds
    }

    // Neptunium tools
    if (self == ObjectTypes.NeptuniumPick || self == ObjectTypes.NeptuniumAxe) {
      return ObjectAmount(ObjectTypes.NeptuniumOre, 4); // 4 neptunium bars = 4 ores
    }

    // Return zero amount for any other tool
    return ObjectAmount(ObjectTypes.Null, 0);
  }

  function burnOres(ObjectTypeId self) internal {
    ObjectAmount memory ores = self.getOreAmount();
    ObjectTypeId objectTypeId = ores.objectTypeId;
    if (!objectTypeId.isNull()) {
      uint256 amount = ores.amount;
      // This increases the availability of the ores being burned
      ResourceCount._set(objectTypeId, ResourceCount._get(objectTypeId) - amount);
      // This allows the same amount of ores to respawn
      BurnedResourceCount._set(ObjectTypes.AnyOre, BurnedResourceCount._get(ObjectTypes.AnyOre) + amount);
    }
  }

  function isMovable(ObjectTypeId self) internal pure returns (bool) {
    if (self == ObjectTypes.Player) {
      return true;
    }

    // TODO: support other movable entities
    return false;
  }

  function isActionAllowed(ObjectTypeId self, bytes4 sig) internal pure returns (bool) {
    if (self == ObjectTypes.Player) {
      return true;
    }

    if (self == ObjectTypes.SmartChest) {
      return sig == ITransferSystem.transfer.selector || sig == ITransferSystem.transferTool.selector
        || sig == ITransferSystem.transferTools.selector || sig == IMachineSystem.fuelMachine.selector;
    }

    return false;
  }
}

function getLogObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](7);
  result[0] = ObjectTypes.OakLog;
  result[1] = ObjectTypes.BirchLog;
  result[2] = ObjectTypes.JungleLog;
  result[3] = ObjectTypes.SakuraLog;
  result[4] = ObjectTypes.AcaciaLog;
  result[5] = ObjectTypes.SpruceLog;
  result[6] = ObjectTypes.DarkOakLog;
  return result;
}

function getPlanksObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](7);
  result[0] = ObjectTypes.OakPlanks;
  result[1] = ObjectTypes.BirchPlanks;
  result[2] = ObjectTypes.JunglePlanks;
  result[3] = ObjectTypes.SakuraPlanks;
  result[4] = ObjectTypes.SprucePlanks;
  result[5] = ObjectTypes.AcaciaPlanks;
  result[6] = ObjectTypes.DarkOakPlanks;
  return result;
}

function getOreObjectTypes() pure returns (ObjectTypeId[] memory) {
  ObjectTypeId[] memory result = new ObjectTypeId[](5);
  result[0] = ObjectTypes.CoalOre;
  result[1] = ObjectTypes.SilverOre;
  result[2] = ObjectTypes.GoldOre;
  result[3] = ObjectTypes.DiamondOre;
  result[4] = ObjectTypes.NeptuniumOre;
  return result;
}

using ObjectTypeLib for ObjectTypeId;
