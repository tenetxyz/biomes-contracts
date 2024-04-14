// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IStore } from "@latticexyz/store/src/IStore.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ITerrainSystem } from "@biomesaw/terrain/src/codegen/world/ITerrainSystem.sol";
import { ObjectTypeMetadata } from "@biomesaw/terrain/src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "@biomesaw/terrain/src/codegen/tables/Recipes.sol";

import { TERRAIN_WORLD_ADDRESS } from "../Constants.sol";

function getTerrainObjectTypeId(VoxelCoord memory coord) view returns (uint8) {
  return ITerrainSystem(TERRAIN_WORLD_ADDRESS).getTerrainObjectTypeId(coord);
}

function getRecipe(bytes32 recipeId) view returns (RecipesData memory) {
  return Recipes.get(IStore(TERRAIN_WORLD_ADDRESS), recipeId);
}

function getObjectTypeMass(uint8 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getMass(IStore(TERRAIN_WORLD_ADDRESS), objectTypeId);
}

function getObjectTypeStackable(uint8 objectTypeId) view returns (uint8) {
  return ObjectTypeMetadata.getStackable(IStore(TERRAIN_WORLD_ADDRESS), objectTypeId);
}

function getObjectTypeDamage(uint8 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getDamage(IStore(TERRAIN_WORLD_ADDRESS), objectTypeId);
}

function getObjectTypeDurability(uint8 objectTypeId) view returns (uint24) {
  return ObjectTypeMetadata.getDurability(IStore(TERRAIN_WORLD_ADDRESS), objectTypeId);
}

function getObjectTypeHardness(uint8 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getHardness(IStore(TERRAIN_WORLD_ADDRESS), objectTypeId);
}

function getObjectTypeIsBlock(uint8 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getIsBlock(IStore(TERRAIN_WORLD_ADDRESS), objectTypeId);
}
