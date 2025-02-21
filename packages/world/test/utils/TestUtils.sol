// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

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
import { gravityApplies as _gravityApplies } from "../../src/Utils.sol";
import { addToInventoryCount as _addToInventoryCount, removeFromInventoryCount as _removeFromInventoryCount, useEquipped as _useEquipped, removeEntityIdFromReverseInventoryEntity as _removeEntityIdFromReverseInventoryEntity, removeObjectTypeIdFromInventoryObjects as _removeObjectTypeIdFromInventoryObjects, transferAllInventoryEntities as _transferAllInventoryEntities, transferInventoryNonEntity as _transferInventoryNonEntity, transferInventoryEntity as _transferInventoryEntity } from "../../src/utils/InventoryUtils.sol";

Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

contract TestUtils {
  address private immutable world;

  /// @dev Allows calling test utils in the context of world
  modifier testUtil() {
    if (address(this) != world) {
      // Next delegatecall will be from world
      vm.startPrank(world, true);
      (bool success, bytes memory data) = address(this).delegatecall(msg.data);
      vm.stopPrank();
      if (success) {
        /// @solidity memory-safe-assembly
        assembly {
          return(add(data, 0x20), mload(data))
        }
      }
      /// @solidity memory-safe-assembly
      assembly {
        revert(add(data, 0x20), mload(data))
      }
    } else {
      _;
    }
  }

  constructor(address _world) {
    world = _world;
  }

  function gravityApplies(VoxelCoord memory playerCoord) public testUtil returns (bool res) {
    return _gravityApplies(playerCoord);
  }

  function addToInventoryCount(
    EntityId ownerEntityId,
    ObjectTypeId ownerObjectTypeId,
    ObjectTypeId objectTypeId,
    uint16 numObjectsToAdd
  ) public testUtil {
    _addToInventoryCount(ownerEntityId, ownerObjectTypeId, objectTypeId, numObjectsToAdd);
  }

  function removeFromInventoryCount(
    EntityId ownerEntityId,
    ObjectTypeId objectTypeId,
    uint16 numObjectsToRemove
  ) public testUtil {
    _removeFromInventoryCount(ownerEntityId, objectTypeId, numObjectsToRemove);
  }

  function useEquipped(EntityId entityId) public testUtil {
    _useEquipped(entityId);
  }

  function removeEntityIdFromReverseInventoryEntity(
    EntityId ownerEntityId,
    EntityId removeInventoryEntityId
  ) public testUtil {
    _removeEntityIdFromReverseInventoryEntity(ownerEntityId, removeInventoryEntityId);
  }

  function removeObjectTypeIdFromInventoryObjects(
    EntityId ownerEntityId,
    ObjectTypeId removeObjectTypeId
  ) public testUtil {
    _removeObjectTypeIdFromInventoryObjects(ownerEntityId, removeObjectTypeId);
  }

  function transferAllInventoryEntities(
    EntityId fromEntityId,
    EntityId toEntityId,
    ObjectTypeId toObjectTypeId
  ) public returns (uint256) {
    return _transferAllInventoryEntities(fromEntityId, toEntityId, toObjectTypeId);
  }

  function transferInventoryNonEntity(
    EntityId srcEntityId,
    EntityId dstEntityId,
    ObjectTypeId dstObjectTypeId,
    ObjectTypeId transferObjectTypeId,
    uint16 numObjectsToTransfer
  ) public {
    _transferInventoryNonEntity(srcEntityId, dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
  }

  function transferInventoryEntity(
    EntityId srcEntityId,
    EntityId dstEntityId,
    ObjectTypeId dstObjectTypeId,
    EntityId inventoryEntityId
  ) public returns (ObjectTypeId) {
    return _transferInventoryEntity(srcEntityId, dstEntityId, dstObjectTypeId, inventoryEntityId);
  }
}

// TODO: remove
function testGetUniqueEntity() returns (EntityId) {
  uint256 uniqueEntity = UniqueEntity.get() + 1;
  UniqueEntity.set(uniqueEntity);

  return EntityId.wrap(bytes32(uniqueEntity));
}

function testInventoryObjectsHasObjectType(EntityId ownerEntityId, ObjectTypeId objectTypeId) view returns (bool) {
  uint16[] memory inventoryObjectTypes = InventoryObjects.get(ownerEntityId);
  for (uint256 i = 0; i < inventoryObjectTypes.length; i++) {
    if (inventoryObjectTypes[i] == ObjectTypeId.unwrap(objectTypeId)) {
      return true;
    }
  }
  return false;
}
