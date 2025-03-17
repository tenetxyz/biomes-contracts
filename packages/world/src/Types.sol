// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { EnergyData } from "./codegen/tables/Energy.sol";
import { Direction } from "./codegen/common.sol";
import { Vec3 } from "./Vec3.sol";
import { EntityId } from "./EntityId.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";

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
  EntityId bedEntityId;
  EntityId equippedEntityId;
  uint256 lastActionTime;
  EntityData entityData;
}

struct EntityData {
  EntityId entityId;
  EntityId baseEntityId;
  ObjectTypeId objectTypeId;
  Vec3 position;
  Direction orientation;
  InventoryObject[] inventory;
  ResourceId chipSystemId;
  uint256 mass;
  EnergyData energy;
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
  Vec3 chestCoord;
  ObjectTypeId chestObjectTypeId;
  ObjectTypeId dstObjectTypeId;
  uint256 machineEnergyLevel;
  bool isDeposit;
}
