// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

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
import { getUniqueEntity } from "../Utils.sol";

import { EntityId } from "../EntityId.sol";

using ObjectTypeLib for ObjectTypeId;

library InventoryUtils {
  function add(EntityId owner) internal { }

  function useTool(EntityId owner, EntityId tool, uint128 useMassMax)
    internal
    returns (uint128 toolMassUsed, ObjectTypeId toolType)
  {
    if (tool.exists()) {
      toolType = ObjectType._get(tool);
      require(toolType.isTool(), "Inventory item is not a tool");
      require(owner == InventoryEntity._get(tool), "Tool not owned");
      uint128 toolMassLeft = Mass._getMass(tool);
      require(toolMassLeft > 0, "Tool is already broken");

      // TODO: separate mine and hit?
      if (toolMassLeft >= useMassMax) {
        toolMassUsed = useMassMax;
      } else {
        // use 10% of the mass if it's greater than 10
        if (toolMassLeft > 10) {
          // TODO: shouldn't it be a percentage of the max mass?
          toolMassUsed = toolMassLeft / 10;
        } else {
          toolMassUsed = toolMassLeft;
        }
      }

      if (toolMassLeft <= toolMassUsed) {
        // Destroy equipped item
        removeToolFromInventory(owner, tool, toolType);

        // Burn ores and make them available for respawn
        toolType.burnOres();

        // TODO: return energy to local pool
      } else {
        Mass._setMass(tool, toolMassLeft - toolMassUsed);
      }
    }
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
  if (inputObjectTypeId.isAny()) {
    removeAnyFromInventory(caller, inputObjectTypeId, recipeData.inputAmounts[i]);
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
  InventoryEntity._set(newInventory, owner);
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
