// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Inventory } from "../codegen/tables/Inventory.sol";

import { InventoryAvailableSlots } from "../codegen/tables/InventoryAvailableSlots.sol";
import { InventoryEntity, InventoryEntityData } from "../codegen/tables/InventoryEntity.sol";
import { InventorySlot, InventorySlotData } from "../codegen/tables/InventorySlot.sol";

import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { InventorySlots } from "../codegen/tables/InventorySlots.sol";

import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ReverseInventoryEntity } from "../codegen/tables/ReverseInventoryEntity.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";

import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { getUniqueEntity } from "../Utils.sol";

import { EntityId } from "../EntityId.sol";

using ObjectTypeLib for ObjectTypeId;

library InventoryUtils {
  function useTool(EntityId owner, EntityId tool, uint128 useMassMax)
    internal
    returns (uint128 massUsed, ObjectTypeId toolType)
  {
    if (!tool.exists()) {
      return (0, ObjectTypes.Null);
    }

    toolType = ObjectType._get(tool);
    require(toolType.isTool(), "Inventory item is not a tool");
    require(owner == InventoryEntity._getOwner(tool), "Tool not owned");
    uint128 toolMassLeft = Mass._getMass(tool);
    require(toolMassLeft > 0, "Tool is already broken");

    uint128 toolMaxMass = ObjectTypeMetadata._getMass(toolType);

    // TODO: separate mine and hit?
    if (toolMassLeft >= useMassMax) {
      massUsed = useMassMax;
    } else {
      // TODO: Confirm if this is correct
      massUsed = toolMaxMass / 10;
    }

    if (toolMassLeft <= massUsed) {
      massUsed = toolMassLeft;
      // Destroy equipped item
      removeTool(tool);

      // Burn ores and make them available for respawn
      toolType.burnOres();

      // TODO: return energy to local pool
    } else {
      Mass._setMass(tool, toolMassLeft - massUsed);
    }
  }

  function addTool(EntityId owner, EntityId tool) internal {
    (uint16 slot, uint16 occupiedIndex) = useEmptySlot(owner);
    InventorySlot._set(owner, slot, tool, ObjectTypes.Null, 0, occupiedIndex, 0);
    InventoryEntity._set(tool, owner, slot);
  }

  function addObject(EntityId owner, ObjectTypeId objectType, uint16 amount) internal {
    require(amount > 0, "Amount must be greater than 0");
    uint16 stackable = ObjectTypeMetadata._getStackable(objectType);
    require(stackable > 0, "Object type cannot be added to inventory");

    uint16 remaining = amount;

    // First, fill existing available slots for this object type
    uint256 numAvailable = InventoryAvailableSlots._length(owner, objectType);
    for (uint256 i = 0; i < numAvailable && remaining > 0; i++) {
      // Get the last available slot
      uint16 availableIndex = uint16(numAvailable - 1 - i);
      uint16 slot = InventoryAvailableSlots._getItem(owner, objectType, availableIndex);
      uint16 currentAmount = InventorySlot._getAmount(owner, slot);

      uint16 canAdd = stackable - currentAmount;
      uint16 toAdd = remaining < canAdd ? remaining : canAdd;

      // Update the slot with the new amount
      currentAmount += toAdd;
      InventorySlot._setAmount(owner, slot, currentAmount);
      remaining -= toAdd;

      // If the slot is now full, remove it from available slots
      if (currentAmount == stackable) {
        // If not the last item in available slots, swap with the last one
        if (availableIndex != numAvailable - 1) {
          uint16 lastSlot = InventoryAvailableSlots._getItem(owner, objectType, numAvailable - 1);
          InventoryAvailableSlots._update(owner, objectType, availableIndex, lastSlot);

          // Update the availableIndex for the moved slot
          InventorySlot._setAvailableIndex(owner, lastSlot, availableIndex);
        }

        // Pop the last element
        InventoryAvailableSlots._pop(owner, objectType);

        // Reset the loop counter as we've modified the array
        i--;
        numAvailable--;
      }
    }

    // If we still have objects to add, create new slots
    while (remaining > 0) {
      (uint16 slot, uint16 occupiedIndex) = useEmptySlot(owner);
      uint16 toAdd = remaining < stackable ? remaining : stackable;

      uint16 availableIndex;

      // If the slot isn't full, add it to available slots
      if (toAdd < stackable) {
        availableIndex = uint16(InventoryAvailableSlots._length(owner, objectType));
        InventoryAvailableSlots._push(owner, objectType, slot);
      }

      // Set all slot data
      InventorySlot._set(owner, slot, EntityId.wrap(0), objectType, toAdd, occupiedIndex, availableIndex);
      remaining -= toAdd;
    }
  }

  function removeTool(EntityId tool) private {
    InventoryEntityData memory data = InventoryEntity._get(tool);
    // Clear the slot but keep it in the same position
    InventorySlot._setEntityId(data.owner, data.slot, EntityId.wrap(0));
    InventorySlot._setAmount(data.owner, data.slot, 0);
    recycleSlot(data.owner, data.slot);
    Mass._deleteRecord(tool);
    InventoryEntity._deleteRecord(tool);
  }

  function removeObject(EntityId owner, ObjectTypeId objectType, uint16 amount) internal {
    require(amount > 0, "Amount must be greater than 0");

    uint16 stackable = ObjectTypeMetadata._getStackable(objectType);
    uint16 remainingToRemove = amount;

    // Iterate through occupied slots
    uint256 numOccupiedSlots = Inventory._lengthOccupiedSlots(owner);

    // Start from the end of occupied slots to minimize array shifts
    for (uint256 i = numOccupiedSlots - 1; i >= 0 && remainingToRemove > 0; i--) {
      uint16 slot = Inventory._getItemOccupiedSlots(owner, i);
      InventorySlotData memory slotData = InventorySlot._get(owner, slot);

      if (slotData.objectType != objectType) {
        continue;
      }

      if (slotData.amount <= remainingToRemove) {
        remainingToRemove -= slotData.amount;

        InventorySlot._deleteRecord(owner, slot);

        // Remove from available slots for that object type
        removeFromAvailableSlots(owner, objectType, slot);

        // Recycle the slot (marks as empty and updates occupied slots array)
        recycleSlot(owner, slot);

        // Update the counter as we removed an item
        numOccupiedSlots--;
      } else {
        // Remove partial amount
        uint16 newAmount = slotData.amount - remainingToRemove;
        InventorySlot._setAmount(owner, slot, newAmount);
        remainingToRemove = 0;

        // Add to available slots for this object type if not already there
        if (slotData.amount == stackable) {
          addToAvailableSlots(owner, objectType, slot);
        }
      }
    }
  }

  // Add a slot to AvailableSlots - O(1)
  function addToAvailableSlots(EntityId owner, ObjectTypeId objectType, uint16 slot) private {
    // Check if already in available slots by looking at availableIndex
    uint16 availableIndex = InventorySlot._getAvailableIndex(owner, slot);

    // Add to available slots
    uint256 newIndex = InventoryAvailableSlots._length(owner, objectType);
    InventoryAvailableSlots._push(owner, objectType, slot);

    // Update the slot's availableIndex
    InventorySlot._setAvailableIndex(owner, slot, uint16(newIndex));
  }

  // Remove a slot from AvailableSlots - O(1)
  function removeFromAvailableSlots(EntityId owner, ObjectTypeId objectType, uint16 slot) private {
    // Get the index in available slots
    uint16 availableIndex = InventorySlot._getAvailableIndex(owner, slot);

    // If it's in the available slots
    uint256 length = InventoryAvailableSlots._length(owner, objectType);

    // If not the last element, swap with the last element
    if (availableIndex < length - 1) {
      uint16 lastSlot = InventoryAvailableSlots._getItem(owner, objectType, length - 1);
      InventoryAvailableSlots._update(owner, objectType, availableIndex, lastSlot);

      // Update the swapped slot's availableIndex
      InventorySlot._setAvailableIndex(owner, lastSlot, availableIndex);
    }

    // Pop the last element
    InventoryAvailableSlots._pop(owner, objectType);
  }

  // Gets a slot to use - either reuses an empty slot or creates a new one
  function useEmptySlot(EntityId owner) private returns (uint16, uint16) {
    // First try to find an empty slot from the Null objectType available slots
    uint256 numEmptySlots = InventoryAvailableSlots._length(owner, ObjectTypes.Null);
    uint16 occupiedIndex = uint16(Inventory._lengthOccupiedSlots(owner));
    if (numEmptySlots > 0) {
      // Reuse the last empty slot
      uint16 availableIndex = uint16(numEmptySlots - 1);
      uint16 emptySlot = InventoryAvailableSlots._getItem(owner, ObjectTypes.Null, availableIndex);

      // Remove from Null available slots
      InventoryAvailableSlots._pop(owner, ObjectTypes.Null);

      // Add to occupied slots and track its index
      Inventory._pushOccupiedSlots(owner, emptySlot);

      // Set occupiedIndex in the slot data
      InventorySlot._setOccupiedIndex(owner, emptySlot, uint16(occupiedIndex));

      return (emptySlot, occupiedIndex);
    }

    // No empty slots available, create a new slot
    uint16 slotsUsed = Inventory._getSlotsUsed(owner);
    uint16 maxSlots = ObjectTypeMetadata._getMaxInventorySlots(ObjectType._get(owner));
    require(slotsUsed < maxSlots, "All slots used");

    // Add to occupied slots and track its index
    Inventory._pushOccupiedSlots(owner, slotsUsed);

    InventorySlot._setOccupiedIndex(owner, slotsUsed, uint16(occupiedIndex));

    // Increment slots used
    Inventory._setSlotsUsed(owner, ++slotsUsed);
    return (slotsUsed - 1, occupiedIndex);
  }

  // Marks a slot as empty but doesn't shift other slots - O(1)
  function recycleSlot(EntityId owner, uint16 slot) private {
    require(slot < Inventory._getSlotsUsed(owner), "Invalid slot");
    uint16 amount = InventorySlot._getAmount(owner, slot);
    require(amount == 0, "Slot not empty");

    // Mark slot as empty by setting objectType to Null
    InventorySlot._setObjectType(owner, slot, ObjectTypes.Null);

    // Add to available null slots
    InventoryAvailableSlots._push(owner, ObjectTypes.Null, slot);

    uint16 occupiedIndex = InventorySlot._getOccupiedIndex(owner, slot);
    uint256 numOccupiedSlots = Inventory._lengthOccupiedSlots(owner);

    // If not the last element, replace with the last element
    if (occupiedIndex < numOccupiedSlots - 1) {
      uint16 lastSlot = Inventory._getItemOccupiedSlots(owner, numOccupiedSlots - 1);
      Inventory._updateOccupiedSlots(owner, occupiedIndex, lastSlot);

      // Update the index for the moved slot
      InventorySlot._setOccupiedIndex(owner, lastSlot, occupiedIndex);
    }

    // Pop the last element
    Inventory._popOccupiedSlots(owner);
  }
}

function addToInventory(
  EntityId owner,
  ObjectTypeId ownerObjectTypeId,
  ObjectTypeId objectTypeId,
  uint16 numObjectsToAdd
) {
  require(owner.exists(), "Owner entity does not exist");
  uint16 stackable = ObjectTypeMetadata._getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be added to the inventory");

  uint16 numInitialObjects = InventoryCount._get(owner, objectTypeId);
  uint16 numInitialFullStacks = numInitialObjects / stackable;
  bool hasInitialPartialStack = numInitialObjects % stackable != 0;
  uint16 numFinalObjects = numInitialObjects + numObjectsToAdd;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numInitialSlotsUsed = InventorySlots._get(owner);
  uint16 numFinalSlotsUsedDelta =
    (numFinalFullStacks + (hasFinalPartialStack ? 1 : 0)) - (numInitialFullStacks + (hasInitialPartialStack ? 1 : 0));
  uint16 numFinalSlotsUsed = numInitialSlotsUsed + numFinalSlotsUsedDelta;
  require(numFinalSlotsUsed <= ObjectTypeMetadata._getMaxInventorySlots(ownerObjectTypeId), "Inventory is full");
  InventorySlots._set(owner, numFinalSlotsUsed);
  InventoryCount._set(owner, objectTypeId, numFinalObjects);

  if (numInitialObjects == 0) {
    InventoryObjects._push(owner, objectTypeId.unwrap());
  }
}

function removeFromInventory(EntityId owner, ObjectTypeId objectTypeId, uint16 numObjectsToRemove) {
  if (objectTypeId.isAny()) {
    removeAnyFromInventory(owner, objectTypeId, numObjectsToRemove);
    return;
  }
  uint16 numInitialObjects = InventoryCount._get(owner, objectTypeId);
  require(numInitialObjects >= numObjectsToRemove, "Not enough objects in the inventory");

  uint16 stackable = ObjectTypeMetadata._getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be removed from the inventory");

  uint16 numInitialFullStacks = numInitialObjects / stackable;
  bool hasInitialPartialStack = numInitialObjects % stackable != 0;

  uint16 numFinalObjects = numInitialObjects - numObjectsToRemove;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numInitialSlotsUsed = InventorySlots._get(owner);
  uint16 numFinalSlotsUsedDelta =
    (numInitialFullStacks + (hasInitialPartialStack ? 1 : 0)) - (numFinalFullStacks + (hasFinalPartialStack ? 1 : 0));
  uint16 numFinalSlotsUsed = numInitialSlotsUsed - numFinalSlotsUsedDelta;
  if (numFinalSlotsUsed == 0) {
    InventorySlots._deleteRecord(owner);
  } else {
    InventorySlots._set(owner, numFinalSlotsUsed);
  }

  if (numFinalObjects == 0) {
    InventoryCount._deleteRecord(owner, objectTypeId);
    removeObjectTypeIdFromInventoryObjects(owner, objectTypeId);
  } else {
    InventoryCount._set(owner, objectTypeId, numFinalObjects);
  }
}

function addToolToInventory(EntityId owner, ObjectTypeId toolObjectTypeId) returns (EntityId) {
  require(toolObjectTypeId.isTool(), "Object type is not a tool");
  EntityId newInventory = getUniqueEntity();
  ObjectType._set(newInventory, toolObjectTypeId);
  // InventoryEntity._set(newInventory, owner);
  ReverseInventoryEntity._push(owner, EntityId.unwrap(newInventory));
  // TODO: figure out how mass should work with multiple inputs/outputs
  // TODO: should we check that total output energy == total input energy? or should we do it at the recipe level?
  // uint128 toolMass = totalInputObjectMass + energyToMass(totalInputObjectEnergy);
  Mass._set(newInventory, ObjectTypeMetadata._getMass(toolObjectTypeId));
  addToInventory(owner, ObjectType._get(owner), toolObjectTypeId, 1);
  return newInventory;
}

function removeToolFromInventory(EntityId owner, EntityId tool, ObjectTypeId toolObjectTypeId) {
  require(toolObjectTypeId.isTool(), "Object type is not a tool");
  require(InventoryEntity._getOwner(tool) == owner, "This tool is not owned by the owner");
  removeFromInventory(owner, toolObjectTypeId, 1);
  Mass._deleteRecord(tool);
  InventoryEntity._deleteRecord(tool);
  removeFromReverseInventoryEntity(owner, tool);
}

function removeAnyFromInventory(EntityId player, ObjectTypeId objectTypeId, uint16 numObjectsToRemove) {
  uint16 remaining = numObjectsToRemove;
  ObjectTypeId[] memory objectTypeIds = objectTypeId.getObjectTypes();
  for (uint256 i = 0; i < objectTypeIds.length; i++) {
    uint16 owned = InventoryCount._get(player, objectTypeIds[i]);
    uint16 spend = owned > remaining ? remaining : owned;
    if (spend > 0) {
      removeFromInventory(player, objectTypeIds[i], spend);
      remaining -= spend;
    }
  }
  require(remaining == 0, "Not enough objects in the inventory");
}

function removeFromReverseInventoryEntity(EntityId owner, EntityId removeInventory) {
  bytes32[] memory inventories = ReverseInventoryEntity._get(owner);
  bytes32[] memory newInventories = new bytes32[](inventories.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventories.length; i++) {
    if (inventories[i] != EntityId.unwrap(removeInventory)) {
      newInventories[j] = inventories[i];
      j++;
    }
  }
  if (newInventories.length == 0) {
    ReverseInventoryEntity._deleteRecord(owner);
  } else {
    ReverseInventoryEntity._set(owner, newInventories);
  }
}

function removeObjectTypeIdFromInventoryObjects(EntityId owner, ObjectTypeId removeObjectTypeId) {
  uint16[] memory currentObjectTypeIds = InventoryObjects._get(owner);
  uint16[] memory newObjectTypeIds = new uint16[](currentObjectTypeIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < currentObjectTypeIds.length; i++) {
    if (currentObjectTypeIds[i] != removeObjectTypeId.unwrap()) {
      newObjectTypeIds[j] = currentObjectTypeIds[i];
      j++;
    }
  }
  if (newObjectTypeIds.length == 0) {
    InventoryObjects._deleteRecord(owner);
  } else {
    InventoryObjects._set(owner, newObjectTypeIds);
  }
}

function transferAllInventoryEntities(EntityId from, EntityId to, ObjectTypeId toObjectTypeId) returns (uint256) {
  uint256 numTransferred = 0;
  uint16[] memory fromObjectTypeIds = InventoryObjects._get(from);
  for (uint256 i = 0; i < fromObjectTypeIds.length; i++) {
    uint16 objectTypeCount = InventoryCount._get(from, ObjectTypeId.wrap(fromObjectTypeIds[i]));
    addToInventory(to, toObjectTypeId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    removeFromInventory(from, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    numTransferred += objectTypeCount;
  }

  bytes32[] memory fromInventories = ReverseInventoryEntity._get(from);
  for (uint256 i = 0; i < fromInventories.length; i++) {
    InventoryEntity._set(EntityId.wrap(fromInventories[i]), to);
    ReverseInventoryEntity._push(to, fromInventories[i]);
  }
  if (fromInventories.length > 0) {
    ReverseInventoryEntity._deleteRecord(from);
  }

  return numTransferred;
}

function transferInventoryNonEntity(
  EntityId src,
  EntityId dst,
  ObjectTypeId dstObjectTypeId,
  ObjectTypeId transferObjectTypeId,
  uint16 numObjectsToTransfer
) {
  require(transferObjectTypeId.isBlock() || transferObjectTypeId.isItem(), "Object type is not a block or item");
  require(numObjectsToTransfer > 0, "Amount must be greater than 0");
  removeFromInventory(src, transferObjectTypeId, numObjectsToTransfer);
  addToInventory(dst, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
}

function transferInventoryEntity(EntityId src, EntityId dst, ObjectTypeId dstObjectTypeId, EntityId inventory)
  returns (ObjectTypeId)
{
  require(InventoryEntity._get(inventory) == src, "Entity does not own inventory item");
  InventoryEntity._set(inventory, dst);
  ReverseInventoryEntity._push(dst, EntityId.unwrap(inventory));
  removeFromReverseInventoryEntity(src, inventory);

  ObjectTypeId inventoryObjectTypeId = ObjectType._get(inventory);
  removeFromInventory(src, inventoryObjectTypeId, 1);
  addToInventory(dst, dstObjectTypeId, inventoryObjectTypeId, 1);
  return inventoryObjectTypeId;
}
