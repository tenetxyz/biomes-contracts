// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";

import { PositionData } from "./codegen/tables/Position.sol";
import { Inventory, InventoryTableId } from "./codegen/tables/Inventory.sol";
import { ObjectType } from "./codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "./codegen/tables/ObjectTypeMetadata.sol";
import { InventoryMetadata } from "./codegen/tables/InventoryMetadata.sol";

import { VoxelCoord } from "./Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS } from "./Constants.sol";

function positionDataToVoxelCoord(PositionData memory coord) pure returns (VoxelCoord memory) {
  return VoxelCoord(coord.x, coord.y, coord.z);
}

function inSurroundingCube(
  VoxelCoord memory cubeCenter,
  int32 halfWidth,
  VoxelCoord memory checkCoord
) pure returns (bool) {
  // Check if `checkCoord` is within the cube in all three dimensions
  bool isInX = checkCoord.x >= cubeCenter.x - halfWidth && checkCoord.x <= cubeCenter.x + halfWidth;
  bool isInY = checkCoord.y >= cubeCenter.y - halfWidth && checkCoord.y <= cubeCenter.y + halfWidth;
  bool isInZ = checkCoord.z >= cubeCenter.z - halfWidth && checkCoord.z <= cubeCenter.z + halfWidth;

  return isInX && isInY && isInZ;
}

function canHoldInventory(bytes32 objectTypeId) pure returns (bool) {
  return objectTypeId == AirObjectID || objectTypeId == PlayerObjectID || objectTypeId == ChestObjectID;
}

function addToInventory(bytes32 entityId, bytes32 objectTypeId, uint8 numObjectsToAdd) {
  bytes32 entityObjectTypeId = ObjectType.get(entityId);
  require(canHoldInventory(entityObjectTypeId), "This entity cannot hold an inventory");
  bytes32[] memory inventoryEntityIds;
  {
    (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData) = Inventory.encode(entityId);
    inventoryEntityIds = getKeysWithValue(InventoryTableId, staticData, encodedLengths, dynamicData);
  }

  uint8 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
  require(stackable > 0, "This object type cannot be added to the inventory");
  uint16 numUsesLeft = ObjectTypeMetadata.getDurability(objectTypeId);

  // Check if this object type id is already in the inventory, otherwise add a new one
  uint8 remainingObjectsToAdd = numObjectsToAdd;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    bytes32 inventoryId = inventoryEntityIds[i][0];
    bytes32 inventoryObjectId = ObjectType.get(inventoryId);
    uint8 numCurrentObjects = InventoryMetadata.getNumObjects(inventoryId);

    if (inventoryObjectId == objectTypeId && numCurrentObjects < stackable) {
      uint8 newNumObjects = numCurrentObjects + remainingObjectsToAdd;
      if (newNumObjects > stackable) {
        newNumObjects = stackable;
        remainingObjectsToAdd -= (stackable - numCurrentObjects);
      } else {
        remainingObjectsToAdd = 0;
      }

      InventoryMetadata.setNumObjects(inventoryId, newNumObjects);
    }

    if (remainingObjectsToAdd == 0) {
      break;
    }
  }

  uint256 inventoryEntityIdsLength = inventoryEntityIds.length;
  while (remainingObjectsToAdd > 0) {
    // add as many new inventory slots per stackable limit to store the remaining objects
    if (entityObjectTypeId == AirObjectID) {
      require(inventoryEntityIdsLength < MAX_PLAYER_INVENTORY_SLOTS, "Player inventory is full");
    } else if (entityObjectTypeId == ChestObjectID) {
      require(inventoryEntityIdsLength < MAX_CHEST_INVENTORY_SLOTS, "Chest inventory is full");
    }

    // Add new object to inventory
    bytes32 inventoryEntityId = getUniqueEntity();
    Inventory.set(inventoryEntityId, entityId);
    ObjectType.set(inventoryEntityId, objectTypeId);
    uint8 newNumObjects = remainingObjectsToAdd;
    if (remainingObjectsToAdd > stackable) {
      newNumObjects = stackable;
      remainingObjectsToAdd -= stackable;
      inventoryEntityIdsLength += 1;
    } else {
      remainingObjectsToAdd = 0;
    }

    InventoryMetadata.set(inventoryEntityId, newNumObjects, numUsesLeft);
  }
}

function removeFromInventory(bytes32 inventorEntityId, uint8 numObjectsToRemove) {
  uint8 numCurrentObjects = InventoryMetadata.getNumObjects(inventorEntityId);
  require(numCurrentObjects >= numObjectsToRemove, "Not enough objects in inventory");
  if (numCurrentObjects > numObjectsToRemove) {
    InventoryMetadata.setNumObjects(inventorEntityId, numCurrentObjects - numObjectsToRemove);
  } else {
    Inventory.deleteRecord(inventorEntityId);
    InventoryMetadata.deleteRecord(inventorEntityId);
  }
}
