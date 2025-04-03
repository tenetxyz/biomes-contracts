// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { Direction } from "../codegen/common.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { MachineData } from "../codegen/tables/Machine.sol";

import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ReverseInventoryEntity } from "../codegen/tables/ReverseInventoryEntity.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { Vec3 } from "../Vec3.sol";

using ObjectTypeLib for ObjectTypeId;

struct InventoryEntity {
  EntityId entityId;
  uint128 mass;
}

struct InventoryObject {
  ObjectTypeId objectTypeId;
  uint16 numObjects;
  InventoryEntity[] inventoryEntities;
}

struct PlayerEntityData {
  address playerAddress;
  EntityId bed;
  EntityId equipped;
  EntityData entityData;
}

struct EntityData {
  EntityId entityId;
  EntityId baseEntityId;
  ObjectTypeId objectTypeId;
  Vec3 position;
  Direction orientation;
  InventoryObject[] inventory;
  ResourceId programSystemId;
  uint256 mass;
  EnergyData energy;
  MachineData machine;
}

function getEntityInventory(EntityId entityId) view returns (InventoryObject[] memory) {
  uint16[] memory objectTypeIds = InventoryObjects._get(entityId);
  InventoryObject[] memory inventoryObjects = new InventoryObject[](objectTypeIds.length);
  bytes32[] memory allInventories = ReverseInventoryEntity._get(entityId);
  for (uint256 i = 0; i < objectTypeIds.length; i++) {
    ObjectTypeId objectTypeId = ObjectTypeId.wrap(objectTypeIds[i]);
    uint16 count = InventoryCount._get(entityId, objectTypeId);
    bool isTool = objectTypeId.isTool();
    uint256 numEntities = 0;
    if (isTool) {
      for (uint256 j = 0; j < allInventories.length; j++) {
        if (ObjectType._get(EntityId.wrap(allInventories[j])) == objectTypeId) {
          numEntities++;
        }
      }
    }
    InventoryEntity[] memory inventoryEntities = new InventoryEntity[](numEntities);
    if (numEntities > 0) {
      uint256 k = 0;
      for (uint256 j = 0; j < allInventories.length; j++) {
        EntityId tool = EntityId.wrap(allInventories[j]);
        if (ObjectType._get(tool) == objectTypeId) {
          inventoryEntities[k] = InventoryEntity({ entityId: tool, mass: Mass._getMass(tool) });
          k++;
        }
      }
    }
    inventoryObjects[i] =
      InventoryObject({ objectTypeId: objectTypeId, numObjects: count, inventoryEntities: inventoryEntities });
  }
  return inventoryObjects;
}
