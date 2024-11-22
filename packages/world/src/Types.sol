// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { PlayerMetadataData } from "./codegen/tables/PlayerMetadata.sol";
import { HealthData } from "./codegen/tables/Health.sol";
import { StaminaData } from "./codegen/tables/Stamina.sol";
import { ChipData } from "./codegen/tables/Chip.sol";

enum Biome {
  Mountains,
  Desert,
  Forest,
  Savanna
}

struct InventoryTool {
  bytes32 entityId;
  uint24 numUsesLeft;
}

struct InventoryObject {
  uint8 objectTypeId;
  uint16 numObjects;
  InventoryTool[] tools;
}

struct PlayerEntityData {
  address playerAddress;
  bytes32 entityId;
  VoxelCoord position;
  PlayerMetadataData metadata;
  bytes32 equippedEntityId;
  InventoryObject[] inventory;
  HealthData health;
  StaminaData stamina;
  uint256 xp;
  uint256 lastActionTime;
}

struct BlockEntityData {
  bytes32 entityId;
  bytes32 baseEntityId;
  uint8 objectTypeId;
  VoxelCoord position;
  InventoryObject[] inventory;
  ChipData chip;
}

struct EntityData {
  uint8 objectTypeId;
  bytes32 entityId;
  InventoryObject[] inventory;
  VoxelCoord position;
}

struct EntityDataWithBaseEntity {
  uint8 objectTypeId;
  bytes32 entityId;
  bytes32 baseEntityId;
  InventoryObject[] inventory;
  VoxelCoord position;
}

struct PickupData {
  uint8 objectTypeId;
  uint16 numToPickup;
}

struct DisplayContent {
  uint8 contentType;
  bytes content;
}
