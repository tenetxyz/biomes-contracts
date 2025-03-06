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

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { getUniqueEntity } from "../Utils.sol";

import { EntityId } from "../EntityId.sol";

using ObjectTypeLib for ObjectTypeId;

function addToInventory(
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

function removeFromInventory(EntityId ownerEntityId, ObjectTypeId objectTypeId, uint16 numObjectsToRemove) {
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

function addToolToInventory(EntityId ownerEntityId, ObjectTypeId toolObjectTypeId) returns (EntityId) {
  require(toolObjectTypeId.isTool(), "Object type is not a tool");
  EntityId newInventoryEntityId = getUniqueEntity();
  ObjectType._set(newInventoryEntityId, toolObjectTypeId);
  InventoryEntity._set(newInventoryEntityId, ownerEntityId);
  ReverseInventoryEntity._push(ownerEntityId, EntityId.unwrap(newInventoryEntityId));
  // TODO: figure out how mass should work with multiple inputs/outputs
  // TODO: should we check that total output energy == total input energy? or should we do it at the recipe level?
  // uint128 toolMass = totalInputObjectMass + energyToMass(totalInputObjectEnergy);
  Mass._set(newInventoryEntityId, ObjectTypeMetadata._getMass(toolObjectTypeId));
  addToInventory(ownerEntityId, ObjectType._get(ownerEntityId), toolObjectTypeId, 1);
  return newInventoryEntityId;
}

function removeToolFromInventory(EntityId ownerEntityId, EntityId toolEntityId, ObjectTypeId toolObjectTypeId) {
  require(toolObjectTypeId.isTool(), "Object type is not a tool");
  require(InventoryEntity._get(toolEntityId) == ownerEntityId, "This tool is not owned by the owner");
  removeFromInventory(ownerEntityId, toolObjectTypeId, 1);
  Mass._deleteRecord(toolEntityId);
  InventoryEntity._deleteRecord(toolEntityId);
  removeEntityIdFromReverseInventoryEntity(ownerEntityId, toolEntityId);
}

function removeAnyFromInventory(EntityId playerEntityId, ObjectTypeId objectTypeId, uint16 numObjectsToRemove) {
  uint16 remaining = numObjectsToRemove;
  ObjectTypeId[] memory objectTypeIds = objectTypeId.getObjectTypes();
  for (uint256 i = 0; i < objectTypeIds.length; i++) {
    uint16 owned = InventoryCount._get(playerEntityId, objectTypeIds[i]);
    uint16 spend = owned > remaining ? remaining : owned;
    if (spend > 0) {
      removeFromInventory(playerEntityId, objectTypeIds[i], spend);
      remaining -= spend;
    }
  }
  require(remaining == 0, "Not enough objects in the inventory");
}

function useEquipped(EntityId entityId) returns (uint128 massUsed, ObjectTypeId inventoryObjectTypeId) {
  EntityId inventoryEntityId = Equipped._get(entityId);
  if (inventoryEntityId.exists()) {
    inventoryObjectTypeId = ObjectType._get(inventoryEntityId);
    require(inventoryObjectTypeId.isTool(), "Inventory item is not a tool");
    uint128 massLeft = Mass._getMass(inventoryEntityId);
    require(massLeft > 0, "Tool is already broken");

    // TODO: separate mine and hit?
    // use 10% of the mass if it's greater than 10
    massUsed = massLeft > 10 ? massLeft / 10 : massLeft;

    if (massLeft <= massUsed) {
      // Destroy equipped item
      removeToolFromInventory(entityId, inventoryEntityId, inventoryObjectTypeId);
      Equipped._deleteRecord(entityId);

      // Burn ores and make them available for respawn
      inventoryObjectTypeId.burnOres();

      // TODO: return energy to local pool
    } else {
      Mass._setMass(inventoryEntityId, massLeft - massUsed);
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
    addToInventory(toEntityId, toObjectTypeId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    removeFromInventory(fromEntityId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
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
  removeFromInventory(srcEntityId, transferObjectTypeId, numObjectsToTransfer);
  addToInventory(dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
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
  removeFromInventory(srcEntityId, inventoryObjectTypeId, 1);
  addToInventory(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
  return inventoryObjectTypeId;
}
