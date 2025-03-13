// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

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

      // Grow the tree (replace the seed with the trunk and add blocks)
      uint32 height = _growTree(seedEntityId, coord, treeData);
      if (height < treeData.height) {
        // If something blocked the height of the tree, return the logs energy to the pool
        uint32 energyToReturn = (treeData.height - height) * ObjectTypeMetadata._getEnergy(treeData.logType);
        addEnergyToLocalPool(coord, energyToReturn);
      }
    }
  }

  function _growTree(EntityId seedEntityId, Vec3 baseCoord, TreeData memory treeData) internal returns (uint32) {
    // Replace the seed with the trunk
    ObjectType._set(seedEntityId, treeData.logType);

    uint32 height = treeData.height;

    // Create the trunk up to available space
    for (uint32 i = 1; i < height; i++) {
      Vec3 trunkCoord = baseCoord + vec3(0, int32(i), 0);
      (EntityId trunkEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(trunkCoord);
      if (objectTypeId != ObjectTypes.Air) {
        height = i + 1;
        break;
      }

      ObjectType._set(trunkEntityId, treeData.logType);
    }

    if (height <= 2) {
      // Very small tree, no leaves
      return height;
    }

    // Adjust canopy parameters based on height
    int32 canopySize;
    int32 canopyStart;
    int32 canopyEnd;

    if (height <= 4) {
      // Small tree
      canopySize = 2;
      canopyStart = int32(height - 2);
      canopyEnd = int32(height + 1); // Extend 1 block above trunk
    } else {
      // Normal or tall tree
      canopySize = 3;
      canopyStart = int32(height - 3);
      canopyEnd = int32(height + 2); // Extend 2 block above trunk
    }

    if (height < treeData.height) {
      canopyEnd = int32(height);
    }

    // Generate a unique seed for this tree to ensure consistent randomness
    uint256 treeSeed = uint256(keccak256(abi.encodePacked(baseCoord, block.timestamp)));

    // Create the canopy
    for (int32 x = -canopySize; x <= canopySize; x++) {
      for (int32 z = -canopySize; z <= canopySize; z++) {
        for (int32 y = canopyStart; y < canopyEnd; y++) {
          // Skip the trunk position
          if (x == 0 && z == 0 && y < int32(height)) {
            continue;
          }

          // TODO: adjust to get desired shape

          {
            // Calculate distance from center axis for a more natural, rounded shape
            int32 distanceFromCenter = x * x + z * z;
            int32 cornerDistance = canopySize ** 2;

            // Skip corners and edges based on distance and randomness for a more natural look
            if (distanceFromCenter > cornerDistance) {
              // Always skip if beyond maximum radius
              continue;
            } else if (distanceFromCenter == cornerDistance) {
              // At the corners (maximum distance), 75% chance to skip
              if (uint256(keccak256(abi.encodePacked(treeSeed, x, y, z))) % 4 < 3) {
                continue;
              }
            } else if (distanceFromCenter >= cornerDistance - 1) {
              // Near corners, 50% chance to skip
              if (uint256(keccak256(abi.encodePacked(treeSeed, x, y, z))) % 2 == 0) {
                continue;
              }
            }

            // Top layer of leaves should be smaller
            if (y >= canopyEnd - 1) {
              if (distanceFromCenter > canopySize) {
                continue;
              }
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

    return height;
  }
}
