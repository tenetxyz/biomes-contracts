// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {LibPRNG} from "solady/utils/LibPRNG.sol";

import {ResourceCount} from "./codegen/tables/ResourceCount.sol";
import {ChunkCommitment} from "./utils/Vec3Storage.sol";

import {
    CHUNK_COMMIT_EXPIRY_BLOCKS,
    MAX_COAL,
    MAX_DIAMOND,
    MAX_GOLD,
    MAX_EMERALD,
    MAX_IRON,
    MAX_WHEAT_SEED
} from "./Constants.sol";
import {ObjectTypeId} from "./ObjectTypeId.sol";
import {ObjectAmount, ObjectTypeLib, getOreObjectTypes} from "./ObjectTypeLib.sol";
import {ObjectTypes} from "./ObjectTypes.sol";
import {Vec3} from "./Vec3.sol";

library NatureLib {
    using LibPRNG for LibPRNG.PRNG;
    using ObjectTypeLib for ObjectTypeId;

    function getMineDrops(ObjectTypeId objectTypeId, Vec3 coord) internal view returns (ObjectAmount[] memory result) {
        // Wheat drops wheat + 0-3 wheat seeds
        if (objectTypeId == ObjectTypes.Wheat) {
            return getWheatDrops(objectTypeId, getRandomSeed(coord));
        }

        // FescueGrass has a chance to drop wheat seeds
        if (objectTypeId == ObjectTypes.FescueGrass) {
            return getGrassDrops(getRandomSeed(coord));
        }

        if (objectTypeId == ObjectTypes.Farmland || objectTypeId == ObjectTypes.WetFarmland) {
            result = new ObjectAmount[](1);
            result[0] = ObjectAmount(ObjectTypes.Dirt, 1);
            return result;
        }

        // Default behavior for all other objects
        result = new ObjectAmount[](1);
        result[0] = ObjectAmount(objectTypeId, 1);

        return result;
    }

    function getWheatDrops(ObjectTypeId objectTypeId, uint256 randomSeed)
        internal
        view
        returns (ObjectAmount[] memory result)
    {
        // Distribution with expected value of exactly 1
        uint256[] memory distribution = new uint256[](4);
        distribution[0] = 40; // 0 seeds: 40%
        distribution[1] = 30; // 1 seed: 30%
        distribution[2] = 20; // 2 seeds: 20%
        distribution[3] = 10; // 3 seeds: 10%

        // Get wheat seed options and their weights using distribution
        (ObjectAmount[] memory seedOptions, uint256[] memory weights) =
            getDropWeights(ObjectTypes.WheatSeed, distribution);

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

    function getGrassDrops(uint256 randomSeed) internal view returns (ObjectAmount[] memory result) {
        uint256[] memory distribution = new uint256[](2);
        distribution[0] = 43; // No seed: 43%
        distribution[1] = 57; // 1 seed: 57%

        (ObjectAmount[] memory grassOptions, uint256[] memory weights) =
            getDropWeights(ObjectTypes.WheatSeed, distribution);

        // Select drop based on calculated weights
        ObjectAmount memory seedDrop = selectObjectByWeight(grassOptions, weights, randomSeed);

        if (seedDrop.objectTypeId != ObjectTypes.Null) {
            result = new ObjectAmount[](1);
            result[0] = seedDrop;
        }

        return result;
    }

    function getRandomOre(Vec3 coord) internal view returns (ObjectTypeId) {
        uint256 seed = getRandomSeed(coord);

        // Get ore options and their weights (based on remaining amounts)
        ObjectAmount[] memory oreOptions = new ObjectAmount[](5);
        uint256[] memory weights = new uint256[](5);

        ObjectTypeId[] memory oreTypes = getOreObjectTypes();
        // Use remaining amounts directly as weights
        for (uint256 i = 0; i < weights.length; i++) {
            oreOptions[i] = ObjectAmount(oreTypes[i], 1);
            weights[i] = getRemainingAmount(oreTypes[i]);
        }

        // Select ore based on availability
        ObjectAmount memory selectedOre = selectObjectByWeight(oreOptions, weights, seed);

        // Return selected ore type and current mined count
        return selectedOre.objectTypeId;
    }

    function getRandomSeed(Vec3 coord) internal view returns (uint256) {
        // Get chunk commitment for the coord, but only validate it for random resources (done in NatureLib)
        Vec3 chunkCoord = coord.toChunkCoord();
        uint256 commitment = ChunkCommitment._get(chunkCoord);
        // We can't get blockhash of current block
        require(block.number > commitment, "Not within commitment blocks");
        require(block.number <= commitment + CHUNK_COMMIT_EXPIRY_BLOCKS, "Chunk commitment expired");
        return uint256(keccak256(abi.encodePacked(blockhash(commitment), coord)));
    }

    // Get resource cap for a specific resource type
    function getResourceCap(ObjectTypeId objectTypeId) internal pure returns (uint256) {
        if (objectTypeId == ObjectTypes.CoalOre) return MAX_COAL;
        if (objectTypeId == ObjectTypes.IronOre) return MAX_IRON;
        if (objectTypeId == ObjectTypes.GoldOre) return MAX_GOLD;
        if (objectTypeId == ObjectTypes.DiamondOre) return MAX_DIAMOND;
        if (objectTypeId == ObjectTypes.EmeraldOre) return MAX_EMERALD;
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
    function selectObjectByWeight(ObjectAmount[] memory options, uint256[] memory weights, uint256 seed)
        internal
        pure
        returns (ObjectAmount memory)
    {
        return options[selectByWeight(weights, seed)];
    }

    // Simple weighted selection from an array of weights
    function selectByWeight(uint256[] memory weights, uint256 seed) internal pure returns (uint256) {
        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
        }

        require(totalWeight > 0, "No options available");

        // Initialize PRNG
        // TODO: maybe this is not necessary as we already have a random seed
        LibPRNG.PRNG memory prng;
        prng.seed(seed);

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

    // Adjusts pre-calculated weights based on resource availability
    function getDropWeights(ObjectTypeId objectType, uint256[] memory distribution)
        internal
        view
        returns (ObjectAmount[] memory options, uint256[] memory weights)
    {
        uint8 maxAmount = uint8(distribution.length - 1);

        options = new ObjectAmount[](distribution.length);
        options[0] = ObjectAmount(ObjectTypes.Null, 0); // Option for 0 drops

        for (uint8 i = 1; i <= maxAmount; i++) {
            options[i] = ObjectAmount(objectType, i);
        }

        // Start with the base weights and adjust for availability
        weights = new uint256[](distribution.length);
        weights[0] = distribution[0]; // Weight for 0 drops stays the same

        // Get resource availability info
        uint256 remaining = getRemainingAmount(objectType);
        uint256 cap = getResourceCap(objectType);

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
