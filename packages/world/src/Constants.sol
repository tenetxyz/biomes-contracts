// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

uint16 constant MAX_BLOCK_STACKABLE = 99;
uint16 constant MAX_ITEM_STACKABLE = 99;
uint16 constant MAX_TOOL_STACKABLE = 1;

int32 constant WORLD_BORDER_LOW_X = -2016;
int32 constant WORLD_BORDER_LOW_Y = -160;
int32 constant WORLD_BORDER_LOW_Z = -2016;

int32 constant WORLD_BORDER_HIGH_X = 2016;
int32 constant WORLD_BORDER_HIGH_Y = 256;
int32 constant WORLD_BORDER_HIGH_Z = 2016;

int32 constant WORLD_DIM_X = WORLD_BORDER_HIGH_X - WORLD_BORDER_LOW_X;
int32 constant WORLD_DIM_Z = WORLD_BORDER_HIGH_Z - WORLD_BORDER_LOW_Z;

int32 constant FORCE_FIELD_SHARD_DIM = 32;
int32 constant LOCAL_ENERGY_POOL_SHARD_DIM = 512;

uint256 constant MIN_TIME_BEFORE_AUTO_LOGOFF = 15 minutes;

int32 constant MAX_PLAYER_INFLUENCE_HALF_WIDTH = 10;
int32 constant MAX_PLAYER_RESPAWN_HALF_WIDTH = 10;

int32 constant SPAWN_AREA_HALF_WIDTH = 5;
uint256 constant SPAWN_BLOCK_RANGE = 10;

int32 constant CHUNK_SIZE = 16;
int32 constant AREA_SIZE = 512;

uint256 constant SAFE_CHIP_GAS = 1_000_000;

uint256 constant CHUNK_COMMIT_EXPIRY_BLOCKS = 256;
int32 constant CHUNK_COMMIT_HALF_WIDTH = 2;
uint256 constant RESPAWN_ORE_BLOCK_RANGE = 10;

// ------------------------------------------------------------
// Values To Tune
// ------------------------------------------------------------
uint128 constant MASS_TO_ENERGY_MULTIPLIER = 50;

uint128 constant MAX_PLAYER_ENERGY = 100_000;
uint128 constant PLAYER_ENERGY_DRAIN_RATE = 100;
uint128 constant PLAYER_ENERGY_DRAIN_INTERVAL = 1 seconds;
uint128 constant MIN_PLAYER_ENERGY_THRESHOLD_TO_DRAIN = MAX_PLAYER_ENERGY / 10;

uint128 constant MACHINE_ENERGY_DRAIN_RATE = 100;
uint128 constant MACHINE_ENERGY_DRAIN_INTERVAL = 1 seconds;
uint128 constant MIN_MACHINE_ENERGY_THRESHOLD_TO_DRAIN = 0;

uint128 constant SMART_CHEST_ENERGY_COST = 100;

uint128 constant PLAYER_BUILD_ENERGY_COST = 100;
uint128 constant PLAYER_MINE_ENERGY_COST = 1000;
uint128 constant PLAYER_HIT_ENERGY_COST = 100;
uint128 constant PLAYER_MOVE_ENERGY_COST = 100;
uint128 constant PLAYER_CRAFT_ENERGY_COST = 100;
uint128 constant PLAYER_DROP_ENERGY_COST = 100;
uint128 constant PLAYER_PICKUP_ENERGY_COST = 100;
uint128 constant PLAYER_TRANSFER_ENERGY_COST = 100;

uint256 constant MAX_COAL = 10_000_000;
uint256 constant MAX_SILVER = 5_000_000;
uint256 constant MAX_GOLD = 1_000_000;
uint256 constant MAX_DIAMOND = 500_000;
uint256 constant MAX_NEPTUNIUM = 100_000;
