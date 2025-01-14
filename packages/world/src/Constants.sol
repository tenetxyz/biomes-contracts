// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

bool constant IN_MAINTENANCE = false;

uint16 constant PLAYER_MASS = 10;

uint8 constant MAX_BLOCK_STACKABLE = 99;
uint8 constant MAX_TOOL_STACKABLE = 1;

int16 constant STRUCTURE_CHUNK = 5;
int16 constant STRUCTURE_CHUNK_CENTER = STRUCTURE_CHUNK / 2 + 1;

int16 constant WORLD_BORDER_LOW_X = -2016;
int16 constant WORLD_BORDER_LOW_Y = -160;
int16 constant WORLD_BORDER_LOW_Z = -2016;

int16 constant WORLD_BORDER_HIGH_X = 2016;
int16 constant WORLD_BORDER_HIGH_Y = 256;
int16 constant WORLD_BORDER_HIGH_Z = 2016;

int16 constant SPAWN_SHARD_DIM = 1000;
int16 constant FORCE_FIELD_SHARD_DIM = 32;

uint16 constant MAX_PLAYER_HEALTH = 1000;
uint32 constant MAX_PLAYER_STAMINA = 120_000;

uint32 constant TIME_BEFORE_INCREASE_STAMINA = 1 minutes;
// Note: temporarily stamina increase rate is 2000 per minute, until we add food
uint32 constant STAMINA_INCREASE_RATE = 1000;
uint32 constant WATER_STAMINA_INCREASE_RATE = 1000;
uint16 constant TIME_BEFORE_INCREASE_HEALTH = 1 minutes;
uint16 constant HEALTH_INCREASE_RATE = 20;

uint16 constant TIME_BEFORE_DECREASE_BATTERY_LEVEL = 1 minutes;

uint16 constant GRAVITY_DAMAGE = 100;
uint16 constant PLAYER_HAND_DAMAGE = 100;
uint16 constant HIT_PLAYER_STAMINA_COST = 250;
uint16 constant GRAVITY_STAMINA_COST = 10;
uint16 constant MINE_STAMINA_COST = 60;
uint16 constant HIT_CHIP_STAMINA_COST = 500;

uint256 constant MIN_TIME_BEFORE_AUTO_LOGOFF = 15 minutes;
uint256 constant MIN_TIME_TO_LOGOFF_AFTER_HIT = 1 minutes;

int16 constant MAX_PLAYER_INFLUENCE_HALF_WIDTH = 10;
int16 constant MAX_PLAYER_RESPAWN_HALF_WIDTH = 10;

uint16 constant MAX_PLAYER_INVENTORY_SLOTS = 36;
uint16 constant MAX_CHEST_INVENTORY_SLOTS = 12;

uint256 constant NUM_XP_FOR_FULL_BATTERY = 5_000;
uint256 constant CHARGE_PER_BATTERY = 4 days;

address constant OP_L1_GAS_ORACLE = 0x420000000000000000000000000000000000000F;
