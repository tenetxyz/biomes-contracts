// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { Vm } from "forge-std/Vm.sol";
import { console } from "forge-std/console.sol";

import { EntityId } from "../../src/EntityId.sol";
import { Vec3 } from "../../src/Vec3.sol";

import { EnergyData } from "../../src/codegen/tables/Energy.sol";

import { InventorySlot } from "../../src/codegen/tables/InventorySlot.sol";
import { InventoryTypeSlots } from "../../src/codegen/tables/InventoryTypeSlots.sol";
import { ObjectType } from "../../src/codegen/tables/ObjectType.sol";

import { ObjectTypeId } from "../../src/ObjectTypeId.sol";

import { ObjectAmount, ObjectTypeLib, getOreObjectTypes } from "../../src/ObjectTypeLib.sol";
import {
  updateMachineEnergy as _updateMachineEnergy,
  updatePlayerEnergy as _updatePlayerEnergy
} from "../../src/utils/EnergyUtils.sol";

import { createEntity } from "../../src/utils/EntityUtils.sol";
import {
  destroyForceField as _destroyForceField,
  getForceField as _getForceField,
  isForceFieldActive as _isForceFieldActive,
  isForceFieldFragment as _isForceFieldFragment,
  setupForceField as _setupForceField
} from "../../src/utils/ForceFieldUtils.sol";
import { InventoryUtils } from "../../src/utils/InventoryUtils.sol";

Vm constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

using ObjectTypeLib for ObjectTypeId;

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
        case 1 { return(dataOffset, dataSize) }
        default { revert(dataOffset, dataSize) }
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

  function addObject(EntityId ownerEntityId, ObjectTypeId objectTypeId, uint16 numObjectsToAdd) public asWorld {
    InventoryUtils.addObject(ownerEntityId, objectTypeId, numObjectsToAdd);
  }

  function addEntity(EntityId ownerEntityId, ObjectTypeId toolObjectTypeId) public asWorld returns (EntityId) {
    EntityId entityId = createEntity(toolObjectTypeId);
    InventoryUtils.addEntity(ownerEntityId, entityId);
    return entityId;
  }

  function removeFromInventory(EntityId ownerEntityId, ObjectTypeId objectTypeId, uint16 numObjectsToRemove)
    public
    asWorld
  {
    InventoryUtils.removeObject(ownerEntityId, objectTypeId, numObjectsToRemove);
  }

  function transferAll(EntityId fromEntityId, EntityId toEntityId) public asWorld {
    InventoryUtils.transferAll(fromEntityId, toEntityId);
  }

  function getEntitySlot(EntityId owner, EntityId entityId) public asWorld returns (uint16) {
    ObjectTypeId objectType = ObjectType._get(entityId);
    uint16[] memory slots = InventoryTypeSlots._get(owner, objectType);
    for (uint256 i = 0; i < slots.length; i++) {
      EntityId slotEntityId = InventorySlot._getEntityId(owner, slots[i]);

      if (slotEntityId == entityId) {
        return slots[i];
      }
    }
    revert("Entity not found in owner's inventory");
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

  function updateMachineEnergy(EntityId entityId) public asWorld returns (EnergyData memory, uint128) {
    return _updateMachineEnergy(entityId);
  }

  function updatePlayerEnergy(EntityId entityId) public asWorld returns (EnergyData memory) {
    return _updatePlayerEnergy(entityId);
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

  function isForceFieldFragment(EntityId forceFieldEntityId, Vec3 fragmentCoord) public asWorld returns (bool) {
    return _isForceFieldFragment(forceFieldEntityId, fragmentCoord);
  }

  function getForceField(Vec3 coord) public asWorld returns (EntityId, EntityId) {
    return _getForceField(coord);
  }

  function setupForceField(EntityId forceFieldId, Vec3 coord) public asWorld {
    _setupForceField(forceFieldId, coord);
  }

  function destroyForceField(EntityId forceFieldId) public asWorld {
    _destroyForceField(forceFieldId);
  }
}
