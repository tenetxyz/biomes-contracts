// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

int32 constant WORLD_BORDER_LOW_X = -2000;
int32 constant WORLD_BORDER_LOW_Y = -150;
int32 constant WORLD_BORDER_LOW_Z = -2000;

int32 constant WORLD_BORDER_HIGH_X = 2000;
int32 constant WORLD_BORDER_HIGH_Y = 250;
int32 constant WORLD_BORDER_HIGH_Z = 2000;

int32 constant SPAWN_LOW_X = 139;
int32 constant SPAWN_HIGH_X = 159;
int32 constant SPAWN_LOW_Z = -34;
int32 constant SPAWN_HIGH_Z = -14;
int32 constant SPAWN_GROUND_Y = -62;

uint16 constant MAX_PLAYER_HEALTH = 1000;
uint32 constant MAX_PLAYER_STAMINA = 120000;

uint32 constant TIME_BEFORE_INCREASE_STAMINA = 1 minutes;
uint32 constant STAMINA_INCREASE_RATE = 1000;
uint16 constant TIME_BEFORE_INCREASE_HEALTH = 1 minutes;
uint16 constant HEALTH_INCREASE_RATE = 20;
uint16 constant GRAVITY_DAMAGE = 100;
uint16 constant PLAYER_HAND_DAMAGE = 20;
uint16 constant HIT_STAMINA_COST = 250;

uint256 constant MIN_TIME_TO_LOGOFF_AFTER_HIT = 1 minutes;

int32 constant MAX_PLAYER_BUILD_MINE_HALF_WIDTH = 5;
int32 constant MAX_PLAYER_RESPAWN_HALF_WIDTH = 5;

uint8 constant MAX_BLOCK_STACKABLE = 99;
uint8 constant MAX_TOOL_STACKABLE = 1;

uint256 constant MAX_PLAYER_INVENTORY_SLOTS = 35;
uint256 constant MAX_CHEST_INVENTORY_SLOTS = 12;

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
