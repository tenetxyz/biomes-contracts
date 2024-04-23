// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

uint16 constant PLAYER_MASS = 10;

uint8 constant MAX_BLOCK_STACKABLE = 99;
uint8 constant MAX_TOOL_STACKABLE = 1;

// Terrain
enum Biome {
  Mountains,
  Desert,
  Forest,
  Savanna
}

int16 constant STRUCTURE_CHUNK = 5;
int16 constant STRUCTURE_CHUNK_CENTER = STRUCTURE_CHUNK / 2 + 1;
