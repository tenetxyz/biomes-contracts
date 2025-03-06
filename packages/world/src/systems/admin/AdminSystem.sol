// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";

import { addToInventory, removeFromInventory, addToolToInventory, removeToolFromInventory } from "../../utils/InventoryUtils.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypeLib } from "../../ObjectTypeLib.sol";
import { EntityId } from "../../EntityId.sol";
import { getUniqueEntity } from "../../Utils.sol";

contract AdminSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  modifier onlyAdmin() {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    _;
  }

  function adminAddToInventory(
    EntityId ownerEntityId,
    ObjectTypeId objectTypeId,
    uint16 numObjectsToAdd
  ) public onlyAdmin {
    require(!objectTypeId.isTool(), "To add a tool, you must use adminAddToolToInventory");
    addToInventory(ownerEntityId, ObjectType._get(ownerEntityId), objectTypeId, numObjectsToAdd);
  }

  function adminAddToolToInventory(
    EntityId ownerEntityId,
    ObjectTypeId toolObjectTypeId
  ) public onlyAdmin returns (EntityId) {
    return addToolToInventory(ownerEntityId, toolObjectTypeId);
  }

  function adminRemoveFromInventory(
    EntityId ownerEntityId,
    ObjectTypeId objectTypeId,
    uint16 numObjectsToRemove
  ) public onlyAdmin {
    require(!objectTypeId.isTool(), "To remove a tool, you must pass in the tool entity id");
    removeFromInventory(ownerEntityId, objectTypeId, numObjectsToRemove);
  }

  function adminRemoveToolFromInventory(EntityId ownerEntityId, EntityId toolEntityId) public onlyAdmin {
    removeToolFromInventory(ownerEntityId, toolEntityId, ObjectType._get(toolEntityId));
  }
}
