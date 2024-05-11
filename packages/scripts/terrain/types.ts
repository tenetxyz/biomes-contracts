import { Perlin } from "@latticexyz/noise";
import { VoxelCoord } from "@latticexyz/utils";

export type TerrainState = {
  coord: VoxelCoord;
  biomeVector: [number, number, number, number];
  height: number;
  perlin: Perlin;
  biome?: number;
  coordHash2D?: number;
  coordHash1D?: number;
  chunkHash?: number;
  chunkHash2?: number;
  biomeHash?: number;
  chunkOffset?: VoxelCoord;
  chunkHeight?: number;
  distanceFromHeight?: number;
};
