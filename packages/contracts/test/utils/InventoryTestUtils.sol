// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Inventory } from "../../src/codegen/tables/Inventory.sol";
import { ReverseInventory } from "../../src/codegen/tables/ReverseInventory.sol";
import { ObjectType } from "../../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../../src/codegen/tables/ObjectTypeMetadata.sol";
import { InventorySlots } from "../../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../../src/codegen/tables/ItemMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS } from "../../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";

function testReverseInventoryHasItem(bytes32 ownerEntityId, bytes32 inventoryEntityId) view returns (bool) {
  bytes32[] memory inventoryEntityIds = ReverseInventory.get(ownerEntityId);
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] == inventoryEntityId) {
      return true;
    }
  }
  return false;
}

function testAddToInventoryCount(
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
