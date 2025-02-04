// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { coordToShardCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { WorldContextProviderLib, WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";

import { ReversePosition } from "../../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../../src/codegen/tables/ObjectType.sol";
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
import { BlockHash } from "../../src/codegen/tables/BlockHash.sol";

import { IProcGenSystem } from "../../src/codegen/world/IProcGenSystem.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, FORCE_FIELD_SHARD_DIM } from "../../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, SmartChestObjectID, WaterObjectID } from "../../src/ObjectTypeIds.sol";

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
  } else if (ownerObjectTypeId == ChestObjectID || ownerObjectTypeId == SmartChestObjectID) {
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

function testTransferAllInventoryEntities(
  bytes32 fromEntityId,
  bytes32 toEntityId,
  uint8 toObjectTypeId
) returns (uint256) {
  uint256 numTransferred = 0;
  uint8[] memory fromObjectTypeIds = InventoryObjects.get(fromEntityId);
  for (uint256 i = 0; i < fromObjectTypeIds.length; i++) {
    uint16 objectTypeCount = InventoryCount.get(fromEntityId, fromObjectTypeIds[i]);
    testAddToInventoryCount(toEntityId, toObjectTypeId, fromObjectTypeIds[i], objectTypeCount);
    testRemoveFromInventoryCount(fromEntityId, fromObjectTypeIds[i], objectTypeCount);
    numTransferred += objectTypeCount;
  }

  bytes32[] memory fromInventoryEntityIds = ReverseInventoryTool.get(fromEntityId);
  for (uint256 i = 0; i < fromInventoryEntityIds.length; i++) {
    InventoryTool.set(fromInventoryEntityIds[i], toEntityId);
    ReverseInventoryTool.push(toEntityId, fromInventoryEntityIds[i]);
  }
  if (fromInventoryEntityIds.length > 0) {
    ReverseInventoryTool.deleteRecord(fromEntityId);
  }

  return numTransferred;
}

function testRemoveEntityIdFromReverseInventoryTool(bytes32 ownerEntityId, bytes32 removeInventoryEntityId) {
  bytes32[] memory inventoryEntityIds = ReverseInventoryTool.get(ownerEntityId);
  bytes32[] memory newInventoryEntityIds = new bytes32[](inventoryEntityIds.length - 1);
  uint256 j = 0;
  for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
    if (inventoryEntityIds[i] != removeInventoryEntityId) {
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

function getForceField(VoxelCoord memory coord) view returns (bytes32) {
  VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
  return ShardField.get(shardCoord.x, shardCoord.y, shardCoord.z);
}

function testGetTerrainObjectTypeId(VoxelCoord memory coord) view returns (uint8) {
  (uint8 terrainObjectTypeId, ) = testGetTerrainAndOreObjectTypeId(coord, 0);
  return terrainObjectTypeId;
}

function testGetTerrainAndOreObjectTypeId(VoxelCoord memory coord, uint256 randomNumber) view returns (uint8, uint8) {
  return testStaticCallProcGenSystem(coord, randomNumber);
}

function testStaticCallProcGenSystem(VoxelCoord memory coord, uint256 randomNumber) view returns (uint8, uint8) {
  return
    abi.decode(
      testStaticCallInternalSystem(abi.encodeCall(IProcGenSystem.getTerrainBlockWithRandomness, (coord, randomNumber))),
      (uint8, uint8)
    );
}

function testStaticCallInternalSystem(bytes memory callData) view returns (bytes memory) {
  (bool success, bytes memory returnData) = WorldContextConsumerLib._world().staticcall(
    WorldContextProviderLib.appendContext({
      callData: callData,
      msgSender: WorldContextConsumerLib._msgSender(),
      msgValue: WorldContextConsumerLib._msgValue()
    })
  );

  if (!success) revertWithBytes(returnData);

  return returnData;
}

function testGravityApplies(VoxelCoord memory playerCoord) view returns (bool) {
  VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
  bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
  if (belowEntityId == bytes32(0)) {
    uint8 terrainObjectTypeId = testGetTerrainObjectTypeId(belowCoord);
    if (terrainObjectTypeId != AirObjectID) {
      return false;
    }
  } else if (ObjectType.get(belowEntityId) != AirObjectID || testGetTerrainObjectTypeId(belowCoord) == WaterObjectID) {
    return false;
  }

  return true;
}
