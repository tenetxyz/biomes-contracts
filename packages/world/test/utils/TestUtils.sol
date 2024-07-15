// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { InventoryTool } from "../../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../../src/codegen/tables/ItemMetadata.sol";
import { ObjectTypeMetadata } from "../../src/codegen/tables/ObjectTypeMetadata.sol";
import { UniqueEntity } from "../../src/codegen/tables/UniqueEntity.sol";
import { ShardFields } from "../../src/codegen/tables/ShardFields.sol";
import { ForceField, ForceFieldData } from "../../src/codegen/tables/ForceField.sol";

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

function getForceField(VoxelCoord memory coord, VoxelCoord memory shardCoord) view returns (bytes32) {
  bytes32[] memory forceFieldEntityIds = ShardFields.get(shardCoord.x, shardCoord.z);
  for (uint i = 0; i < forceFieldEntityIds.length; i++) {
    ForceFieldData memory forceFieldData = ForceField.get(forceFieldEntityIds[i]);

    // Check if coord inside of force field
    if (
      coord.x >= forceFieldData.fieldLowX &&
      coord.x <= forceFieldData.fieldHighX &&
      coord.z >= forceFieldData.fieldLowZ &&
      coord.z <= forceFieldData.fieldHighZ
    ) {
      return forceFieldEntityIds[i];
    }
  }
  return bytes32(0);
}

function getForceField(VoxelCoord memory coord) view returns (bytes32) {
  VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(coord, FORCE_FIELD_SHARD_DIM);
  return getForceField(coord, shardCoord);
}
