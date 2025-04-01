// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { EnergyData } from "./codegen/tables/Energy.sol";
import { MachineData } from "./codegen/tables/Machine.sol";
import { Direction } from "./codegen/common.sol";
import { Vec3 } from "./Vec3.sol";
import { EntityId } from "./EntityId.sol";
import { ObjectTypeId } from "./ObjectTypeId.sol";
import { ObjectAmount } from "./ObjectTypeLib.sol";

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
  EntityData entityData;
}

struct EntityData {
  EntityId entityId;
  EntityId baseEntityId;
  ObjectTypeId objectTypeId;
  Vec3 position;
  Direction orientation;
  InventoryObject[] inventory;
  ResourceId programSystemId;
  uint256 mass;
  EnergyData energy;
}

struct PickupData {
  ObjectTypeId objectTypeId;
  uint16 numToPickup;
}

struct ProgramOnTransferData {
  EntityId callerEntityId; // The entity initiating the transfer
  EntityId targetEntityId; // The entity whose program is being called
  EntityId fromEntityId;
  EntityId toEntityId;
  EntityId[] toolEntityIds;
  ObjectAmount[] objectAmounts;
  bytes extraData;
}
