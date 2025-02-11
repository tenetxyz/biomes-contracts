// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { CommitmentData } from "./codegen/tables/Commitment.sol";
import { EnergyData } from "./codegen/tables/Energy.sol";
import { EntityId } from "./EntityId.sol";

struct VoxelCoord {
  int32 x;
  int32 y;
  int32 z;
}

// Define an enum representing all possible 3D movements in a Moore neighborhood
enum VoxelCoordDirection {
  PositiveX, // +1 in the x direction
  NegativeX, // -1 in the x direction
  PositiveY, // +1 in the y direction
  NegativeY, // -1 in the y direction
  PositiveZ, // +1 in the z direction
  NegativeZ, // -1 in the z direction
  PositiveXPositiveY, // +1 in x and +1 in y
  PositiveXNegativeY, // +1 in x and -1 in y
  PositiveXPositiveZ, // +1 in x and +1 in z
  PositiveXNegativeZ, // +1 in x and -1 in z
  NegativeXPositiveY, // -1 in x and +1 in y
  NegativeXNegativeY, // -1 in x and -1 in y
  NegativeXPositiveZ, // -1 in x and +1 in z
  NegativeXNegativeZ, // -1 in x and -1 in z
  PositiveYPositiveZ, // +1 in y and +1 in z
  PositiveYNegativeZ, // +1 in y and -1 in z
  NegativeYPositiveZ, // -1 in y and +1 in z
  NegativeYNegativeZ, // -1 in y and -1 in z
  PositiveXPositiveYPositiveZ, // +1 in x, +1 in y, +1 in z
  PositiveXPositiveYNegativeZ, // +1 in x, +1 in y, -1 in z
  PositiveXNegativeYPositiveZ, // +1 in x, -1 in y, +1 in z
  PositiveXNegativeYNegativeZ, // +1 in x, -1 in y, -1 in z
  NegativeXPositiveYPositiveZ, // -1 in x, +1 in y, +1 in z
  NegativeXPositiveYNegativeZ, // -1 in x, +1 in y, -1 in z
  NegativeXNegativeYPositiveZ, // -1 in x, -1 in y, +1 in z
  NegativeXNegativeYNegativeZ // -1 in x, -1 in y, -1 in z
}

// Define an enum representing all possible 3D movements in a Von Neumann neighborhood
enum VoxelCoordDirectionVonNeumann {
  PositiveX,
  NegativeX,
  PositiveY,
  NegativeY,
  PositiveZ,
  NegativeZ
}

struct InventoryTool {
  EntityId entityId;
  uint256 numUsesLeft;
}

struct InventoryObject {
  uint16 objectTypeId;
  uint16 numObjects;
  InventoryTool[] tools;
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
