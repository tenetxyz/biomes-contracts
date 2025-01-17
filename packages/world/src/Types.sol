// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { PlayerMetadataData } from "./codegen/tables/PlayerMetadata.sol";
import { HealthData } from "./codegen/tables/Health.sol";
import { StaminaData } from "./codegen/tables/Stamina.sol";
import { ChipData } from "./codegen/tables/Chip.sol";
import { CommitmentData } from "./codegen/tables/Commitment.sol";

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

struct PlayerEntityDataWithCommitment {
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
  CommitmentData commitment;
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

struct PipeTransferData {
  bytes32 targetEntityId;
  VoxelCoordDirectionVonNeumann[] path;
  TransferData transferData;
}

struct TransferData {
  uint8 objectTypeId;
  uint16 numToTransfer;
  bytes32[] toolEntityIds;
}

struct ChipOnTransferData {
  bytes32 targetEntityId; // The entity whose chip is being called
  bytes32 callerEntityId; // The entity initiating the transfer
  bool isDeposit; // true = caller->target, false = target->caller
  TransferData transferData;
  bytes extraData;
}

struct ChipOnPipeTransferData {
  bytes32 playerEntityId;
  bytes32 targetEntityId; // The entity whose chip is being called
  bytes32 callerEntityId; // The entity initiating the transfer
  bool isDeposit; // true = caller->target, false = target->caller
  VoxelCoordDirectionVonNeumann[] path;
  TransferData transferData;
  bytes extraData;
}
