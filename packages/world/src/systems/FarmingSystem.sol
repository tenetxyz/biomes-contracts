// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { SeedGrowth } from "../codegen/tables/SeedGrowth.sol";

import { useEquipped } from "../utils/InventoryUtils.sol";
import { getOrCreateEntityAt, getObjectTypeIdAt } from "../utils/EntityUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { massToEnergy, transferEnergyToPool } from "../utils/EnergyUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeLib, TreeData } from "../ObjectTypeLib.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { PLAYER_TILL_ENERGY_COST } from "../Constants.sol";

contract FarmingSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function till(Vec3 coord) external {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    (EntityId farmlandEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    require(objectTypeId == ObjectTypes.Dirt || objectTypeId == ObjectTypes.Grass, "Not dirt or grass");
    (uint128 massUsed, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId);
    require(toolObjectTypeId.isHoe(), "Must equip a hoe");

    uint128 energyCost = PLAYER_TILL_ENERGY_COST + massToEnergy(massUsed);
    transferEnergyToPool(playerEntityId, playerCoord, energyCost);

    ObjectType._set(farmlandEntityId, ObjectTypes.Farmland);
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

      // First, check if we have enough space to grow the tree
      bool hasSpace = _hasTreeSpace(coord, int32(uint32(treeData.height)));

      if (hasSpace) {
        // Grow the tree (replace the seed with the trunk and add blocks)
        _growTree(seedEntityId, coord, treeData);
      } else {
        // Not enough space to grow tree, convert seed to a sapling (just the log)
        // which can be mined. This prevents the seed from being stuck.
        // TODO: return remaining energy to pool?
        ObjectType._set(seedEntityId, treeData.logType);
      }
    }
  }

  function _hasTreeSpace(Vec3 coord, int32 height) internal view returns (bool) {
    // Check vertical space for the trunk
    for (int32 i = 0; i < height; i++) {
      Vec3 checkCoord = coord + vec3(0, i, 0);
      if (i > 0) {
        // Skip the seed's position
        ObjectTypeId objectTypeId = getObjectTypeIdAt(checkCoord);
        if (objectTypeId != ObjectTypes.Air) {
          return false;
        }
      }
    }

    // Check space for the canopy
    int32 canopySize = 2; // How far from the trunk the leaves extend
    for (int32 x = -canopySize; x <= canopySize; x++) {
      for (int32 z = -canopySize; z <= canopySize; z++) {
        // Check a few levels at the top for the canopy
        for (int32 y = height - 3; y < height + 1; y++) {
          if (x == 0 && z == 0 && y < height) {
            continue; // Skip the trunk position
          }
          Vec3 checkCoord = coord + vec3(x, y, z);
          ObjectTypeId objectTypeId = getObjectTypeIdAt(checkCoord);
          if (objectTypeId != ObjectTypes.Air) {
            return false;
          }
        }
      }
    }

    return true;
  }

  function _growTree(EntityId seedEntityId, Vec3 baseCoord, TreeData memory treeData) internal {
    // Replace the seed with the trunk
    ObjectType._set(seedEntityId, treeData.logType);

    int32 height = int32(uint32(treeData.height));

    // Create the trunk
    for (int32 i = 1; i < height; i++) {
      Vec3 trunkCoord = baseCoord + vec3(0, i, 0);
      (EntityId trunkEntityId, ) = getOrCreateEntityAt(trunkCoord);
      ObjectType._set(trunkEntityId, treeData.logType);
    }

    // Create the canopy
    int32 canopyStart = height - 3;
    int32 canopySize = 2;

    for (int32 x = -canopySize; x <= canopySize; x++) {
      for (int32 z = -canopySize; z <= canopySize; z++) {
        for (int32 y = canopyStart; y < height + 1; y++) {
          if (x == 0 && z == 0 && y < height) {
            continue; // Skip the trunk position
          }

          // Skip corners for a more natural look
          if ((x == -canopySize || x == canopySize) && (z == -canopySize || z == canopySize)) {
            // 50% chance to skip corners
            if (uint(keccak256(abi.encodePacked(baseCoord, x, y, z))) % 2 == 0) {
              continue;
            }
          }

          Vec3 leafCoord = baseCoord + vec3(x, y, z);
          (EntityId leafEntityId, ObjectTypeId existingType) = getOrCreateEntityAt(leafCoord);

          // Only place leaves in air blocks
          if (existingType == ObjectTypes.Air) {
            ObjectType._set(leafEntityId, treeData.leafType);
          }
        }
      }
    }
  }
}
