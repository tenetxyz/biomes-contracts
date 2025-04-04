// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Inventory } from "../codegen/tables/Inventory.sol";

import { InventoryEntity, InventoryEntityData } from "../codegen/tables/InventoryEntity.sol";
import { InventoryTypeSlots } from "../codegen/tables/InventoryTypeSlots.sol";

import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { InventorySlot, InventorySlotData } from "../codegen/tables/InventorySlot.sol";

import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";

import { ObjectAmount, ObjectTypeLib } from "../ObjectTypeLib.sol";
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

    // TODO: separate mine and hit?
    // TODO: should it use at most tool's max mass / 10?
    if (toolMassLeft >= useMassMax) {
      massUsed = useMassMax;
    } else {
      // TODO: Confirm if this is correct
      massUsed = ObjectTypeMetadata._getMass(toolType) / 10;
    }

    if (toolMassLeft <= massUsed) {
      massUsed = toolMassLeft;
      // Destroy equipped item
      destroyTool(tool);

      // Burn ores and make them available for respawn
      toolType.burnOres();

      // TODO: return energy to local pool
    } else {
      Mass._setMass(tool, toolMassLeft - massUsed);
    }
  }

  function addTool(EntityId owner, EntityId tool) internal {
    (uint16 slot, uint16 occupiedIndex) = useEmptySlot(owner);
    ObjectTypeId toolType = ObjectType._get(tool);

    // Set the slot data
    InventorySlot._set(owner, slot, tool, toolType, 1, occupiedIndex, 0);

    // Add to type slots for this tool type
    addToTypeSlots(owner, toolType, slot);

    // Set entity-to-inventory mapping
    InventoryEntity._set(tool, owner, slot);
  }

  function addObject(EntityId owner, ObjectTypeId objectType, uint16 amount) internal {
    require(amount > 0, "Amount must be greater than 0");
    uint16 stackable = ObjectTypeMetadata._getStackable(objectType);
    require(stackable > 0, "Object type cannot be added to inventory");

    uint16 remaining = amount;

    // First, find and fill existing partially filled slots for this object type
    uint256 numTypeSlots = InventoryTypeSlots._length(owner, objectType);
    for (uint256 i = 0; i < numTypeSlots && remaining > 0; i++) {
      uint16 slot = InventoryTypeSlots._getItem(owner, objectType, i);
      uint16 currentAmount = InventorySlot._getAmount(owner, slot);

      // Skip slots that are already full
      if (currentAmount >= stackable) {
        continue;
      }

      uint16 canAdd = stackable - currentAmount;
      uint16 toAdd = remaining < canAdd ? remaining : canAdd;

      // Update the slot with the new amount
      InventorySlot._setAmount(owner, slot, currentAmount + toAdd);
      remaining -= toAdd;
    }

    // If we still have objects to add, try to use empty slots
    while (remaining > 0) {
      (uint16 slot, uint16 occupiedIndex) = useEmptySlot(owner);
      uint16 toAdd = remaining < stackable ? remaining : stackable;

      // Set slot data
      InventorySlot._setObjectType(owner, slot, objectType);
      InventorySlot._setAmount(owner, slot, toAdd);

      // Add to type slots
      addToTypeSlots(owner, objectType, slot);

      remaining -= toAdd;
    }
  }

  function destroyTool(EntityId tool) private {
    removeTool(tool);
    Mass._deleteRecord(tool);
  }

  function removeTool(EntityId tool) private returns (InventoryEntityData memory) {
    InventoryEntityData memory data = InventoryEntity._get(tool);
    EntityId owner = data.owner;
    uint16 slot = data.slot;

    // Get the tool type to remove from type slots
    ObjectTypeId toolType = InventorySlot._getObjectType(owner, slot);

    // Recycle the slot (this handles removing from type slots too)
    recycleSlot(owner, slot);

    // Remove the entity mapping
    InventoryEntity._deleteRecord(tool);

    return data;
  }

  function removeObject(EntityId owner, ObjectTypeId objectType, uint16 amount) internal {
    require(amount > 0, "Amount must be greater than 0");

    uint16 remainingToRemove = amount;

    // Check if there are any slots with this object type
    uint256 numTypeSlots = InventoryTypeSlots._length(owner, objectType);
    require(numTypeSlots > 0, "No objects of this type in inventory");

    // Iterate from end to minimize array shifts
    for (uint256 i = numTypeSlots; i > 0 && remainingToRemove > 0; i--) {
      uint16 slot = InventoryTypeSlots._getItem(owner, objectType, i - 1);
      uint16 currentAmount = InventorySlot._getAmount(owner, slot);

      if (currentAmount <= remainingToRemove) {
        // Remove entire slot contents
        remainingToRemove -= currentAmount;

        // Recycle the slot
        recycleSlot(owner, slot);
      } else {
        // Remove partial amount
        uint16 newAmount = currentAmount - remainingToRemove;
        InventorySlot._setAmount(owner, slot, newAmount);
        remainingToRemove = 0;
      }
    }

    require(remainingToRemove == 0, "Not enough objects to remove");
  }

  function transfer(EntityId from, EntityId to, EntityId[] memory tools, ObjectAmount[] memory objectAmounts) internal {
    require(from != to, "Cannot transfer to self");

    // Transfer tools
    for (uint256 i = 0; i < tools.length; i++) {
      EntityId tool = tools[i];
      require(tool.exists(), "Tool does not exist");
      require(removeTool(tool).owner == from, "Tool not owned by sender");
      addTool(to, tool);
    }

    // Transfer objects
    for (uint256 i = 0; i < objectAmounts.length; i++) {
      (ObjectTypeId objectType, uint16 amount) = (objectAmounts[i].objectTypeId, objectAmounts[i].amount);
      require(amount > 0, "Amount must be greater than 0");
      removeObject(from, objectType, amount);
      addObject(to, objectType, amount);
    }
  }

  function transferAll(EntityId from, EntityId to) internal {
    require(from != to, "Cannot transfer to self");

    uint16[] memory slots = Inventory._get(from);

    // Inventory is empty
    if (slots.length == 0) return;

    // Process all slots first
    for (uint256 i = 0; i < slots.length; i++) {
      InventorySlotData memory slotData = InventorySlot._get(from, slots[i]);

      // If this is a tool
      if (slotData.entityId.exists()) {
        // No need to remove from owner as we will clean the whole inventory later
        addTool(to, slotData.entityId);
      } else {
        // Transfer regular objects
        addObject(to, slotData.objectType, slotData.amount);
      }

      InventorySlot._deleteRecord(from, slots[i]);
      InventoryTypeSlots._deleteRecord(from, slotData.objectType);
    }

    // Clean up inventory structure
    Inventory._deleteRecord(from);
  }

  // Add a slot to type slots - O(1)
  function addToTypeSlots(EntityId owner, ObjectTypeId objectType, uint16 slot) private {
    // Check if slot already exists in type slots
    uint16 typeIndex = InventorySlot._getTypeIndex(owner, slot);
    uint256 numTypeSlots = InventoryTypeSlots._length(owner, objectType);

    // If slot already has a valid index and the type matches, no need to update
    if (typeIndex < numTypeSlots) {
      uint16 existingSlot = InventoryTypeSlots._getItem(owner, objectType, typeIndex);
      if (existingSlot == slot) {
        return;
      }
    }

    // Add to type slots
    InventoryTypeSlots._push(owner, objectType, slot);
    InventorySlot._setTypeIndex(owner, slot, uint16(numTypeSlots));
  }

  // Remove a slot from type slots - O(1)
  function removeFromTypeSlots(EntityId owner, ObjectTypeId objectType, uint16 slot) private {
    uint16 typeIndex = InventorySlot._getTypeIndex(owner, slot);
    uint256 numTypeSlots = InventoryTypeSlots._length(owner, objectType);

    // Only remove if the slot is in the type slots
    if (typeIndex < numTypeSlots) {
      // If not the last element, swap with the last element
      if (typeIndex < numTypeSlots - 1) {
        uint16 lastSlot = InventoryTypeSlots._getItem(owner, objectType, numTypeSlots - 1);
        InventoryTypeSlots._update(owner, objectType, typeIndex, lastSlot);

        // Update the typeIndex for the moved slot
        InventorySlot._setTypeIndex(owner, lastSlot, typeIndex);
      }

      // Pop the last element
      InventoryTypeSlots._pop(owner, objectType);
    }

    // Clear the typeIndex - now the slot doesn't belong to any type
    InventorySlot._setTypeIndex(owner, slot, 0);
  }

  // Gets a slot to use - either reuses an empty slot or creates a new one - O(1)
  function useEmptySlot(EntityId owner) private returns (uint16, uint16) {
    // First try to find an empty slot from the Null objectType
    uint256 numEmptySlots = InventoryTypeSlots._length(owner, ObjectTypes.Null);
    uint16 occupiedIndex = uint16(Inventory._length(owner));

    if (numEmptySlots > 0) {
      // Reuse the last empty slot
      uint16 emptySlot = InventoryTypeSlots._getItem(owner, ObjectTypes.Null, numEmptySlots - 1);

      // Remove from null type slots
      removeFromTypeSlots(owner, ObjectTypes.Null, emptySlot);

      // Add to occupied slots and track its index
      Inventory._push(owner, emptySlot);
      InventorySlot._setOccupiedIndex(owner, emptySlot, occupiedIndex);

      return (emptySlot, occupiedIndex);
    }

    // No empty slots available, try to use a new slot
    uint16 maxSlots = ObjectTypeMetadata._getMaxInventorySlots(ObjectType._get(owner));
    require(occupiedIndex < maxSlots, "All slots used");

    // Add to occupied slots and track its index
    Inventory._push(owner, occupiedIndex);
    InventorySlot._setOccupiedIndex(owner, occupiedIndex, occupiedIndex);

    // Initialize typeIndex as 0 (not in any type slots yet)
    InventorySlot._setTypeIndex(owner, occupiedIndex, 0);

    return (occupiedIndex, occupiedIndex);
  }

  // Marks a slot as empty - O(1)
  function recycleSlot(EntityId owner, uint16 slot) private {
    // Get the object type before emptying the slot
    ObjectTypeId objectType = InventorySlot._getObjectType(owner, slot);

    // Remove from type-specific slots if needed
    if (objectType != ObjectTypes.Null) {
      removeFromTypeSlots(owner, objectType, slot);
    }

    // The slot should be emptied but not deleted - we'll reuse it
    InventorySlot._setObjectType(owner, slot, ObjectTypes.Null);
    InventorySlot._setAmount(owner, slot, 0);
    InventorySlot._setEntityId(owner, slot, EntityId.wrap(0));

    // Add to null object type's slots
    addToTypeSlots(owner, ObjectTypes.Null, slot);

    // Swap and pop occupied slots to remove from active inventory
    uint16 occupiedIndex = InventorySlot._getOccupiedIndex(owner, slot);
    uint256 numOccupiedSlots = Inventory._length(owner);

    // If not the last element in occupied slots, swap with the last element
    if (occupiedIndex < numOccupiedSlots - 1) {
      uint16 lastSlot = Inventory._getItem(owner, numOccupiedSlots - 1);
      Inventory._update(owner, occupiedIndex, lastSlot);
      InventorySlot._setOccupiedIndex(owner, lastSlot, occupiedIndex);
    }

    // Pop the last element from occupied slots
    Inventory._pop(owner);
  }
}
