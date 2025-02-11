// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../../src/Types.sol";
import { EntityId } from "../../src/EntityId.sol";

import { UniqueEntity } from "../../src/codegen/tables/UniqueEntity.sol";
import { ReversePosition } from "../../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../../src/codegen/tables/ObjectType.sol";
import { InventoryTool } from "../../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../../src/codegen/tables/Equipped.sol";
import { Mass } from "../../src/codegen/tables/Mass.sol";
import { ObjectTypeMetadata } from "../../src/codegen/tables/ObjectTypeMetadata.sol";
import { ObjectCategory } from "../../src/codegen/common.sol";

import { PlayerObjectID, ChestObjectID, SmartChestObjectID, AirObjectID, WaterObjectID } from "../../src/ObjectTypeIds.sol";

function testGetUniqueEntity() returns (EntityId) {
  uint256 uniqueEntity = UniqueEntity.get() + 1;
  UniqueEntity.set(uniqueEntity);

  return EntityId.wrap(bytes32(uniqueEntity));
}

function testGravityApplies(VoxelCoord memory playerCoord) view returns (bool) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  EntityId belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
  require(belowEntityId.exists(), "Attempted to apply gravity but encountered an unrevealed block");
  uint16 belowObjectTypeId = ObjectType.get(belowEntityId);
  if (belowObjectTypeId != AirObjectID && belowObjectTypeId != WaterObjectID) {
    return false;
  }

  return true;
}

function testAddToInventoryCount(
  EntityId ownerEntityId,
  uint16 ownerObjectTypeId,
  uint16 objectTypeId,
  uint16 numObjectsToAdd
) {
  uint16 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
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
  require(numFinalSlotsUsed <= ObjectTypeMetadata.getMaxInventorySlots(ownerObjectTypeId), "Inventory is full");
  InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);

  if (numInitialObjects == 0) {
    InventoryObjects._push(ownerEntityId, objectTypeId);
  }
}

function testRemoveFromInventoryCount(EntityId ownerEntityId, uint16 objectTypeId, uint16 numObjectsToRemove) {
  uint16 numInitialObjects = InventoryCount.get(ownerEntityId, objectTypeId);
  require(numInitialObjects >= numObjectsToRemove, "Not enough objects in the inventory");

  uint16 stackable = ObjectTypeMetadata.getStackable(objectTypeId);
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

function testUseEquipped(
  EntityId entityId,
  EntityId inventoryEntityId,
  uint16 inventoryObjectTypeId,
  uint24 durabilityDecrease
) {
  if (inventoryEntityId.exists()) {
    uint128 durabilityLeft = Mass.getMass(inventoryEntityId);
    // Allow mining even if durability is exactly or less than required, then break the tool
    require(durabilityLeft > 0, "Tool is already broken");

    if (durabilityLeft <= durabilityDecrease) {
      // Tool will break after this use, but allow mining
      // Destroy equipped item
      testRemoveFromInventoryCount(entityId, inventoryObjectTypeId, 1);
      Mass.deleteRecord(inventoryEntityId);
      InventoryTool.deleteRecord(inventoryEntityId);
      testRemoveEntityIdFromReverseInventoryTool(entityId, inventoryEntityId);
      Equipped.deleteRecord(entityId);
    } else {
      Mass.setMass(inventoryEntityId, durabilityLeft - durabilityDecrease);
    }
  }
}

function testRemoveEntityIdFromReverseInventoryTool(EntityId ownerEntityId, EntityId removeInventoryEntityId) {
  bytes32[] memory inventoryEntityIds = ReverseInventoryTool._get(ownerEntityId);
  bytes32[] memory newInventoryEntityIds = new bytes32[](inventoryEntityIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] != EntityId.unwrap(removeInventoryEntityId)) {
      newInventoryEntityIds[j] = inventoryEntityIds[i];
      j++;
    }
  }
  if (newInventoryEntityIds.length == 0) {
    ReverseInventoryTool.deleteRecord(ownerEntityId);
  } else {
    ReverseInventoryTool.set(ownerEntityId, newInventoryEntityIds);
  }
}

function testRemoveObjectTypeIdFromInventoryObjects(EntityId ownerEntityId, uint16 removeObjectTypeId) {
  uint16[] memory currentObjectTypeIds = InventoryObjects._get(ownerEntityId);
  uint16[] memory newObjectTypeIds = new uint16[](currentObjectTypeIds.length - 1);
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

function testTransferAllInventoryEntities(
  EntityId fromEntityId,
  EntityId toEntityId,
  uint16 toObjectTypeId
) returns (uint256) {
  uint256 numTransferred = 0;
  uint16[] memory fromObjectTypeIds = InventoryObjects._get(fromEntityId);
  for (uint256 i = 0; i < fromObjectTypeIds.length; i++) {
    uint16 objectTypeCount = InventoryCount._get(fromEntityId, fromObjectTypeIds[i]);
    testAddToInventoryCount(toEntityId, toObjectTypeId, fromObjectTypeIds[i], objectTypeCount);
    testRemoveFromInventoryCount(fromEntityId, fromObjectTypeIds[i], objectTypeCount);
    numTransferred += objectTypeCount;
  }

  bytes32[] memory fromInventoryEntityIds = ReverseInventoryTool._get(fromEntityId);
  for (uint256 i = 0; i < fromInventoryEntityIds.length; i++) {
    InventoryTool._set(EntityId.wrap(fromInventoryEntityIds[i]), toEntityId);
    ReverseInventoryTool.push(toEntityId, fromInventoryEntityIds[i]);
  }
  if (fromInventoryEntityIds.length > 0) {
    ReverseInventoryTool.deleteRecord(fromEntityId);
  }

  return numTransferred;
}

function testTransferInventoryNonTool(
  EntityId srcEntityId,
  EntityId dstEntityId,
  uint16 dstObjectTypeId,
  uint16 transferObjectTypeId,
  uint16 numObjectsToTransfer
) {
  require(
    ObjectTypeMetadata.getObjectCategory(transferObjectTypeId) == ObjectCategory.Block,
    "Object type is not a block"
  );
  require(numObjectsToTransfer > 0, "Amount must be greater than 0");
  testRemoveFromInventoryCount(srcEntityId, transferObjectTypeId, numObjectsToTransfer);
  testAddToInventoryCount(dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
}

function testTransferInventoryTool(
  EntityId srcEntityId,
  EntityId dstEntityId,
  uint16 dstObjectTypeId,
  EntityId toolEntityId
) returns (uint16) {
  require(InventoryTool.get(toolEntityId) == srcEntityId, "Entity does not own inventory item");
  if (Equipped.get(srcEntityId) == toolEntityId) {
    Equipped.deleteRecord(srcEntityId);
  }
  InventoryTool.set(toolEntityId, dstEntityId);
  ReverseInventoryTool.push(dstEntityId, EntityId.unwrap(toolEntityId));
  testRemoveEntityIdFromReverseInventoryTool(srcEntityId, toolEntityId);

  uint16 inventoryObjectTypeId = ObjectType._get(toolEntityId);
  testRemoveFromInventoryCount(srcEntityId, inventoryObjectTypeId, 1);
  testAddToInventoryCount(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
  return inventoryObjectTypeId;
}
