// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { InventoryTool } from "../codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS } from "../Constants.sol";
import { PlayerObjectID, ChestObjectID, SmartChestObjectID } from "../ObjectTypeIds.sol";

function addToInventoryCount(
  bytes32 ownerEntityId,
  uint8 ownerObjectTypeId,
  uint16 objectTypeId,
  uint16 numObjectsToAdd
) {
  uint8 stackable = ObjectTypeMetadata._getStackable(objectTypeId);
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
  if (ownerObjectTypeId == PlayerObjectID) {
    require(numFinalSlotsUsed <= MAX_PLAYER_INVENTORY_SLOTS, "Inventory is full");
  } else if (ownerObjectTypeId == ChestObjectID || ownerObjectTypeId == SmartChestObjectID) {
    require(numFinalSlotsUsed <= MAX_CHEST_INVENTORY_SLOTS, "Inventory is full");
  }
  InventorySlots._set(ownerEntityId, numFinalSlotsUsed);
  InventoryCount._set(ownerEntityId, objectTypeId, numFinalObjects);

  if (numInitialObjects == 0) {
    InventoryObjects._push(ownerEntityId, objectTypeId);
  }
}

function removeFromInventoryCount(bytes32 ownerEntityId, uint16 objectTypeId, uint16 numObjectsToRemove) {
  uint16 numInitialObjects = InventoryCount._get(ownerEntityId, objectTypeId);
  require(numInitialObjects >= numObjectsToRemove, "Not enough objects in the inventory");

  uint8 stackable = ObjectTypeMetadata._getStackable(objectTypeId);
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
  bytes32 entityId,
  bytes32 inventoryEntityId,
  uint8 inventoryObjectTypeId,
  uint24 durabilityDecrease
) {
  if (inventoryEntityId != bytes32(0)) {
    uint24 durabilityLeft = ItemMetadata._get(inventoryEntityId);
    // Allow mining even if durability is exactly or less than required, then break the tool
    require(durabilityLeft > 0, "Tool is already broken");

    if (durabilityLeft <= durabilityDecrease) {
      // Tool will break after this use, but allow mining
      // Destroy equipped item
      removeFromInventoryCount(entityId, inventoryObjectTypeId, 1);
      ItemMetadata._deleteRecord(inventoryEntityId);
      InventoryTool._deleteRecord(inventoryEntityId);
      removeEntityIdFromReverseInventoryTool(entityId, inventoryEntityId);
      Equipped._deleteRecord(entityId);
    } else {
      ItemMetadata._set(inventoryEntityId, durabilityLeft - durabilityDecrease);
    }
  }
}

function removeEntityIdFromReverseInventoryTool(bytes32 ownerEntityId, bytes32 removeInventoryEntityId) {
  bytes32[] memory inventoryEntityIds = ReverseInventoryTool._get(ownerEntityId);
  bytes32[] memory newInventoryEntityIds = new bytes32[](inventoryEntityIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] != removeInventoryEntityId) {
      newInventoryEntityIds[j] = inventoryEntityIds[i];
      j++;
    }
  }
  if (newInventoryEntityIds.length == 0) {
    ReverseInventoryTool._deleteRecord(ownerEntityId);
  } else {
    ReverseInventoryTool._set(ownerEntityId, newInventoryEntityIds);
  }
}

function removeObjectTypeIdFromInventoryObjects(bytes32 ownerEntityId, uint8 removeObjectTypeId) {
  uint8[] memory currentObjectTypeIds = InventoryObjects._get(ownerEntityId);
  uint8[] memory newObjectTypeIds = new uint8[](currentObjectTypeIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < currentObjectTypeIds.length; i++) {
    if (currentObjectTypeIds[i] != removeObjectTypeId) {
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
  bytes32 fromEntityId,
  bytes32 toEntityId,
  uint8 toObjectTypeId
) returns (uint256) {
  uint256 numTransferred = 0;
  uint8[] memory fromObjectTypeIds = InventoryObjects._get(fromEntityId);
  for (uint256 i = 0; i < fromObjectTypeIds.length; i++) {
    uint16 objectTypeCount = InventoryCount._get(fromEntityId, fromObjectTypeIds[i]);
    addToInventoryCount(toEntityId, toObjectTypeId, fromObjectTypeIds[i], objectTypeCount);
    removeFromInventoryCount(fromEntityId, fromObjectTypeIds[i], objectTypeCount);
    numTransferred += objectTypeCount;
  }

  bytes32[] memory fromInventoryEntityIds = ReverseInventoryTool._get(fromEntityId);
  for (uint256 i = 0; i < fromInventoryEntityIds.length; i++) {
    InventoryTool._set(fromInventoryEntityIds[i], toEntityId);
    ReverseInventoryTool._push(toEntityId, fromInventoryEntityIds[i]);
  }
  if (fromInventoryEntityIds.length > 0) {
    ReverseInventoryTool._deleteRecord(fromEntityId);
  }

  return numTransferred;
}

function transferInventoryNonTool(
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  uint8 dstObjectTypeId,
  uint8 transferObjectTypeId,
  uint16 numObjectsToTransfer
) {
  require(!ObjectTypeMetadata._getIsTool(transferObjectTypeId), "Object type is not a block");
  require(numObjectsToTransfer > 0, "Amount must be greater than 0");
  removeFromInventoryCount(srcEntityId, transferObjectTypeId, numObjectsToTransfer);
  addToInventoryCount(dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
}

function transferInventoryTool(
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  uint8 dstObjectTypeId,
  bytes32 toolEntityId
) returns (uint8) {
  require(InventoryTool._get(toolEntityId) == srcEntityId, "Entity does not own inventory item");
  if (Equipped._get(srcEntityId) == toolEntityId) {
    Equipped._deleteRecord(srcEntityId);
  }
  InventoryTool._set(toolEntityId, dstEntityId);
  ReverseInventoryTool._push(dstEntityId, toolEntityId);
  removeEntityIdFromReverseInventoryTool(srcEntityId, toolEntityId);

  uint8 inventoryObjectTypeId = ObjectType._get(toolEntityId);
  removeFromInventoryCount(srcEntityId, inventoryObjectTypeId, 1);
  addToInventoryCount(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
  return inventoryObjectTypeId;
}
