// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { coordToShardCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { InventoryTool } from "../../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../../src/codegen/tables/ItemMetadata.sol";
import { ObjectTypeMetadata } from "../../src/codegen/tables/ObjectTypeMetadata.sol";
import { UniqueEntity } from "../../src/codegen/tables/UniqueEntity.sol";
import { ShardField } from "../../src/codegen/tables/ShardField.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, FORCE_FIELD_SHARD_DIM } from "../../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../../src/ObjectTypeIds.sol";

function testGetUniqueEntity() returns (bytes32) {
  uint256 uniqueEntity = UniqueEntity.get() + 1;
  UniqueEntity.set(uniqueEntity);

  return bytes32(uniqueEntity);
}

function testReverseInventoryToolHasItem(bytes32 ownerEntityId, bytes32 inventoryEntityId) view returns (bool) {
  bytes32[] memory inventoryEntityIds = ReverseInventoryTool.get(ownerEntityId);
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] == inventoryEntityId) {
      return true;
    }
  }
  return false;
}

function testInventoryObjectsHasObjectType(bytes32 ownerEntityId, uint8 objectTypeId) view returns (bool) {
  uint8[] memory inventoryObjectTypes = InventoryObjects.get(ownerEntityId);
  for (uint256 i = 0; i < inventoryObjectTypes.length; i++) {
    if (inventoryObjectTypes[i] == objectTypeId) {
      return true;
    }
  }
  return false;
}

function testAddToInventoryCount(
  bytes32 ownerEntityId,
  uint8 ownerObjectTypeId,
  uint8 objectTypeId,
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

  if (numInitialObjects == 0) {
    InventoryObjects.push(ownerEntityId, objectTypeId);
  }
}

function testRemoveObjectTypeIdFromInventoryObjects(bytes32 ownerEntityId, uint8 removeObjectTypeId) {
  uint8[] memory currentObjectTypeIds = InventoryObjects.get(ownerEntityId);
  uint8[] memory newObjectTypeIds = new uint8[](currentObjectTypeIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < currentObjectTypeIds.length; i++) {
    if (currentObjectTypeIds[i] != removeObjectTypeId) {
      newObjectTypeIds[j] = currentObjectTypeIds[i];
      j++;
    }
  }
  if (newObjectTypeIds.length == 0) {
    InventoryObjects.deleteRecord(ownerEntityId);
  } else {
    InventoryObjects.set(ownerEntityId, newObjectTypeIds);
  }
}

function testRemoveFromInventoryCount(bytes32 ownerEntityId, uint8 objectTypeId, uint16 numObjectsToRemove) {
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
    testRemoveObjectTypeIdFromInventoryObjects(ownerEntityId, objectTypeId);
  } else {
    InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);
  }
}

function getForceField(VoxelCoord memory coord) view returns (bytes32) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  return ShardField.get(shardCoord.x, shardCoord.y, shardCoord.z);
}
