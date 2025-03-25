// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerPosition, ReversePlayerPosition } from "../../utils/Vec3Storage.sol";
import { Vec3, vec3 } from "../../Vec3.sol";

import { addToInventory, removeFromInventory, addToolToInventory, removeToolFromInventory } from "../../utils/InventoryUtils.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypeLib } from "../../ObjectTypeLib.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { EntityId } from "../../EntityId.sol";
import { getUniqueEntity } from "../../Utils.sol";
import { MoveLib } from "../libraries/MoveLib.sol";
import { PlayerUtils } from "../../utils/PlayerUtils.sol";
import { safeGetObjectTypeIdAt, getPlayer, setPlayer } from "../../utils/EntityUtils.sol";

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

  function adminTeleportPlayer(address player, Vec3 finalCoord) public onlyAdmin {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(player);

    Vec3[] memory playerCoords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    EntityId[] memory playerEntityIds = MoveLib._getPlayerEntityIds(playerEntityId, playerCoords);
    require(!MoveLib._gravityApplies(finalCoord), "Cannot teleport here as gravity applies");

    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReversePlayerPosition._deleteRecord(playerCoords[i]);
    }

    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(finalCoord);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      Vec3 newCoord = newPlayerCoords[i];

      ObjectTypeId newObjectTypeId = safeGetObjectTypeIdAt(newCoord);
      require(ObjectTypeMetadata._getCanPassThrough(newObjectTypeId), "Cannot teleport to a non-passable block");
      require(!getPlayer(newCoord).exists(), "Cannot teleport where a player already exists");

      setPlayer(newCoord, playerEntityIds[i]);
    }
  }
}
