// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { CommitmentData } from "./codegen/tables/Commitment.sol";
import { EnergyData } from "./codegen/tables/Energy.sol";
import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "./VoxelCoord.sol";
import { EntityId } from "./EntityId.sol";

struct ChunkCoord {
  int32 x;
  int32 y;
  int32 z;
}

struct InventoryEntity {
  EntityId entityId;
  uint128 mass;
}

struct InventoryObject {
  uint16 objectTypeId;
  uint16 numObjects;
  InventoryEntity[] inventoryEntities;
}

struct PlayerEntityData {
  address playerAddress;
  EntityId entityId;
  VoxelCoord position;
  bool isLoggedOff;
  EntityId equippedEntityId;
  InventoryObject[] inventory;
  uint256 mass;
  EnergyData energy;
  uint256 lastActionTime;
  CommitmentData commitment;
}

struct BlockEntityData {
  EntityId entityId;
  EntityId baseEntityId;
  uint16 objectTypeId;
  VoxelCoord position;
  InventoryObject[] inventory;
  address chipAddress;
}

struct EntityData {
  uint16 objectTypeId;
  EntityId entityId;
  EntityId baseEntityId;
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
  EntityId[] toolEntityIds;
}

struct PipeTransferData {
  EntityId targetEntityId;
  VoxelCoordDirectionVonNeumann[] path;
  TransferData transferData;
  bytes extraData;
}

struct ChipOnTransferData {
  EntityId targetEntityId; // The entity whose chip is being called
  EntityId callerEntityId; // The entity initiating the transfer
  bool isDeposit; // true = caller->target, false = target->caller
  TransferData transferData;
  bytes extraData;
}

struct ChipOnPipeTransferData {
  EntityId playerEntityId;
  EntityId targetEntityId; // The entity whose chip is being called
  EntityId callerEntityId; // The entity initiating the transfer
  bool isDeposit; // true = caller->target, false = target->caller
  VoxelCoordDirectionVonNeumann[] path;
  TransferData transferData;
  bytes extraData;
}

struct TransferCommonContext {
  EntityId playerEntityId;
  EntityId chestEntityId;
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
