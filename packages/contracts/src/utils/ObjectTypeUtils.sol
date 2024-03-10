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

function isPick(bytes32 objectTypeId) returns (bool) {
  return
    objectTypeId == WoodenAxeObjectID ||
    objectTypeId == StonePickObjectID ||
    objectTypeId == SilverPickObjectID ||
    objectTypeId == GoldPickObjectID ||
    objectTypeId == NeptuniumPickObjectID ||
    objectTypeId == DiamondPickObjectID;
}

function isAxe(bytes32 objectTypeId) returns (bool) {
  return
    objectTypeId == WoodenAxeObjectID ||
    objectTypeId == StoneAxeObjectID ||
    objectTypeId == SilverAxeObjectID ||
    objectTypeId == GoldAxeObjectID ||
    objectTypeId == NeptuniumAxeObjectID ||
    objectTypeId == DiamondAxeObjectID;
}

function isWoodLog(bytes32 objectTypeId) returns (bool) {
  return
    objectTypeId == OakLogObjectID ||
    objectTypeId == SakuraLogObjectID ||
    objectTypeId == BirchLogObjectID ||
    objectTypeId == RubberLogObjectID;
}

function isStone(bytes32 objectTypeId) returns (bool) {
  return
    objectTypeId == StoneObjectID ||
    objectTypeId == CobblestoneObjectID ||
    objectTypeId == BasaltObjectID ||
    objectTypeId == ClayObjectID ||
    objectTypeId == GraniteObjectID ||
    objectTypeId == QuartziteObjectID ||
    objectTypeId == LimestoneObjectID;
}
