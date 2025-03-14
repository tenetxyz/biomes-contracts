// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
// import { ObjectType } from "../codegen/tables/ObjectType.sol";
// import { Mass } from "../codegen/tables/Mass.sol";

import { useEquipped } from "../utils/InventoryUtils.sol";
import { getOrCreateEntityAt, getObjectTypeIdAt } from "../utils/EntityUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { massToEnergy, transferEnergyToPool, addEnergyToLocalPool } from "../utils/EnergyUtils.sol";
import { abs } from "../utils/MathUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeLib, TreeData } from "../ObjectTypeLib.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { PLAYER_TILL_ENERGY_COST } from "../Constants.sol";

contract FarmingSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  // Manually defined trunk positions (relative to base)
  function _getTrunkPositions() internal pure returns (Vec3[] memory) {
    Vec3[] memory trunkPositions = new Vec3[](5);
    trunkPositions[0] = vec3(0, 0, 0); // Base (replaces seed)
    trunkPositions[1] = vec3(0, 1, 0);
    trunkPositions[2] = vec3(0, 2, 0);
    trunkPositions[3] = vec3(0, 3, 0);
    trunkPositions[4] = vec3(0, 4, 0);
    return trunkPositions;
  }

  // Manually defined leaf positions (relative to base)
  function _getLeafPositions() internal pure returns (Vec3[] memory) {
    Vec3[] memory leafPositions = new Vec3[](46);

    // Layer 1 (y=2)
    leafPositions[0] = vec3(-1, 2, -1);
    leafPositions[1] = vec3(-1, 2, 0);
    leafPositions[2] = vec3(-1, 2, 1);
    leafPositions[3] = vec3(0, 2, -1);
    leafPositions[4] = vec3(0, 2, 1);
    leafPositions[5] = vec3(1, 2, -1);
    leafPositions[6] = vec3(1, 2, 0);
    leafPositions[7] = vec3(1, 2, 1);

    // Layer 2 (y=3)
    leafPositions[8] = vec3(-2, 3, -1);
    leafPositions[9] = vec3(-2, 3, 0);
    leafPositions[10] = vec3(-2, 3, 1);
    leafPositions[11] = vec3(-1, 3, -2);
    leafPositions[12] = vec3(-1, 3, -1);
    leafPositions[13] = vec3(-1, 3, 0);
    leafPositions[14] = vec3(-1, 3, 1);
    leafPositions[15] = vec3(-1, 3, 2);
    leafPositions[16] = vec3(0, 3, -2);
    leafPositions[17] = vec3(0, 3, -1);
    leafPositions[18] = vec3(0, 3, 1);
    leafPositions[19] = vec3(0, 3, 2);
    leafPositions[20] = vec3(1, 3, -2);
    leafPositions[21] = vec3(1, 3, -1);
    leafPositions[22] = vec3(1, 3, 0);
    leafPositions[23] = vec3(1, 3, 1);
    leafPositions[24] = vec3(1, 3, 2);
    leafPositions[25] = vec3(2, 3, -1);
    leafPositions[26] = vec3(2, 3, 0);
    leafPositions[27] = vec3(2, 3, 1);

    // Layer 3 (y=4)
    leafPositions[28] = vec3(-1, 4, -1);
    leafPositions[29] = vec3(-1, 4, 0);
    leafPositions[30] = vec3(-1, 4, 1);
    leafPositions[31] = vec3(0, 4, -1);
    leafPositions[32] = vec3(0, 4, 1);
    leafPositions[33] = vec3(1, 4, -1);
    leafPositions[34] = vec3(1, 4, 0);
    leafPositions[35] = vec3(1, 4, 1);

    // Layer 4 (y=5, above trunk)
    leafPositions[36] = vec3(-1, 5, -1);
    leafPositions[37] = vec3(-1, 5, 0);
    leafPositions[38] = vec3(-1, 5, 1);
    leafPositions[39] = vec3(0, 5, -1);
    leafPositions[40] = vec3(0, 5, 0); // Top center
    leafPositions[41] = vec3(0, 5, 1);
    leafPositions[42] = vec3(1, 5, -1);
    leafPositions[43] = vec3(1, 5, 0);
    leafPositions[44] = vec3(1, 5, 1);

    // Single leaf on top (y=6)
    leafPositions[45] = vec3(0, 6, 0);

    return leafPositions;
  }

  function till(Vec3 coord) external {
    // (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    // requireInPlayerInfluence(playerCoord, coord);
    //
    // (EntityId farmlandEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    // require(objectTypeId == ObjectTypes.Dirt || objectTypeId == ObjectTypes.Grass, "Not dirt or grass");
    // (uint128 massUsed, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId);
    // require(toolObjectTypeId.isHoe(), "Must equip a hoe");
    //
    // uint128 energyCost = PLAYER_TILL_ENERGY_COST + massToEnergy(massUsed);
    // transferEnergyToPool(playerEntityId, playerCoord, energyCost);
    //
    // ObjectType._set(farmlandEntityId, ObjectTypes.Farmland);
  }

  function growSeed(Vec3 coord) external {
    requireValidPlayer(_msgSender());

    (EntityId seedEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId.isSeed(), "Not a seed");

    require(SeedGrowth._getFullyGrownAt(seedEntityId) <= block.timestamp, "Seed cannot be grown yet");

    if (objectTypeId.isCropSeed()) {
      // Turn wet farmland to regular farmland if mining a seed or crop
      (EntityId belowEntityId, ObjectTypeId belowTypeId) = getOrCreateEntityAt(coord - vec3(0, 1, 0));
      // Sanity check
      if (belowTypeId == ObjectTypes.WetFarmland) {
        ObjectType._set(belowEntityId, ObjectTypes.Farmland);
      }

      ObjectType._set(seedEntityId, objectTypeId.getCrop());
    } else if (objectTypeId.isTreeSeed()) {
      TreeData memory treeData = objectTypeId.getTreeData();
      require(treeData.logType != ObjectTypes.Null, "Invalid tree seed");

      // Grow the tree (replace the seed with the trunk and add blocks)
      (uint32 height, uint32 leaves) = _growTree(seedEntityId, coord, treeData);
      // If something blocked the height of the tree, return the logs energy to the pool
      uint32 energyToReturn = (treeData.height - height) * ObjectTypeMetadata._getEnergy(treeData.logType);

      // If not all leaves were generated, return their energy to the local pool
      uint32 maxPossibleLeaves = 46; // Hardcoded number of leaf positions in our model
      energyToReturn += (maxPossibleLeaves - leaves) * ObjectTypeMetadata._getEnergy(treeData.leafType);
      if (energyToReturn > 0) {
        addEnergyToLocalPool(coord, energyToReturn);
      }
    }
  }

  // Use manually defined tree model with fixed trunk and leaf positions
  function _growTree(
    EntityId seedEntityId,
    Vec3 baseCoord,
    TreeData memory treeData
  ) internal returns (uint32, uint32) {
    // Get manually defined trunk and leaf positions
    Vec3[] memory trunkPositions = _getTrunkPositions();
    Vec3[] memory leafPositions = _getLeafPositions();

    // Place the trunk blocks from bottom up until blocked
    uint32 trunkPlaced = 0;

    // Replace the seed with the first trunk block
    ObjectType._set(seedEntityId, treeData.logType);
    trunkPlaced = 1; // Count the base trunk

    // Place remaining trunk blocks
    for (uint32 i = 1; i < trunkPositions.length; i++) {
      Vec3 pos = baseCoord + trunkPositions[i];
      (EntityId entityId, ObjectTypeId existingType) = getOrCreateEntityAt(pos);

      // Stop if blocked
      if (existingType != ObjectTypes.Air) {
        break;
      }

      ObjectType._set(entityId, treeData.logType);
      trunkPlaced++;
    }

    // If trunk is too short, don't place leaves
    if (trunkPlaced <= 2) {
      return (trunkPlaced, 0);
    }

    // Place leaf blocks from bottom up until blocked
    uint32 leavesPlaced = 0;
    for (uint32 i = 0; i < leafPositions.length; i++) {
      // Skip leaf positions that would be above the actual trunk height
      if (trunkPlaced < trunkPositions.length && leafPositions[i].y() > int32(trunkPlaced)) {
        continue;
      }

      Vec3 pos = baseCoord + leafPositions[i];

      (EntityId entityId, ObjectTypeId existingType) = getOrCreateEntityAt(pos);

      // Only place leaves in air blocks
      if (existingType == ObjectTypes.Air) {
        ObjectType._set(entityId, treeData.leafType);
        leavesPlaced++;
      }
    }

    return (trunkPlaced, leavesPlaced);
  }

  // This function is no longer needed as trunk placement is handled in _growTree
}
