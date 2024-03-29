// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { InventorySlots } from "../codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS } from "../Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";

function addToInventoryCount(
  bytes32 ownerEntityId,
  bytes32 ownerObjectTypeId,
  bytes32 objectTypeId,
  uint16 numObjectsToAdd
) {
  uint8 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be added to the inventory");

  uint16 numInitialObjects = InventoryCount.get(ownerEntityId, objectTypeId);
  uint16 numInitialFullStacks = numInitialObjects / stackable;
  bool hasInitialPartialStack = numInitialObjects % stackable != 0;
  uint16 numFinalObjects = numInitialObjects + numObjectsToAdd;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numInitialSlotsUsed = InventorySlots.get(ownerEntityId);
  uint16 numFinalSlotsUsedDelta = (numFinalFullStacks + (hasFinalPartialStack ? 1 : 0)) -
    (numInitialFullStacks + (hasInitialPartialStack ? 1 : 0));
  uint16 numFinalSlotsUsed = numInitialSlotsUsed + numFinalSlotsUsedDelta;
  if (ownerObjectTypeId == PlayerObjectID) {
    require(numFinalSlotsUsed <= MAX_PLAYER_INVENTORY_SLOTS, "Inventory is full");
  } else if (ownerObjectTypeId == ChestObjectID) {
    require(numFinalSlotsUsed <= MAX_CHEST_INVENTORY_SLOTS, "Inventory is full");
  }
  InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);
}

function removeFromInventoryCount(bytes32 ownerEntityId, bytes32 objectTypeId, uint16 numObjectsToRemove) {
  uint16 numInitialObjects = InventoryCount.get(ownerEntityId, objectTypeId);
  require(numInitialObjects >= numObjectsToRemove, "Not enough objects in the inventory");

  uint8 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be removed from the inventory");

  uint16 numInitialFullStacks = numInitialObjects / stackable;
  bool hasInitialPartialStack = numInitialObjects % stackable != 0;

  uint16 numFinalObjects = numInitialObjects - numObjectsToRemove;
  uint16 numFinalFullStacks = numFinalObjects / stackable;
  bool hasFinalPartialStack = numFinalObjects % stackable != 0;

  uint16 numInitialSlotsUsed = InventorySlots.get(ownerEntityId);
  uint16 numFinalSlotsUsedDelta = (numInitialFullStacks + (hasInitialPartialStack ? 1 : 0)) -
    (numFinalFullStacks + (hasFinalPartialStack ? 1 : 0));
  uint16 numFinalSlotsUsed = numInitialSlotsUsed - numFinalSlotsUsedDelta;
  if (numFinalSlotsUsed == 0) {
    InventorySlots.deleteRecord(ownerEntityId);
  } else {
    InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  }

  if (numFinalObjects == 0) {
    InventoryCount.deleteRecord(ownerEntityId, objectTypeId);
  } else {
    InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);
  }
}

function useEquipped(bytes32 entityId, bytes32 inventoryEntityId) {
  if (inventoryEntityId != bytes32(0)) {
    uint24 numUsesLeft = ItemMetadata.get(inventoryEntityId);
    if (numUsesLeft > 0) {
      if (numUsesLeft == 1) {
        // Destroy equipped item
        removeFromInventoryCount(entityId, ObjectType.get(inventoryEntityId), 1);
        ItemMetadata.deleteRecord(inventoryEntityId);
        Inventory.deleteRecord(inventoryEntityId);
        Equipped.deleteRecord(entityId);
        removeEntityIdFromReverseInventory(entityId, inventoryEntityId);
        ObjectType.deleteRecord(inventoryEntityId);
      } else {
        ItemMetadata.set(inventoryEntityId, numUsesLeft - 1);
      }
    } // 0 = unlimited uses
  }
}

function removeEntityIdFromReverseInventory(bytes32 ownerEntityId, bytes32 removeInventoryEntityId) {
  bytes32[] memory inventoryEntityIds = ReverseInventory.get(ownerEntityId);
  bytes32[] memory newInventoryEntityIds = new bytes32[](inventoryEntityIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] != removeInventoryEntityId) {
      newInventoryEntityIds[j] = inventoryEntityIds[i];
      j++;
    }
  }
  if (newInventoryEntityIds.length == 0) {
    ReverseInventory.deleteRecord(ownerEntityId);
  } else {
    ReverseInventory.set(ownerEntityId, newInventoryEntityIds);
  }
}

function transferAllInventoryEntities(bytes32 fromEntityId, bytes32 toEntityId, bytes32 toObjectTypeId) {
  bytes32[] memory fromInventoryEntityIds = ReverseInventory.get(fromEntityId);
  for (uint256 i = 0; i < fromInventoryEntityIds.length; i++) {
    bytes32 inventoryObjectTypeId = ObjectType.get(fromInventoryEntityIds[i]);
    addToInventoryCount(toEntityId, toObjectTypeId, inventoryObjectTypeId, 1);
    removeFromInventoryCount(fromEntityId, inventoryObjectTypeId, 1);
    Inventory.set(fromInventoryEntityIds[i], toEntityId);
    ReverseInventory.push(toEntityId, fromInventoryEntityIds[i]);
  }
  ReverseInventory.deleteRecord(fromEntityId);
}

function transferInventoryItem(
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  bytes32 dstObjectTypeId,
  bytes32 inventoryEntityId
) {
  require(Inventory.get(inventoryEntityId) == srcEntityId, "Entity does not own inventory item");
  if (Equipped.get(srcEntityId) == inventoryEntityId) {
    Equipped.deleteRecord(srcEntityId);
  }
  Inventory.set(inventoryEntityId, dstEntityId);
  ReverseInventory.push(dstEntityId, inventoryEntityId);
  removeEntityIdFromReverseInventory(srcEntityId, inventoryEntityId);

  bytes32 inventoryObjectTypeId = ObjectType.get(inventoryEntityId);
  removeFromInventoryCount(srcEntityId, inventoryObjectTypeId, 1);
  addToInventoryCount(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
}
