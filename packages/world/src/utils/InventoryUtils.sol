// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../codegen/tables/ReverseInventoryEntity.sol";
import { InventorySlots } from "../codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { ObjectTypeId, PlayerObjectID, ChestObjectID, SmartChestObjectID } from "../ObjectTypeIds.sol";

import { EntityId } from "../EntityId.sol";

function addToInventoryCount(
  EntityId ownerEntityId,
  ObjectTypeId ownerObjectTypeId,
  ObjectTypeId objectTypeId,
  uint16 numObjectsToAdd
) {
  uint16 stackable = ObjectTypeMetadata._getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be added to the inventory");

  uint16 numInitialObjects = InventoryCount._get(ownerEntityId, objectTypeId);
  uint16 numInitialFullStacks = numInitialObjects / stackable;
  bool hasInitialPartialStack = numInitialObjects % stackable != 0;
  uint16 numFinalObjects = numInitialObjects + numObjectsToAdd;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numInitialSlotsUsed = InventorySlots._get(ownerEntityId);
  uint16 numFinalSlotsUsedDelta = (numFinalFullStacks + (hasFinalPartialStack ? 1 : 0)) -
    (numInitialFullStacks + (hasInitialPartialStack ? 1 : 0));
  uint16 numFinalSlotsUsed = numInitialSlotsUsed + numFinalSlotsUsedDelta;
  require(numFinalSlotsUsed <= ObjectTypeMetadata._getMaxInventorySlots(ownerObjectTypeId), "Inventory is full");
  InventorySlots._set(ownerEntityId, numFinalSlotsUsed);
  InventoryCount._set(ownerEntityId, objectTypeId, numFinalObjects);

  if (numInitialObjects == 0) {
    InventoryObjects._push(ownerEntityId, objectTypeId.unwrap());
  }
}

function removeFromInventoryCount(EntityId ownerEntityId, ObjectTypeId objectTypeId, uint16 numObjectsToRemove) {
  uint16 numInitialObjects = InventoryCount._get(ownerEntityId, objectTypeId);
  require(numInitialObjects >= numObjectsToRemove, "Not enough objects in the inventory");

  uint16 stackable = ObjectTypeMetadata._getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be removed from the inventory");

  uint16 numInitialFullStacks = numInitialObjects / stackable;
  bool hasInitialPartialStack = numInitialObjects % stackable != 0;

  uint16 numFinalObjects = numInitialObjects - numObjectsToRemove;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numInitialSlotsUsed = InventorySlots._get(ownerEntityId);
  uint16 numFinalSlotsUsedDelta = (numInitialFullStacks + (hasInitialPartialStack ? 1 : 0)) -
    (numFinalFullStacks + (hasFinalPartialStack ? 1 : 0));
  uint16 numFinalSlotsUsed = numInitialSlotsUsed - numFinalSlotsUsedDelta;
  if (numFinalSlotsUsed == 0) {
    InventorySlots._deleteRecord(ownerEntityId);
  } else {
    InventorySlots._set(ownerEntityId, numFinalSlotsUsed);
  }

  if (numFinalObjects == 0) {
    InventoryCount._deleteRecord(ownerEntityId, objectTypeId);
    removeObjectTypeIdFromInventoryObjects(ownerEntityId, objectTypeId);
  } else {
    InventoryCount._set(ownerEntityId, objectTypeId, numFinalObjects);
  }
}

function useEquipped(
  EntityId entityId,
  EntityId inventoryEntityId,
  ObjectTypeId inventoryObjectTypeId,
  uint24 durabilityDecrease
) {
  if (inventoryEntityId.exists()) {
    // TOOD: fix
    uint128 durabilityLeft = Mass._getMass(inventoryEntityId);
    // Allow mining even if durability is exactly or less than required, then break the tool
    require(durabilityLeft > 0, "Tool is already broken");

    if (durabilityLeft <= durabilityDecrease) {
      // Tool will break after this use, but allow mining
      // Destroy equipped item
      removeFromInventoryCount(entityId, inventoryObjectTypeId, 1);
      Mass._deleteRecord(inventoryEntityId);
      InventoryEntity._deleteRecord(inventoryEntityId);
      removeEntityIdFromReverseInventoryEntity(entityId, inventoryEntityId);
      Equipped._deleteRecord(entityId);
    } else {
      Mass._setMass(inventoryEntityId, durabilityLeft - durabilityDecrease);
    }
  }
}

function removeEntityIdFromReverseInventoryEntity(EntityId ownerEntityId, EntityId removeInventoryEntityId) {
  bytes32[] memory inventoryEntityIds = ReverseInventoryEntity._get(ownerEntityId);
  bytes32[] memory newInventoryEntityIds = new bytes32[](inventoryEntityIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] != EntityId.unwrap(removeInventoryEntityId)) {
      newInventoryEntityIds[j] = inventoryEntityIds[i];
      j++;
    }
  }
  if (newInventoryEntityIds.length == 0) {
    ReverseInventoryEntity._deleteRecord(ownerEntityId);
  } else {
    ReverseInventoryEntity._set(ownerEntityId, newInventoryEntityIds);
  }
}

function removeObjectTypeIdFromInventoryObjects(EntityId ownerEntityId, ObjectTypeId removeObjectTypeId) {
  uint16[] memory currentObjectTypeIds = InventoryObjects._get(ownerEntityId);
  uint16[] memory newObjectTypeIds = new uint16[](currentObjectTypeIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < currentObjectTypeIds.length; i++) {
    if (currentObjectTypeIds[i] != removeObjectTypeId.unwrap()) {
      newObjectTypeIds[j] = currentObjectTypeIds[i];
      j++;
    }
  }
  if (newObjectTypeIds.length == 0) {
    InventoryObjects._deleteRecord(ownerEntityId);
  } else {
    InventoryObjects._set(ownerEntityId, newObjectTypeIds);
  }
}

function transferAllInventoryEntities(
  EntityId fromEntityId,
  EntityId toEntityId,
  ObjectTypeId toObjectTypeId
) returns (uint256) {
  uint256 numTransferred = 0;
  uint16[] memory fromObjectTypeIds = InventoryObjects._get(fromEntityId);
  for (uint256 i = 0; i < fromObjectTypeIds.length; i++) {
    uint16 objectTypeCount = InventoryCount._get(fromEntityId, ObjectTypeId.wrap(fromObjectTypeIds[i]));
    addToInventoryCount(toEntityId, toObjectTypeId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    removeFromInventoryCount(fromEntityId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    numTransferred += objectTypeCount;
  }

  bytes32[] memory fromInventoryEntityIds = ReverseInventoryEntity._get(fromEntityId);
  for (uint256 i = 0; i < fromInventoryEntityIds.length; i++) {
    InventoryEntity._set(EntityId.wrap(fromInventoryEntityIds[i]), toEntityId);
    ReverseInventoryEntity._push(toEntityId, fromInventoryEntityIds[i]);
  }
  if (fromInventoryEntityIds.length > 0) {
    ReverseInventoryEntity._deleteRecord(fromEntityId);
  }

  return numTransferred;
}

function transferInventoryNonEntity(
  EntityId srcEntityId,
  EntityId dstEntityId,
  ObjectTypeId dstObjectTypeId,
  ObjectTypeId transferObjectTypeId,
  uint16 numObjectsToTransfer
) {
  require(transferObjectTypeId.isBlock() || transferObjectTypeId.isItem(), "Object type is not a block or item");
  require(numObjectsToTransfer > 0, "Amount must be greater than 0");
  removeFromInventoryCount(srcEntityId, transferObjectTypeId, numObjectsToTransfer);
  addToInventoryCount(dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
}

function transferInventoryEntity(
  EntityId srcEntityId,
  EntityId dstEntityId,
  ObjectTypeId dstObjectTypeId,
  EntityId inventoryEntityId
) returns (ObjectTypeId) {
  require(InventoryEntity._get(inventoryEntityId) == srcEntityId, "Entity does not own inventory item");
  if (Equipped._get(srcEntityId) == inventoryEntityId) {
    Equipped._deleteRecord(srcEntityId);
  }
  InventoryEntity._set(inventoryEntityId, dstEntityId);
  ReverseInventoryEntity._push(dstEntityId, EntityId.unwrap(inventoryEntityId));
  removeEntityIdFromReverseInventoryEntity(srcEntityId, inventoryEntityId);

  ObjectTypeId inventoryObjectTypeId = ObjectType._get(inventoryEntityId);
  removeFromInventoryCount(srcEntityId, inventoryObjectTypeId, 1);
  addToInventoryCount(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
  return inventoryObjectTypeId;
}
