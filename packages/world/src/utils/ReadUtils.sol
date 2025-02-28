// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReverseInventoryEntity } from "../codegen/tables/ReverseInventoryEntity.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../codegen/tables/Mass.sol";

import { InventoryObject, InventoryEntity } from "../Types.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectType } from "../ObjectType.sol";

function getEntityInventory(EntityId entityId) view returns (InventoryObject[] memory) {
  uint16[] memory objectTypes = InventoryObjects._get(entityId);
  InventoryObject[] memory inventoryObjects = new InventoryObject[](objectTypes.length);
  bytes32[] memory allInventoryEntityIds = ReverseInventoryEntity._get(entityId);
  for (uint256 i = 0; i < objectTypes.length; i++) {
    ObjectType objectType = ObjectType.wrap(objectTypes[i]);
    uint16 count = InventoryCount._get(entityId, objectType);
    bool isTool = objectType.isTool();
    uint256 numEntities = 0;
    if (isTool) {
      for (uint256 j = 0; j < allInventoryEntityIds.length; j++) {
        if (ObjectType._get(EntityId.wrap(allInventoryEntityIds[j])) == objectType) {
          numEntities++;
        }
      }
    }
    InventoryEntity[] memory inventoryEntities = new InventoryEntity[](numEntities);
    if (numEntities > 0) {
      uint256 k = 0;
      for (uint256 j = 0; j < allInventoryEntityIds.length; j++) {
        EntityId toolEntityId = EntityId.wrap(allInventoryEntityIds[j]);
        if (ObjectType._get(toolEntityId) == objectType) {
          inventoryEntities[k] = InventoryEntity({ entityId: toolEntityId, mass: Mass._getMass(toolEntityId) });
          k++;
        }
      }
    }
    inventoryObjects[i] = InventoryObject({
      objectType: objectType,
      numObjects: count,
      inventoryEntities: inventoryEntities
    });
  }
  return inventoryObjects;
}
