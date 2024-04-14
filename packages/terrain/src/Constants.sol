// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

// Terrain
enum Biome {
  Mountains,
  Mountains2,
  Mountains3,
  Mountains4,
  Swamp,
  Plains,
  Forest,
  Desert
}

int32 constant STRUCTURE_CHUNK = 5;
int32 constant STRUCTURE_CHUNK_CENTER = STRUCTURE_CHUNK / 2 + 1;
