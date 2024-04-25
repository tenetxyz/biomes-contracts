// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

address constant TERRAIN_WORLD_ADDRESS = 0x0A215592244e40Cf34Fad63bAEe10B7e79990f50;

int16 constant WORLD_BORDER_LOW_X = -2000;
int16 constant WORLD_BORDER_LOW_Y = -150;
int16 constant WORLD_BORDER_LOW_Z = -2000;

int16 constant WORLD_BORDER_HIGH_X = 2000;
int16 constant WORLD_BORDER_HIGH_Y = 250;
int16 constant WORLD_BORDER_HIGH_Z = 2000;

int16 constant SPAWN_LOW_X = 363;
int16 constant SPAWN_LOW_Z = -225;

int16 constant SPAWN_HIGH_X = 387;
int16 constant SPAWN_HIGH_Z = -205;

int16 constant SPAWN_GROUND_Y = 17;

uint16 constant MAX_PLAYER_HEALTH = 1000;
uint32 constant MAX_PLAYER_STAMINA = 120000;

uint32 constant TIME_BEFORE_INCREASE_STAMINA = 1 minutes;
uint32 constant STAMINA_INCREASE_RATE = 100;
uint32 constant WATER_STAMINA_INCREASE_RATE = 2000;
uint16 constant TIME_BEFORE_INCREASE_HEALTH = 1 minutes;
uint16 constant HEALTH_INCREASE_RATE = 20;

uint16 constant GRAVITY_DAMAGE = 100;
uint16 constant PLAYER_HAND_DAMAGE = 20;
uint16 constant HIT_STAMINA_COST = 250;

uint256 constant MIN_TIME_TO_LOGOFF_AFTER_HIT = 1 minutes;

int16 constant MAX_PLAYER_BUILD_MINE_HALF_WIDTH = 5;
int16 constant MAX_PLAYER_RESPAWN_HALF_WIDTH = 5;

uint16 constant MAX_PLAYER_INVENTORY_SLOTS = 36;
uint16 constant MAX_CHEST_INVENTORY_SLOTS = 12;
