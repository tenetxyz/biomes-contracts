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

int32 constant SPAWN_SHARD_DIM = 1000;
int32 constant FORCE_FIELD_SHARD_DIM = 32;

uint256 constant MIN_TIME_BEFORE_AUTO_LOGOFF = 15 minutes;

int32 constant MAX_PLAYER_INFLUENCE_HALF_WIDTH = 10;
int32 constant MAX_PLAYER_RESPAWN_HALF_WIDTH = 10;

address constant ORACLE_ADDRESS = 0xe67AcfFCe0B542540F1520a9eaD7Aa86ff31196E;
