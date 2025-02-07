// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReverseInventoryTool } from "../codegen/tables/ReverseInventoryTool.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { InventoryObject, InventoryTool } from "../Types.sol";

function getEntityInventory(bytes32 entityId) view returns (InventoryObject[] memory) {
  uint8[] memory objectTypeIds = InventoryObjects._get(entityId);
  InventoryObject[] memory inventoryObjects = new InventoryObject[](objectTypeIds.length);
  bytes32[] memory allInventoryTools = ReverseInventoryTool._get(entityId);
  for (uint256 i = 0; i < objectTypeIds.length; i++) {
    uint16 objectTypeId = objectTypeIds[i];
    uint16 count = InventoryCount._get(entityId, objectTypeId);
    bool isTool = ObjectTypeMetadata._getIsTool(objectTypeId);
    uint256 numTools = 0;
    if (isTool) {
      for (uint256 j = 0; j < allInventoryTools.length; j++) {
        if (ObjectType._get(allInventoryTools[j]) == objectTypeId) {
          numTools++;
        }
      }
    }
    InventoryTool[] memory inventoryTools = new InventoryTool[](numTools);
    if (numTools > 0) {
      uint256 k = 0;
      for (uint256 j = 0; j < allInventoryTools.length; j++) {
        if (ObjectType._get(allInventoryTools[j]) == objectTypeId) {
          inventoryTools[k] = InventoryTool({
            entityId: allInventoryTools[j],
            numUsesLeft: ItemMetadata._getNumUsesLeft(allInventoryTools[j])
          });
          k++;
        }
      }
    }
    inventoryObjects[i] = InventoryObject({ objectTypeId: objectTypeId, numObjects: count, tools: inventoryTools });
  }
  return inventoryObjects;
}
