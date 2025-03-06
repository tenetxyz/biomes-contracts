// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { EntityId } from "../../src/EntityId.sol";
import { Vec3 } from "../../src/Vec3.sol";

import { EnergyData } from "../../src/codegen/tables/Energy.sol";
import { computeBoundaryShards as _computeBoundaryShards } from "../../src/systems/ForceFieldSystem.sol";

import { ObjectTypeId } from "../../src/ObjectTypeId.sol";
import { addToInventoryCount as _addToInventoryCount, removeFromInventoryCount as _removeFromInventoryCount, useEquipped as _useEquipped, removeEntityIdFromReverseInventoryEntity as _removeEntityIdFromReverseInventoryEntity, removeObjectTypeIdFromInventoryObjects as _removeObjectTypeIdFromInventoryObjects, transferAllInventoryEntities as _transferAllInventoryEntities, transferInventoryNonEntity as _transferInventoryNonEntity, transferInventoryEntity as _transferInventoryEntity } from "../../src/utils/InventoryUtils.sol";
import { updateEnergyLevel as _updateEnergyLevel } from "../../src/utils/EnergyUtils.sol";
import { isForceFieldShard as _isForceFieldShard, isForceFieldActive as _isForceFieldActive, getForceField as _getForceField, setupForceField as _setupForceField } from "../../src/utils/ForceFieldUtils.sol";

Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

library TestUtils {
  /// @dev Allows calling test utils in the context of world
  function asWorld(bytes32 libAddressSlot) internal {
    address world = WorldContextConsumerLib._world();
    if (address(this) != world) {
      // Next delegatecall will be from world
      vm.prank(world, true);
      (bool success, bytes memory data) = _getLibAddress(libAddressSlot).delegatecall(msg.data);
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
  }

  function _getLibAddress(bytes32 libAddressSlot) private view returns (address) {
    return address(bytes20(vm.load(address(this), libAddressSlot)));
  }

  function init(bytes32 libAddressSlot, address libAddress) internal {
    vm.store(address(this), libAddressSlot, bytes32(bytes20(libAddress)));
  }
}

library TestInventoryUtils {
  bytes32 constant LIB_ADDRESS_SLOT = keccak256("TestUtils.TestInventoryUtils");

  modifier asWorld() {
    TestUtils.asWorld(LIB_ADDRESS_SLOT);
    _;
  }

  // Hack to be able to access the library address until we figure out why mud doesn't allow it
  function init(address libAddress) public {
    TestUtils.init(LIB_ADDRESS_SLOT, libAddress);
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
}

library TestEnergyUtils {
  bytes32 constant LIB_ADDRESS_SLOT = keccak256("TestUtils.TestEnergyUtils");

  modifier asWorld() {
    TestUtils.asWorld(LIB_ADDRESS_SLOT);
    _;
  }

  // Hack to be able to access the library address until we figure out why mud doesn't allow it
  function init(address libAddress) public {
    TestUtils.init(LIB_ADDRESS_SLOT, libAddress);
  }

  function updateEnergyLevel(EntityId entityId) public asWorld returns (EnergyData memory) {
    return _updateEnergyLevel(entityId);
  }
}

library TestForceFieldUtils {
  bytes32 constant LIB_ADDRESS_SLOT = keccak256("TestUtils.TestForceFieldUtils");

  modifier asWorld() {
    TestUtils.asWorld(LIB_ADDRESS_SLOT);
    _;
  }

  // Hack to be able to access the library address until we figure out why mud doesn't allow it
  function init(address libAddress) public {
    TestUtils.init(LIB_ADDRESS_SLOT, libAddress);
  }

  function isForceFieldActive(EntityId forceFieldEntityId) public asWorld returns (bool) {
    return _isForceFieldActive(forceFieldEntityId);
  }

  function isForceFieldShard(EntityId forceFieldEntityId, Vec3 shardCoord) public asWorld returns (bool) {
    return _isForceFieldShard(forceFieldEntityId, shardCoord);
  }

  function getForceField(Vec3 coord) public asWorld returns (EntityId) {
    return _getForceField(coord);
  }

  function setupForceField(EntityId forceFieldId, Vec3 coord) public asWorld {
    _setupForceField(forceFieldId, coord);
  }

  function computeBoundaryShards(EntityId forceFieldId, Vec3 from, Vec3 to) public asWorld returns (Vec3[] memory) {
    return _computeBoundaryShards(forceFieldId, from, to);
  }
}
