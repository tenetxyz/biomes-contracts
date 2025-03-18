// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

uint32 constant MAX_PLAYER_INFLUENCE_HALF_WIDTH = 10;
uint32 constant MAX_PLAYER_RESPAWN_HALF_WIDTH = 10;

uint16 constant MAX_PLAYER_JUMPS = 3;
uint16 constant MAX_PLAYER_GLIDES = 10;
uint16 constant PLAYER_FALL_DAMAGE_THRESHOLD = 3;

uint256 constant SPAWN_BLOCK_RANGE = 10;

int32 constant FRAGMENT_SIZE = 8; // 8x8x8 (3D)
int32 constant CHUNK_SIZE = 16; // 16x16x16 (3D)
int32 constant REGION_SIZE = 512; // 512x512 (2D)

uint256 constant SAFE_CHIP_GAS = 1_000_000;

uint256 constant CHUNK_COMMIT_EXPIRY_BLOCKS = 256;
uint256 constant CHUNK_COMMIT_HALF_WIDTH = 2;
uint256 constant RESPAWN_ORE_BLOCK_RANGE = 10;

// ------------------------------------------------------------
// Values To Tune
// ------------------------------------------------------------
uint128 constant MASS_TO_ENERGY_MULTIPLIER = 50;

uint128 constant MAX_PLAYER_ENERGY = 1_000_000;
uint128 constant PLAYER_ENERGY_DRAIN_RATE = 10;

uint128 constant MACHINE_ENERGY_DRAIN_RATE = 100;

uint128 constant SMART_CHEST_ENERGY_COST = 100;

uint128 constant PLAYER_BUILD_ENERGY_COST = 100;
uint128 constant PLAYER_MINE_ENERGY_COST = 100;
uint128 constant PLAYER_HIT_ENERGY_COST = 100;
uint128 constant PLAYER_MOVE_ENERGY_COST = 5;
uint128 constant PLAYER_FALL_ENERGY_COST = MAX_PLAYER_ENERGY / 25; // This makes it so, with full energy, you die from a 25 block fall
uint128 constant PLAYER_CRAFT_ENERGY_COST = 100;
uint128 constant PLAYER_DROP_ENERGY_COST = 100;
uint128 constant PLAYER_PICKUP_ENERGY_COST = 100;
uint128 constant PLAYER_TRANSFER_ENERGY_COST = 100;
uint128 constant PLAYER_TILL_ENERGY_COST = 100;

uint256 constant MAX_COAL = 10_000_000;
uint256 constant MAX_SILVER = 5_000_000;
uint256 constant MAX_GOLD = 1_000_000;
uint256 constant MAX_DIAMOND = 500_000;
uint256 constant MAX_NEPTUNIUM = 100_000;

uint128 constant INITIAL_ENERGY_PER_VEGETATION = 100;
