// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { InventoryTool } from "../../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../../src/codegen/tables/ItemMetadata.sol";
import { ObjectTypeMetadata } from "../../src/codegen/tables/ObjectTypeMetadata.sol";
import { UniqueEntity } from "../../src/codegen/tables/UniqueEntity.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS } from "../../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../../src/ObjectTypeIds.sol";
import { isChest } from "../../src/utils/ObjectTypeUtils.sol";

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
  } else if (isChest(ownerObjectTypeId)) {
    require(numFinalSlotsUsed <= MAX_CHEST_INVENTORY_SLOTS, "Inventory is full");
  }
  InventorySlots.set(ownerEntityId, numFinalSlotsUsed);
  InventoryCount.set(ownerEntityId, objectTypeId, numFinalObjects);

  if (numInitialObjects == 0) {
    InventoryObjects.push(ownerEntityId, objectTypeId);
  }
}
