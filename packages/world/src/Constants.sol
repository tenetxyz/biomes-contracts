// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

uint32 constant MAX_ENTITY_INFLUENCE_HALF_WIDTH = 10;
uint32 constant MAX_RESPAWN_HALF_WIDTH = 10;

uint16 constant MAX_PLAYER_JUMPS = 3;
uint16 constant MAX_PLAYER_GLIDES = 10;
uint16 constant PLAYER_FALL_DAMAGE_THRESHOLD = 3;

uint256 constant SPAWN_BLOCK_RANGE = 10;

int32 constant FRAGMENT_SIZE = 8; // 8x8x8 (3D)
int32 constant CHUNK_SIZE = 16; // 16x16x16 (3D)
int32 constant REGION_SIZE = 512; // 512x512 (2D)

uint256 constant SAFE_PROGRAM_GAS = 1_000_000;

uint256 constant CHUNK_COMMIT_EXPIRY_BLOCKS = 256;
uint256 constant CHUNK_COMMIT_HALF_WIDTH = 2;
uint256 constant RESPAWN_ORE_BLOCK_RANGE = 10;

// ------------------------------------------------------------
// Values To Tune
// ------------------------------------------------------------
uint128 constant MAX_PLAYER_ENERGY = 817400000000000000;
uint128 constant PLAYER_ENERGY_DRAIN_RATE = 1351521164000;

uint128 constant MACHINE_ENERGY_DRAIN_RATE = 7966149167;

uint128 constant SMART_CHEST_ENERGY_COST = 10000000000000000;

uint128 constant BUILD_ENERGY_COST = 8100000000000000;
uint128 constant MINE_ENERGY_COST = 8100000000000000;
uint128 constant HIT_ENERGY_COST = 8100000000000000;
uint128 constant TILL_ENERGY_COST = 8100000000000000;
uint128 constant CRAFT_ENERGY_COST = 8100000000000000;
uint128 constant MOVE_ENERGY_COST = 25543750000000;
uint128 constant PLAYER_FALL_ENERGY_COST = MAX_PLAYER_ENERGY / 25; // This makes it so, with full energy, you die from a 25 block fall

// Resource caps
uint256 constant MAX_WHEAT_SEED = 5_000_000;
uint256 constant MAX_OAK_SEED = 1_000_000;
uint256 constant MAX_SPRUCE_SEED = 1_000_000;

uint256 constant MAX_COAL = 13_116_437;
uint256 constant MAX_IRON = 4_213_327;
uint256 constant MAX_GOLD = 356_434;
uint256 constant MAX_DIAMOND = 18_696;
uint256 constant MAX_EMERALD = 23_046;

uint128 constant INITIAL_ENERGY_PER_VEGETATION = 10000000000000000;
uint128 constant INITIAL_LOCAL_ENERGY_BUFFER = 2678400000000000000;
