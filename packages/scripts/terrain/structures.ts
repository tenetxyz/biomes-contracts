import {
  BIRCH_LEAF_OBJECT_ID,
  BIRCH_LOG_OBJECT_ID,
  OAK_LEAF_OBJECT_ID,
  OAK_LOG_OBJECT_ID,
  RUBBER_LEAF_OBJECT_ID,
  RUBBER_LOG_OBJECT_ID,
  SAKURA_LEAF_OBJECT_ID,
  SAKURA_LOG_OBJECT_ID,
} from "./objectTypeIds";
import { VoxelCoord } from "@latticexyz/utils";
import { STRUCTURE_CHUNK } from "./constants";
import { TerrainState } from "./types";
import { accessState } from "./utils";

export type Structure = (number | undefined)[][][];

function getEmptyStructure(): Structure {
  return [
    [[], [], [], [], []],
    [[], [], [], [], []],
    [[], [], [], [], []],
    [[], [], [], [], []],
    [[], [], [], [], []],
  ];
}

function defineOakTree(): Structure {
  const s = getEmptyStructure();

  // // fill up the entire structure
  // for (let i = 0; i < STRUCTURE_CHUNK; i++) {
  //   for (let j = 0; j < STRUCTURE_CHUNK; j++) {
  //     for (let k = 0; k < STRUCTURE_CHUNK; k++) {
  //       s[i][j][k] = BIRCH_LEAF_OBJECT_ID;
  //     }
  //   }
  // }

  // Trunk
  s[3][0][3] = OAK_LOG_OBJECT_ID;
  s[3][1][3] = OAK_LOG_OBJECT_ID;
  s[3][2][3] = OAK_LOG_OBJECT_ID;
  s[3][3][3] = OAK_LOG_OBJECT_ID;

  // Leaves
  s[2][3][3] = OAK_LEAF_OBJECT_ID;
  s[3][3][2] = OAK_LEAF_OBJECT_ID;
  s[4][3][3] = OAK_LEAF_OBJECT_ID;
  s[3][3][4] = OAK_LEAF_OBJECT_ID;
  s[2][3][2] = OAK_LEAF_OBJECT_ID;
  s[4][3][4] = OAK_LEAF_OBJECT_ID;
  s[2][3][4] = OAK_LEAF_OBJECT_ID;
  s[4][3][2] = OAK_LEAF_OBJECT_ID;
  s[2][4][3] = OAK_LEAF_OBJECT_ID;
  s[3][4][2] = OAK_LEAF_OBJECT_ID;
  s[4][4][3] = OAK_LEAF_OBJECT_ID;
  s[3][4][4] = OAK_LEAF_OBJECT_ID;
  s[3][4][3] = OAK_LEAF_OBJECT_ID;

  return s;
}

function defineBirchTree(): Structure {
  const s = getEmptyStructure();

  // Trunk
  s[3][0][3] = BIRCH_LOG_OBJECT_ID;
  s[3][1][3] = BIRCH_LOG_OBJECT_ID;
  s[3][2][3] = BIRCH_LOG_OBJECT_ID;
  s[3][3][3] = BIRCH_LOG_OBJECT_ID;

  // Leaves
  s[2][3][3] = BIRCH_LEAF_OBJECT_ID;
  s[3][3][2] = BIRCH_LEAF_OBJECT_ID;
  s[4][3][3] = BIRCH_LEAF_OBJECT_ID;
  s[3][3][4] = BIRCH_LEAF_OBJECT_ID;
  s[2][3][2] = BIRCH_LEAF_OBJECT_ID;
  s[4][3][4] = BIRCH_LEAF_OBJECT_ID;
  s[2][3][4] = BIRCH_LEAF_OBJECT_ID;
  s[4][3][2] = BIRCH_LEAF_OBJECT_ID;
  s[2][4][3] = BIRCH_LEAF_OBJECT_ID;
  s[3][4][2] = BIRCH_LEAF_OBJECT_ID;
  s[4][4][3] = BIRCH_LEAF_OBJECT_ID;
  s[3][4][4] = BIRCH_LEAF_OBJECT_ID;
  s[3][4][3] = BIRCH_LEAF_OBJECT_ID;

  return s;
}

function defineSakuraTree(): Structure {
  const s = getEmptyStructure();

  // Trunk
  s[3][0][3] = SAKURA_LOG_OBJECT_ID;
  s[3][1][3] = SAKURA_LOG_OBJECT_ID;
  s[3][2][3] = SAKURA_LOG_OBJECT_ID;
  s[3][3][3] = SAKURA_LOG_OBJECT_ID;

  // Leaves
  s[2][3][3] = SAKURA_LEAF_OBJECT_ID;
  s[3][3][2] = SAKURA_LEAF_OBJECT_ID;
  s[4][3][3] = SAKURA_LEAF_OBJECT_ID;
  s[3][3][4] = SAKURA_LEAF_OBJECT_ID;
  s[2][3][2] = SAKURA_LEAF_OBJECT_ID;
  s[4][3][4] = SAKURA_LEAF_OBJECT_ID;
  s[2][3][4] = SAKURA_LEAF_OBJECT_ID;
  s[4][3][2] = SAKURA_LEAF_OBJECT_ID;
  s[2][4][3] = SAKURA_LEAF_OBJECT_ID;
  s[3][4][2] = SAKURA_LEAF_OBJECT_ID;
  s[4][4][3] = SAKURA_LEAF_OBJECT_ID;
  s[3][4][4] = SAKURA_LEAF_OBJECT_ID;
  s[3][4][3] = SAKURA_LEAF_OBJECT_ID;

  return s;
}

function defineRubberTree(): Structure {
  const s = getEmptyStructure();

  // Trunk
  s[3][0][3] = RUBBER_LOG_OBJECT_ID;
  s[3][1][3] = RUBBER_LOG_OBJECT_ID;
  s[3][2][3] = RUBBER_LOG_OBJECT_ID;
  s[3][3][3] = RUBBER_LOG_OBJECT_ID;

  // Leaves
  s[2][3][3] = RUBBER_LEAF_OBJECT_ID;
  s[3][3][2] = RUBBER_LEAF_OBJECT_ID;
  s[4][3][3] = RUBBER_LEAF_OBJECT_ID;
  s[3][3][4] = RUBBER_LEAF_OBJECT_ID;
  s[2][3][2] = RUBBER_LEAF_OBJECT_ID;
  s[4][3][4] = RUBBER_LEAF_OBJECT_ID;
  s[2][3][4] = RUBBER_LEAF_OBJECT_ID;
  s[4][3][2] = RUBBER_LEAF_OBJECT_ID;
  s[2][4][3] = RUBBER_LEAF_OBJECT_ID;
  s[3][4][2] = RUBBER_LEAF_OBJECT_ID;
  s[4][4][3] = RUBBER_LEAF_OBJECT_ID;
  s[3][4][4] = RUBBER_LEAF_OBJECT_ID;
  s[3][4][3] = RUBBER_LEAF_OBJECT_ID;

  return s;
}

export function defineHashedPatch(state: TerrainState, objectID: number): Structure {
  const s = getEmptyStructure();
  const hash1 = accessState(state, "chunkHash2"); // Main hash for overall density control
  const hash2 = accessState(state, "coordHash2D"); // Secondary hash for finer variations

  // Convert hashes into a seeding number for density (adjust factors as needed)
  const densitySeed = (hash1 % 10) + (hash2 % 10); // This will adjust the density of the cotton patch

  for (let i = 0; i < STRUCTURE_CHUNK; i++) {
    for (let j = 0; j < STRUCTURE_CHUNK; j++) {
      for (let k = 0; k < STRUCTURE_CHUNK; k++) {
        // Apply a conditional based on the density seed to decide if a cotton bush should be placed
        if ((i + j + k + densitySeed) % 3 === 0) {
          // Every third position influenced by density seed
          s[i][j][k] = objectID;
        }
      }
    }
  }

  return s;
}

export function getStructureBlock(structure: Structure, { x, y, z }: VoxelCoord) {
  if (x < 0 || y < 0 || z < 0 || x >= STRUCTURE_CHUNK || y >= STRUCTURE_CHUNK || z >= STRUCTURE_CHUNK) return undefined;
  return structure[x][y][z];
}

export const OakTree = defineOakTree();
export const BirchTree = defineBirchTree();
export const SakuraTree = defineSakuraTree();
export const RubberTree = defineRubberTree();
