// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { EnergyData } from "./codegen/tables/Energy.sol";
import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "./VoxelCoord.sol";
import { EntityId } from "./EntityId.sol";
import { ObjectTypeId } from "./ObjectTypeIds.sol";

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
  ObjectTypeId objectTypeId;
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
}

struct BlockEntityData {
  EntityId entityId;
  EntityId baseEntityId;
  ObjectTypeId objectTypeId;
  VoxelCoord position;
  InventoryObject[] inventory;
  address chipAddress;
}

struct EntityData {
  ObjectTypeId objectTypeId;
  EntityId entityId;
  EntityId baseEntityId;
  InventoryObject[] inventory;
  VoxelCoord position;
}

struct PickupData {
  ObjectTypeId objectTypeId;
  uint16 numToPickup;
}

struct TransferData {
  ObjectTypeId objectTypeId;
  uint16 numToTransfer;
  EntityId[] toolEntityIds;
}

struct ChipOnTransferData {
  EntityId targetEntityId; // The entity whose chip is being called
  EntityId callerEntityId; // The entity initiating the transfer
  bool isDeposit; // true = caller->target, false = target->caller
  TransferData transferData;
  bytes extraData;
}

struct TransferCommonContext {
  EntityId playerEntityId;
  EntityId chestEntityId;
  VoxelCoord chestCoord;
  ObjectTypeId chestObjectTypeId;
  ObjectTypeId dstObjectTypeId;
  uint256 machineEnergyLevel;
  bool isDeposit;
}
