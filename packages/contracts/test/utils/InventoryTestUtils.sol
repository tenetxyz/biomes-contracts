// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Inventory } from "../../src/codegen/tables/Inventory.sol";
import { ReverseInventory } from "../../src/codegen/tables/ReverseInventory.sol";

function reverseInventoryHasItem(bytes32 ownerEntityId, bytes32 inventoryEntityId) view returns (bool) {
  bytes32[] memory inventoryEntityIds = ReverseInventory.get(ownerEntityId);
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] == inventoryEntityId) {
      return true;
    }
  }
  return false;
}
