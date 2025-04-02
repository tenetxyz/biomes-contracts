// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { LibPRNG } from "solady/utils/LibPRNG.sol";

import { ResourceCategory } from "./codegen/common.sol";
import { ResourceCount } from "./codegen/tables/ResourceCount.sol";

import { TotalBurnedResourceCount } from "./codegen/tables/TotalBurnedResourceCount.sol";
import { TotalResourceCount } from "./codegen/tables/TotalResourceCount.sol";

import {
  MAX_COAL,
  MAX_DIAMOND,
  MAX_GOLD,
  MAX_NEPTUNIUM,
  MAX_OAK_SEED,
  MAX_SILVER,
  MAX_SPRUCE_SEED,
  MAX_WHEAT_SEED
} from "./Constants.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "./ObjectTypeLib.sol";
import { ObjectTypes } from "./ObjectTypes.sol";
import { Vec3 } from "./Vec3.sol";

library ResourceLib {
  using LibPRNG for LibPRNG.PRNG;
  using ObjectTypeLib for ObjectTypeId;

  // Structure to hold resource drop results with metadata
  struct ResourceDropResult {
    ObjectAmount[] amounts;
    bool requiresResourceTracking;
    ResourceCategory category;
    bool returnToPool;
    ObjectTypeId returnType;
  }

  // Get resource types and caps for a given category
  function getResourceInfo(ResourceCategory category)
    internal
    pure
    returns (ObjectTypeId[] memory resources, uint256[] memory caps)
  {
    if (category == ResourceCategory.Mining) {
      // Return ore types and caps
      resources = new ObjectTypeId[](5);
      resources[0] = ObjectTypes.CoalOre;
      resources[1] = ObjectTypes.SilverOre;
      resources[2] = ObjectTypes.GoldOre;
      resources[3] = ObjectTypes.DiamondOre;
      resources[4] = ObjectTypes.NeptuniumOre;

      caps = new uint256[](5);
      caps[0] = MAX_COAL;
      caps[1] = MAX_SILVER;
      caps[2] = MAX_GOLD;
      caps[3] = MAX_DIAMOND;
      caps[4] = MAX_NEPTUNIUM;
    } else if (category == ResourceCategory.Farming) {
      // Return seed types and caps
      resources = new ObjectTypeId[](3);
      resources[0] = ObjectTypes.WheatSeed;
      resources[1] = ObjectTypes.OakSeed;
      resources[2] = ObjectTypes.SpruceSeed;

      caps = new uint256[](3);
      caps[0] = MAX_WHEAT_SEED;
      caps[1] = MAX_OAK_SEED;
      caps[2] = MAX_SPRUCE_SEED;
    } else {
      revert("Unsupported resource category");
    }
  }

  // Enhanced drop function with probabilistic seed drops
  function getResourceDrops(ObjectTypeId objectTypeId, bytes32 randomSeed)
    internal
    pure
    returns (ResourceDropResult memory result)
  {
    // Initialize PRNG with the provided seed
    LibPRNG.PRNG memory prng;
    prng.seed(uint256(randomSeed));

    // Default values
    result.requiresResourceTracking = false;
    result.returnToPool = false;

    // Case 1: Raw resource collection (AnyOre)
    if (objectTypeId == ObjectTypes.AnyOre) {
      // This will be handled by the caller (NatureSystem) with getRandomResource
      result.amounts = new ObjectAmount[](1);
      result.amounts[0] = ObjectAmount(objectTypeId, 1);
      result.category = ResourceCategory.Mining;
      result.requiresResourceTracking = true;
      return result;
    }

    // Case 2: Crop harvesting with probability-based seed drops
    if (objectTypeId.isCrop()) {
      // Get the seed type that corresponds to this crop
      ObjectTypeId seedType = objectTypeId.getSeedDrop();

      // Get crop with probability of seed (70% chance)
      if (prng.uniform(100) < 70) {
        result.amounts = new ObjectAmount[](2);
        result.amounts[0] = ObjectAmount(objectTypeId, 1);
        result.amounts[1] = ObjectAmount(seedType, 1);
      } else {
        // Just the crop (return seed to pool)
        result.amounts = new ObjectAmount[](1);
        result.amounts[0] = ObjectAmount(objectTypeId, 1);
        result.returnToPool = true;
        result.returnType = seedType;
      }

      result.category = ResourceCategory.Farming;
      result.requiresResourceTracking = true;
      return result;
    }

    // Case 3: FescueGrass gives a chance for seeds
    if (objectTypeId == ObjectTypes.FescueGrass) {
      // 50% chance to get a seed from grass
      if (prng.uniform(100) < 50) {
        result.amounts = new ObjectAmount[](1);
        result.amounts[0] = ObjectAmount(ObjectTypes.WheatSeed, 1);
        result.requiresResourceTracking = true;
        result.category = ResourceCategory.Farming;
      } else {
        // Nothing (empty array)
        result.amounts = new ObjectAmount[](0);
      }

      return result;
    }

    // Case 4: Default behavior for all other objects
    result.amounts = new ObjectAmount[](1);
    result.amounts[0] = ObjectAmount(objectTypeId, 1);

    // Check if it's a mining resource
    if (
      objectTypeId == ObjectTypes.CoalOre || objectTypeId == ObjectTypes.SilverOre
        || objectTypeId == ObjectTypes.GoldOre || objectTypeId == ObjectTypes.DiamondOre
        || objectTypeId == ObjectTypes.NeptuniumOre
    ) {
      result.requiresResourceTracking = true;
      result.category = ResourceCategory.Mining;
    }

    return result;
  }

  // Get a random resource based on category and coordinates
  function getRandomResource(ResourceCategory category, Vec3 coord, uint256 commitment)
    internal
    view
    returns (ObjectTypeId, uint256)
  {
    // Get resource types and caps
    (ObjectTypeId[] memory resources, uint256[] memory caps) = getResourceInfo(category);

    // Get counts from ResourceCount table
    uint256[] memory collected = new uint256[](resources.length);
    for (uint256 i = 0; i < resources.length; i++) {
      collected[i] = ResourceCount._get(resources[i]);
    }

    // Calculate remaining amounts for each resource and total remaining
    uint256[] memory remaining = new uint256[](resources.length);
    uint256 totalRemaining = 0;
    for (uint256 i = 0; i < resources.length; i++) {
      remaining[i] = caps[i] - collected[i];
      totalRemaining += remaining[i];
    }

    require(totalRemaining > 0, "No resources available to collect");

    // Initialize PRNG with commitment and coordinates
    LibPRNG.PRNG memory prng;
    prng.seed(uint256(keccak256(abi.encodePacked(blockhash(commitment), coord))));

    // Get pseudo random number between 0 and totalRemaining
    uint256 scaledRand = prng.uniform(totalRemaining);

    // Pick resource based on probability distribution
    uint256 resourceIndex = 0;
    uint256 acc = 0;

    for (; resourceIndex < remaining.length - 1; resourceIndex++) {
      acc += remaining[resourceIndex];
      if (scaledRand < acc) break;
    }

    // Return resource type and count
    return (resources[resourceIndex], collected[resourceIndex] + 1);
  }

  // Get the category for a resource type
  function getCategory(ObjectTypeId objectTypeId) internal pure returns (ResourceCategory) {
    if (
      objectTypeId == ObjectTypes.CoalOre || objectTypeId == ObjectTypes.SilverOre
        || objectTypeId == ObjectTypes.GoldOre || objectTypeId == ObjectTypes.DiamondOre
        || objectTypeId == ObjectTypes.NeptuniumOre
    ) {
      return ResourceCategory.Mining;
    } else if (
      objectTypeId == ObjectTypes.WheatSeed || objectTypeId == ObjectTypes.OakSeed
        || objectTypeId == ObjectTypes.SpruceSeed
    ) {
      return ResourceCategory.Farming;
    }

    revert("Unknown resource category for object type");
  }
}
