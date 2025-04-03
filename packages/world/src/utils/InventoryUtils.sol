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
  function add(EntityId owner) internal { }

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
    uint16 slot = addSlot(owner);
    InventorySlot._setEntityId(owner, slot, tool);
    InventoryEntity._set(tool, owner, slot);
  }

  function addObject(EntityId owner, ObjectTypeId objectType, uint16 amount) internal {
    uint16 stackable = ObjectTypeMetadata._getStackable(objectType);
    require(stackable > 0, "Object type cannot be added to inventory");
    uint16[] memory available = InventoryAvailableSlots._get(owner, objectType);
    uint16 slot;
    if (available.length == 0) {
      slot = addSlot(owner);
    } else {
      slot = available[available.length - 1];
    }
  }

  function removeTool(EntityId tool) private {
    InventoryEntityData memory data = InventoryEntity._get(tool);
    removeSlot(data.owner, data.slot);
    Mass._deleteRecord(tool);
    InventoryEntity._deleteRecord(tool);
  }

  function addSlot(EntityId owner) private returns (uint16) {
    uint16 slotsUsed = Inventory._getSlotsUsed(owner);
    uint16 maxSlots = ObjectTypeMetadata._getMaxInventorySlots(ObjectType._get(owner));
    require(slotsUsed < maxSlots, "All slots used");
    Inventory._setSlotsUsed(owner, ++slotsUsed);
    return slotsUsed;
  }

  function removeSlot(EntityId owner, uint16 slot) private {
    uint16 slotsUsed = Inventory._getSlotsUsed(owner);
    require(slot < slotsUsed, "Invalid slot");
    if (slot != slotsUsed - 1) {
      InventorySlotData memory lastSlotData = InventorySlot._get(owner, slotsUsed - 1);
      InventorySlot._set(owner, slot, lastSlotData);
    }
    Inventory._setSlotsUsed(owner, slotsUsed - 1);
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
  require(InventoryEntity._get(tool) == owner, "This tool is not owned by the owner");
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
