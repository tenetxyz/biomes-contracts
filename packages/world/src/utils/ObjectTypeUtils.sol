// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { CobblestoneObjectID, CobblestoneBrickObjectID, CobblestoneCarvedObjectID, CobblestonePolishedObjectID, CobblestoneShinglesObjectID } from "../ObjectTypeIds.sol";
import { StoneObjectID, StoneBrickObjectID, StoneCarvedObjectID, StonePolishedObjectID, StoneShinglesObjectID } from "../ObjectTypeIds.sol";
import { BasaltObjectID, BasaltBrickObjectID, BasaltCarvedObjectID, BasaltPolishedObjectID, BasaltShinglesObjectID } from "../ObjectTypeIds.sol";
import { ClayObjectID, ClayBrickObjectID, ClayCarvedObjectID, ClayPolishedObjectID, ClayShinglesObjectID } from "../ObjectTypeIds.sol";
import { GraniteObjectID, GraniteBrickObjectID, GraniteCarvedObjectID, GraniteShinglesObjectID, GranitePolishedObjectID } from "../ObjectTypeIds.sol";
import { QuartziteObjectID, QuartziteBrickObjectID, QuartziteCarvedObjectID, QuartzitePolishedObjectID, QuartziteShinglesObjectID } from "../ObjectTypeIds.sol";
import { LimestoneObjectID, LimestoneBrickObjectID, LimestoneCarvedObjectID, LimestonePolishedObjectID, LimestoneShinglesObjectID } from "../ObjectTypeIds.sol";
import { ReinforcedOakLumberObjectID, ReinforcedRubberLumberObjectID, ReinforcedBirchLumberObjectID } from "../ObjectTypeIds.sol";
import { GoldCubeObjectID, SilverCubeObjectID, DiamondCubeObjectID, NeptuniumCubeObjectID } from "../ObjectTypeIds.sol";
import { OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID, OakLumberObjectID, SakuraLumberObjectID, RubberLumberObjectID, BirchLumberObjectID } from "../ObjectTypeIds.sol";
import { WoodenPickObjectID, WoodenAxeObjectID, WoodenWhackerObjectID } from "../ObjectTypeIds.sol";
import { SilverOreObjectID, StonePickObjectID, StoneAxeObjectID, StoneWhackerObjectID, SilverPickObjectID, SilverAxeObjectID, SilverWhackerObjectID, GoldPickObjectID, GoldAxeObjectID, NeptuniumPickObjectID, NeptuniumAxeObjectID, DiamondPickObjectID, DiamondAxeObjectID } from "../ObjectTypeIds.sol";
import { BlueOakLumberObjectID, BrownOakLumberObjectID, GreenOakLumberObjectID, MagentaOakLumberObjectID, OrangeOakLumberObjectID, PinkOakLumberObjectID, PurpleOakLumberObjectID, RedOakLumberObjectID, TanOakLumberObjectID, WhiteOakLumberObjectID, YellowOakLumberObjectID, BlackOakLumberObjectID, SilverOakLumberObjectID } from "../ObjectTypeIds.sol";

function isPick(uint8 objectTypeId) pure returns (bool) {
  return
    objectTypeId == WoodenAxeObjectID ||
    objectTypeId == StonePickObjectID ||
    objectTypeId == SilverPickObjectID ||
    objectTypeId == GoldPickObjectID ||
    objectTypeId == NeptuniumPickObjectID ||
    objectTypeId == DiamondPickObjectID;
}

function isAxe(uint8 objectTypeId) pure returns (bool) {
  return
    objectTypeId == WoodenAxeObjectID ||
    objectTypeId == StoneAxeObjectID ||
    objectTypeId == SilverAxeObjectID ||
    objectTypeId == GoldAxeObjectID ||
    objectTypeId == NeptuniumAxeObjectID ||
    objectTypeId == DiamondAxeObjectID;
}

function isLog(uint8 objectTypeId) pure returns (bool) {
  return
    objectTypeId == OakLogObjectID ||
    objectTypeId == SakuraLogObjectID ||
    objectTypeId == BirchLogObjectID ||
    objectTypeId == RubberLogObjectID;
}

function getLogObjectTypes() pure returns (uint8[4] memory) {
  return [OakLogObjectID, SakuraLogObjectID, BirchLogObjectID, RubberLogObjectID];
}

function isLumber(uint8 objectTypeId) pure returns (bool) {
  return
    objectTypeId == OakLumberObjectID ||
    objectTypeId == SakuraLumberObjectID ||
    objectTypeId == RubberLumberObjectID ||
    objectTypeId == BirchLumberObjectID ||
    objectTypeId == BlueOakLumberObjectID ||
    objectTypeId == BrownOakLumberObjectID ||
    objectTypeId == GreenOakLumberObjectID ||
    objectTypeId == MagentaOakLumberObjectID ||
    objectTypeId == OrangeOakLumberObjectID ||
    objectTypeId == PinkOakLumberObjectID ||
    objectTypeId == PurpleOakLumberObjectID ||
    objectTypeId == RedOakLumberObjectID ||
    objectTypeId == TanOakLumberObjectID ||
    objectTypeId == WhiteOakLumberObjectID ||
    objectTypeId == YellowOakLumberObjectID ||
    objectTypeId == BlackOakLumberObjectID ||
    objectTypeId == SilverOakLumberObjectID;
}

function getLumberObjectTypes() pure returns (uint8[17] memory) {
  return [
    OakLumberObjectID,
    SakuraLumberObjectID,
    RubberLumberObjectID,
    BirchLumberObjectID,
    BlueOakLumberObjectID,
    BrownOakLumberObjectID,
    GreenOakLumberObjectID,
    MagentaOakLumberObjectID,
    OrangeOakLumberObjectID,
    PinkOakLumberObjectID,
    PurpleOakLumberObjectID,
    RedOakLumberObjectID,
    TanOakLumberObjectID,
    WhiteOakLumberObjectID,
    YellowOakLumberObjectID,
    BlackOakLumberObjectID,
    SilverOakLumberObjectID
  ];
}

function getReinforcedLumberObjectTypes() pure returns (uint8[3] memory) {
  return [ReinforcedOakLumberObjectID, ReinforcedRubberLumberObjectID, ReinforcedBirchLumberObjectID];
}

function isReinforcedLumber(uint8 objectTypeId) pure returns (bool) {
  return
    objectTypeId == ReinforcedOakLumberObjectID ||
    objectTypeId == ReinforcedRubberLumberObjectID ||
    objectTypeId == ReinforcedBirchLumberObjectID;
}

function isStone(uint8 objectTypeId) pure returns (bool) {
  return
    objectTypeId == StoneObjectID ||
    objectTypeId == CobblestoneObjectID ||
    objectTypeId == BasaltObjectID ||
    objectTypeId == ClayObjectID ||
    objectTypeId == GraniteObjectID ||
    objectTypeId == QuartziteObjectID ||
    objectTypeId == LimestoneObjectID;
}
