// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { ResourceCount } from "./codegen/tables/ResourceCount.sol";

import { TotalBurnedResourceCount } from "./codegen/tables/TotalBurnedResourceCount.sol";
import { TotalResourceCount } from "./codegen/tables/TotalResourceCount.sol";

import { MAX_COAL, MAX_DIAMOND, MAX_GOLD, MAX_NEPTUNIUM, MAX_SILVER, MAX_WHEAT_SEED } from "./Constants.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "./ObjectTypeLib.sol";
import { ObjectTypes } from "./ObjectTypes.sol";
import { Vec3 } from "./Vec3.sol";

library NatureLib {
  using LibPRNG for LibPRNG.PRNG;
  using ObjectTypeLib for ObjectTypeId;

  function getMineDrops(ObjectTypeId objectTypeId, bytes32 randomSeed)
    internal
    view
    returns (ObjectAmount[] memory result)
  {
    // Wheat drops: Always drops wheat + 0-3 wheat seeds based on adjusted binomial distribution
    if (objectTypeId == ObjectTypes.Wheat) {
      return getWheatDrops(objectTypeId, randomSeed);
    }

    // FescueGrass has a chance to drop wheat seeds
    if (objectTypeId == ObjectTypes.FescueGrass) {
      return getGrassDrops(randomSeed);
    }

    // Default behavior for all other objects
    result = new ObjectAmount[](1);
    result[0] = ObjectAmount(objectTypeId, 1);

    return result;
  }

  function getWheatDrops(ObjectTypeId objectTypeId, bytes32 randomSeed)
    internal
    view
    returns (ObjectAmount[] memory result)
  {
    // Pre-calculated binomial distribution for n=3, p=0.57
    uint256[] memory distribution = new uint256[](4);
    distribution[0] = 8; // 0 seeds: 8%
    distribution[1] = 31; // 1 seed: 31%
    distribution[2] = 41; // 2 seeds: 41%
    distribution[3] = 20; // 3 seeds: 20%

    // Get wheat seed options and their weights using pre-calculated distribution
    (ObjectAmount[] memory seedOptions, uint256[] memory weights) =
      getResourceDropWeights(ObjectTypes.WheatSeed, distribution);

    // Select seed drop based on calculated weights
    ObjectAmount memory seedDrop = selectObjectByWeight(seedOptions, weights, randomSeed);

    // Always drop wheat, plus seeds if any were selected
    if (seedDrop.objectTypeId != ObjectTypes.Null) {
      result = new ObjectAmount[](2);
      result[0] = ObjectAmount(objectTypeId, 1);
      result[1] = seedDrop;
    } else {
      result = new ObjectAmount[](1);
      result[0] = ObjectAmount(objectTypeId, 1);
    }

    return result;
  }

  function getGrassDrops(bytes32 randomSeed) internal view returns (ObjectAmount[] memory result) {
    uint256[] memory distribution = new uint256[](2);
    distribution[0] = 43; // No seed: 43%
    distribution[1] = 57; // 1 seed: 57%

    (ObjectAmount[] memory grassOptions, uint256[] memory weights) =
      getResourceDropWeights(ObjectTypes.WheatSeed, distribution);

    // Select drop based on calculated weights
    ObjectAmount memory seedDrop = selectObjectByWeight(grassOptions, weights, randomSeed);

    if (seedDrop.objectTypeId != ObjectTypes.Null) {
      result = new ObjectAmount[](1);
      result[0] = seedDrop;
    }

    return result;
  }

  function getRandomOre(Vec3 coord, uint256 commitment) internal view returns (ObjectTypeId) {
    // Generate random seed based on commitment and coordinates
    bytes32 seed = keccak256(abi.encodePacked(blockhash(commitment), coord));

    // Get ore options and their weights (based on remaining amounts)
    (ObjectAmount[] memory oreOptions, uint256[] memory weights) = getOreWeights();

    // Select ore based on availability
    ObjectAmount memory selectedOre = selectObjectByWeight(oreOptions, weights, seed);

    // Return selected ore type and current mined count
    return selectedOre.objectTypeId;
  }

  // Get weights for ore selection (directly based on remaining amounts)
  function getOreWeights() internal view returns (ObjectAmount[] memory options, uint256[] memory weights) {
    options = new ObjectAmount[](5);
    weights = new uint256[](5);

    options[0] = ObjectAmount(ObjectTypes.CoalOre, 1);
    options[1] = ObjectAmount(ObjectTypes.SilverOre, 1);
    options[2] = ObjectAmount(ObjectTypes.GoldOre, 1);
    options[3] = ObjectAmount(ObjectTypes.DiamondOre, 1);
    options[4] = ObjectAmount(ObjectTypes.NeptuniumOre, 1);

    // Use remaining amounts directly as weights
    for (uint256 i = 0; i < weights.length; i++) {
      weights[i] = getRemainingAmount(options[i].objectTypeId);
    }
  }

  // Get resource cap for a specific resource type
  function getResourceCap(ObjectTypeId objectTypeId) internal pure returns (uint256) {
    if (objectTypeId == ObjectTypes.CoalOre) return MAX_COAL;
    if (objectTypeId == ObjectTypes.SilverOre) return MAX_SILVER;
    if (objectTypeId == ObjectTypes.GoldOre) return MAX_GOLD;
    if (objectTypeId == ObjectTypes.DiamondOre) return MAX_DIAMOND;
    if (objectTypeId == ObjectTypes.NeptuniumOre) return MAX_NEPTUNIUM;
    if (objectTypeId == ObjectTypes.WheatSeed) return MAX_WHEAT_SEED;

    // If no specific cap, use a high value
    return type(uint256).max;
  }

  // Get remaining amount of a resource
  function getRemainingAmount(ObjectTypeId objectTypeId) internal view returns (uint256) {
    if (objectTypeId == ObjectTypes.Null) return type(uint256).max;

    uint256 cap = getResourceCap(objectTypeId);
    uint256 mined = ResourceCount._get(objectTypeId);
    return mined >= cap ? 0 : cap - mined;
  }

  // Simple random selection based on weights
  function selectObjectByWeight(ObjectAmount[] memory options, uint256[] memory weights, bytes32 seed)
    internal
    pure
    returns (ObjectAmount memory)
  {
    uint256 selectedIndex = selectByWeight(weights, seed);
    return options[selectedIndex];
  }

  // Simple weighted selection from an array of weights
  function selectByWeight(uint256[] memory weights, bytes32 seed) internal pure returns (uint256) {
    uint256 totalWeight = 0;
    for (uint256 i = 0; i < weights.length; i++) {
      totalWeight += weights[i];
    }

    require(totalWeight > 0, "No options available");

    // Initialize PRNG
    LibPRNG.PRNG memory prng;
    prng.seed(uint256(seed));

    // Select option based on weights
    uint256 randomValue = prng.uniform(totalWeight);
    uint256 cumulativeWeight = 0;

    uint256 j = 0;
    for (; j < weights.length - 1; j++) {
      cumulativeWeight += weights[j];
      if (randomValue < cumulativeWeight) break;
    }

    return j;
  }

  // Generic function to adjust pre-calculated weights based on resource availability
  // baseWeights: pre-calculated distribution weights (index 0 is for 0 items, etc.)
  function getResourceDropWeights(
    ObjectTypeId resourceType, // The resource type to get
    uint256[] memory distribution // Pre-calculated weights for distribution
  ) internal view returns (ObjectAmount[] memory options, uint256[] memory weights) {
    uint8 maxAmount = uint8(distribution.length - 1);

    // Create options array from 0 to maxAmount
    options = new ObjectAmount[](distribution.length);
    options[0] = ObjectAmount(ObjectTypes.Null, 0); // Option for 0 drops

    for (uint8 i = 1; i <= maxAmount; i++) {
      options[i] = ObjectAmount(resourceType, i);
    }

    // Start with the base weights and adjust for availability
    weights = new uint256[](distribution.length);
    weights[0] = distribution[0]; // Weight for 0 drops stays the same

    // Get resource availability info
    uint256 remaining = getRemainingAmount(resourceType);
    uint256 cap = getResourceCap(resourceType);

    // For each non-zero option, apply compound probability adjustment
    for (uint8 i = 1; i <= maxAmount; i++) {
      if (remaining < i) {
        weights[i] = 0;
        continue;
      }

      // Calculate compound probability for getting i resources
      uint256 p = distribution[i];

      // Apply availability adjustment for each resource needed
      for (uint8 j = 0; j < i; j++) {
        p = p * (remaining - j) / (cap - j);
      }

      weights[i] = p;
    }
  }
}
