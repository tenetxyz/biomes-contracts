// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { CommitmentData } from "./codegen/tables/Commitment.sol";

struct InventoryTool {
  bytes32 entityId;
  uint256 numUsesLeft;
}

struct InventoryObject {
  uint16 objectTypeId;
  uint16 numObjects;
  InventoryTool[] tools;
}

struct PlayerEntityData {
  address playerAddress;
  bytes32 entityId;
  VoxelCoord position;
  bool isLoggedOff;
  bytes32 equippedEntityId;
  InventoryObject[] inventory;
  uint256 lastActionTime;
  CommitmentData commitment;
}

struct BlockEntityData {
  bytes32 entityId;
  bytes32 baseEntityId;
  uint16 objectTypeId;
  VoxelCoord position;
  InventoryObject[] inventory;
  address chipAddress;
}

struct EntityData {
  uint16 objectTypeId;
  bytes32 entityId;
  bytes32 baseEntityId;
  InventoryObject[] inventory;
  VoxelCoord position;
}

struct PickupData {
  uint16 objectTypeId;
  uint16 numToPickup;
}

struct TransferData {
  uint16 objectTypeId;
  uint16 numToTransfer;
  bytes32[] toolEntityIds;
}

struct PipeTransferData {
  bytes32 targetEntityId;
  VoxelCoordDirectionVonNeumann[] path;
  TransferData transferData;
  bytes extraData;
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

struct TransferCommonContext {
  bytes32 playerEntityId;
  bytes32 chestEntityId;
  VoxelCoord chestCoord;
  uint16 chestObjectTypeId;
  uint16 dstObjectTypeId;
  address chipAddress;
  uint256 machineEnergyLevel;
  bool isDeposit;
}

struct PipeTransferCommonContext {
  VoxelCoord targetCoord;
  address chipAddress;
  uint256 machineEnergyLevel;
  uint16 targetObjectTypeId;
}
