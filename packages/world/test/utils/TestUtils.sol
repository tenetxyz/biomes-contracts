// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../../src/Types.sol";
import { EntityId } from "../../src/EntityId.sol";

import { UniqueEntity } from "../../src/codegen/tables/UniqueEntity.sol";
import { ReversePosition } from "../../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../../src/codegen/tables/ObjectType.sol";
import { InventoryEntity } from "../../src/codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "../../src/codegen/tables/ReverseInventoryEntity.sol";
import { InventorySlots } from "../../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../../src/codegen/tables/Equipped.sol";
import { Mass } from "../../src/codegen/tables/Mass.sol";
import { ObjectTypeMetadata } from "../../src/codegen/tables/ObjectTypeMetadata.sol";
import { TerrainLib } from "../../src/systems/libraries/TerrainLib.sol";
import { ObjectTypeId, PlayerObjectID, ChestObjectID, SmartChestObjectID, AirObjectID, WaterObjectID } from "../../src/ObjectTypeIds.sol";

function testGetUniqueEntity() returns (EntityId) {
  uint256 uniqueEntity = UniqueEntity.get() + 1;
  UniqueEntity.set(uniqueEntity);

  return EntityId.wrap(bytes32(uniqueEntity));
}

function testGravityApplies(VoxelCoord memory playerCoord) view returns (bool) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  EntityId belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
  if (!belowEntityId.exists()) {
    ObjectTypeId terrainObjectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(belowCoord));
    if (terrainObjectTypeId != AirObjectID && terrainObjectTypeId != WaterObjectID) {
      return false;
    }
  } else {
    ObjectTypeId belowObjectTypeId = ObjectType.get(belowEntityId);
    if (belowObjectTypeId != AirObjectID && belowObjectTypeId != WaterObjectID) {
      return false;
    }
  }

  return true;
}

function testAddToInventoryCount(
  EntityId ownerEntityId,
  ObjectTypeId ownerObjectTypeId,
  ObjectTypeId objectTypeId,
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
    InventoryObjects.push(ownerEntityId, objectTypeId.unwrap());
  }
}

function testRemoveFromInventoryCount(EntityId ownerEntityId, ObjectTypeId objectTypeId, uint16 numObjectsToRemove) {
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
  ObjectTypeId inventoryObjectTypeId,
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
      InventoryEntity.deleteRecord(inventoryEntityId);
      testRemoveEntityIdFromReverseInventoryEntity(entityId, inventoryEntityId);
      Equipped.deleteRecord(entityId);
    } else {
      Mass.setMass(inventoryEntityId, durabilityLeft - durabilityDecrease);
    }
  }
}

function testRemoveEntityIdFromReverseInventoryEntity(EntityId ownerEntityId, EntityId removeInventoryEntityId) {
  bytes32[] memory inventoryEntityIds = ReverseInventoryEntity.get(ownerEntityId);
  bytes32[] memory newInventoryEntityIds = new bytes32[](inventoryEntityIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] != EntityId.unwrap(removeInventoryEntityId)) {
      newInventoryEntityIds[j] = inventoryEntityIds[i];
      j++;
    }
  }
  if (newInventoryEntityIds.length == 0) {
    ReverseInventoryEntity.deleteRecord(ownerEntityId);
  } else {
    ReverseInventoryEntity.set(ownerEntityId, newInventoryEntityIds);
  }
}

function testRemoveObjectTypeIdFromInventoryObjects(EntityId ownerEntityId, ObjectTypeId removeObjectTypeId) {
  uint16[] memory currentObjectTypeIds = InventoryObjects.get(ownerEntityId);
  uint16[] memory newObjectTypeIds = new uint16[](currentObjectTypeIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < currentObjectTypeIds.length; i++) {
    if (currentObjectTypeIds[i] != removeObjectTypeId.unwrap()) {
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
  ObjectTypeId toObjectTypeId
) returns (uint256) {
  uint256 numTransferred = 0;
  uint16[] memory fromObjectTypeIds = InventoryObjects.get(fromEntityId);
  for (uint256 i = 0; i < fromObjectTypeIds.length; i++) {
    uint16 objectTypeCount = InventoryCount.get(fromEntityId, ObjectTypeId.wrap(fromObjectTypeIds[i]));
    testAddToInventoryCount(toEntityId, toObjectTypeId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    testRemoveFromInventoryCount(fromEntityId, ObjectTypeId.wrap(fromObjectTypeIds[i]), objectTypeCount);
    numTransferred += objectTypeCount;
  }

  bytes32[] memory fromInventoryEntityIds = ReverseInventoryEntity.get(fromEntityId);
  for (uint256 i = 0; i < fromInventoryEntityIds.length; i++) {
    InventoryEntity.set(EntityId.wrap(fromInventoryEntityIds[i]), toEntityId);
    ReverseInventoryEntity.push(toEntityId, fromInventoryEntityIds[i]);
  }
  if (fromInventoryEntityIds.length > 0) {
    ReverseInventoryEntity.deleteRecord(fromEntityId);
  }

  return numTransferred;
}

function testTransferInventoryNonEntity(
  EntityId srcEntityId,
  EntityId dstEntityId,
  ObjectTypeId dstObjectTypeId,
  ObjectTypeId transferObjectTypeId,
  uint16 numObjectsToTransfer
) {
  require(transferObjectTypeId.isBlock() || transferObjectTypeId.isItem(), "Object type is not a block or item");
  require(numObjectsToTransfer > 0, "Amount must be greater than 0");
  testRemoveFromInventoryCount(srcEntityId, transferObjectTypeId, numObjectsToTransfer);
  testAddToInventoryCount(dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
}

function testTransferInventoryEntity(
  EntityId srcEntityId,
  EntityId dstEntityId,
  ObjectTypeId dstObjectTypeId,
  EntityId inventoryEntityId
) returns (ObjectTypeId) {
  require(InventoryEntity.get(inventoryEntityId) == srcEntityId, "Entity does not own inventory item");
  if (Equipped.get(srcEntityId) == inventoryEntityId) {
    Equipped.deleteRecord(srcEntityId);
  }
  InventoryEntity.set(inventoryEntityId, dstEntityId);
  ReverseInventoryEntity.push(dstEntityId, EntityId.unwrap(inventoryEntityId));
  testRemoveEntityIdFromReverseInventoryEntity(srcEntityId, inventoryEntityId);

  ObjectTypeId inventoryObjectTypeId = ObjectType.get(inventoryEntityId);
  testRemoveFromInventoryCount(srcEntityId, inventoryObjectTypeId, 1);
  testAddToInventoryCount(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
  return inventoryObjectTypeId;
}
