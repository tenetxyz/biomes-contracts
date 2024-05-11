import { AIR_OBJECT_ID, BiomesVariantData, getBiomesVariantDataStrict } from "./objectTypeIds";
import { Perlin } from "@latticexyz/noise";
import { VoxelCoord } from "@latticexyz/utils";
import { getBiome } from "./getBiome";
import { getHeight } from "./getHeight";
import { Air, Flora, Ores, TerrainBlocks, Trees, Water } from "./occurence";
import { TerrainState } from "./types";

export function getTerrain(coord: VoxelCoord, perlin: Perlin) {
  const biome = getBiome(coord, perlin);
  const height = getHeight(coord, biome, perlin);
  return { biome, height };
}

export function getTerrainBlock(coord: VoxelCoord, perlin: Perlin): BiomesVariantData {
  const { biome, height } = getTerrain(coord, perlin);
  const state: TerrainState = { biomeVector: biome, height, coord, perlin };

  return (
    Water(state) ||
    Air(state) ||
    Ores(state) ||
    TerrainBlocks(state) ||
    Trees(state) ||
    Flora(state) ||
    getBiomesVariantDataStrict(AIR_OBJECT_ID)
  );
}
