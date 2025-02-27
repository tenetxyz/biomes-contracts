// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { VoxelCoord } from "../../src/Types.sol";
import { EntityId } from "../../src/EntityId.sol";

import { ObjectType } from "../../src/codegen/tables/ObjectType.sol";
import { InventoryObjects } from "../../src/codegen/tables/InventoryObjects.sol";
import { InventoryCount } from "../../src/codegen/tables/InventoryCount.sol";
import { EnergyData } from "../../src/codegen/tables/Energy.sol";
import { ObjectAmount, ObjectTypeId, getOreObjectTypes } from "../../src/ObjectTypeIds.sol";
import { addToInventoryCount as _addToInventoryCount, removeFromInventoryCount as _removeFromInventoryCount, useEquipped as _useEquipped, removeEntityIdFromReverseInventoryEntity as _removeEntityIdFromReverseInventoryEntity, removeObjectTypeIdFromInventoryObjects as _removeObjectTypeIdFromInventoryObjects, transferAllInventoryEntities as _transferAllInventoryEntities, transferInventoryNonEntity as _transferInventoryNonEntity, transferInventoryEntity as _transferInventoryEntity } from "../../src/utils/InventoryUtils.sol";
import { updateMachineEnergyLevel as _updateMachineEnergyLevel } from "../../src/utils/EnergyUtils.sol";

Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

bytes32 constant LIB_ADDRESS_SLOT = keccak256("TestUtils.libAddress");

library TestUtils {
  /// @dev Allows calling test utils in the context of world
  modifier asWorld() {
    address world = WorldContextConsumerLib._world();
    if (address(this) != world) {
      // Next delegatecall will be from world
      vm.prank(world, true);
      (bool success, bytes memory data) = _getLibAddress().delegatecall(msg.data);
      /// @solidity memory-safe-assembly
      assembly {
        let dataOffset := add(data, 0x20)
        let dataSize := mload(data)
        switch success
        case 1 {
          return(dataOffset, dataSize)
        }
        default {
          revert(dataOffset, dataSize)
        }
      }
    }

    _;
  }

  // Hack to be able to access the library address until we figure out why mud doesn't allow it
  function init(address libAddress) public {
    vm.store(address(this), LIB_ADDRESS_SLOT, bytes32(bytes20(libAddress)));
  }

  function _getLibAddress() private view returns (address) {
    return address(bytes20(vm.load(address(this), LIB_ADDRESS_SLOT)));
  }

  function addToInventoryCount(
    EntityId ownerEntityId,
    ObjectTypeId ownerObjectTypeId,
    ObjectTypeId objectTypeId,
    uint16 numObjectsToAdd
  ) public asWorld {
    _addToInventoryCount(ownerEntityId, ownerObjectTypeId, objectTypeId, numObjectsToAdd);
  }

  function removeFromInventoryCount(
    EntityId ownerEntityId,
    ObjectTypeId objectTypeId,
    uint16 numObjectsToRemove
  ) public asWorld {
    _removeFromInventoryCount(ownerEntityId, objectTypeId, numObjectsToRemove);
  }

  function useEquipped(EntityId entityId) public asWorld {
    _useEquipped(entityId);
  }

  function removeEntityIdFromReverseInventoryEntity(
    EntityId ownerEntityId,
    EntityId removeInventoryEntityId
  ) public asWorld {
    _removeEntityIdFromReverseInventoryEntity(ownerEntityId, removeInventoryEntityId);
  }

  function removeObjectTypeIdFromInventoryObjects(
    EntityId ownerEntityId,
    ObjectTypeId removeObjectTypeId
  ) public asWorld {
    _removeObjectTypeIdFromInventoryObjects(ownerEntityId, removeObjectTypeId);
  }

  function transferAllInventoryEntities(
    EntityId fromEntityId,
    EntityId toEntityId,
    ObjectTypeId toObjectTypeId
  ) public asWorld returns (uint256) {
    return _transferAllInventoryEntities(fromEntityId, toEntityId, toObjectTypeId);
  }

  function transferInventoryNonEntity(
    EntityId srcEntityId,
    EntityId dstEntityId,
    ObjectTypeId dstObjectTypeId,
    ObjectTypeId transferObjectTypeId,
    uint16 numObjectsToTransfer
  ) public asWorld {
    _transferInventoryNonEntity(srcEntityId, dstEntityId, dstObjectTypeId, transferObjectTypeId, numObjectsToTransfer);
  }

  function transferInventoryEntity(
    EntityId srcEntityId,
    EntityId dstEntityId,
    ObjectTypeId dstObjectTypeId,
    EntityId inventoryEntityId
  ) public asWorld returns (ObjectTypeId) {
    return _transferInventoryEntity(srcEntityId, dstEntityId, dstObjectTypeId, inventoryEntityId);
  }

  function updateMachineEnergyLevel(EntityId entityId) public asWorld returns (EnergyData memory) {
    return _updateMachineEnergyLevel(entityId);
  }

  // No need to use asWorld here
  function inventoryObjectsHasObjectType(
    EntityId ownerEntityId,
    ObjectTypeId objectTypeId
  ) internal view returns (bool) {
    uint16[] memory inventoryObjectTypes = InventoryObjects.get(ownerEntityId);
    for (uint256 i = 0; i < inventoryObjectTypes.length; i++) {
      if (inventoryObjectTypes[i] == ObjectTypeId.unwrap(objectTypeId)) {
        return true;
      }
    }
    return false;
  }

  function inventoryGetOreAmounts(EntityId owner) internal view returns (ObjectAmount[] memory) {
    ObjectTypeId[] memory ores = getOreObjectTypes();

    uint256 numOres = 0;
    for (uint256 i = 0; i < ores.length; i++) {
      if (InventoryCount.get(owner, ores[i]) > 0) numOres++;
    }

    ObjectAmount[] memory oreAmounts = new ObjectAmount[](numOres);
    for (uint256 i = 0; i < ores.length; i++) {
      uint16 count = InventoryCount.get(owner, ores[i]);
      if (count > 0) {
        oreAmounts[numOres - 1] = ObjectAmount(ores[i], count);
        numOres--;
      }
    }

    return oreAmounts;
  }
}
