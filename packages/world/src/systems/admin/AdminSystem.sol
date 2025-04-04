// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ROOT_NAMESPACE_ID } from "@latticexyz/world/src/constants.sol";

import { Vec3, vec3 } from "../../Vec3.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { MovablePosition, ReverseMovablePosition } from "../../utils/Vec3Storage.sol";

import { EntityId } from "../../EntityId.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypeLib } from "../../ObjectTypeLib.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { getUniqueEntity } from "../../Utils.sol";

import {
  createEntity, getMovableEntityAt, safeGetObjectTypeIdAt, setMovableEntityAt
} from "../../utils/EntityUtils.sol";
import { InventoryUtils } from "../../utils/InventoryUtils.sol";
import { PlayerUtils } from "../../utils/PlayerUtils.sol";
import { MoveLib } from "../libraries/MoveLib.sol";

contract AdminSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  modifier onlyAdmin() {
    AccessControl.requireOwner(ROOT_NAMESPACE_ID, _msgSender());
    _;
  }

  function adminAddToInventory(EntityId owner, ObjectTypeId objectTypeId, uint16 numObjectsToAdd) public onlyAdmin {
    require(!objectTypeId.isTool(), "To add a tool, you must use adminAddToolToInventory");
    InventoryUtils.addObject(owner, objectTypeId, numObjectsToAdd);
  }

  function adminAddToolToInventory(EntityId owner, ObjectTypeId toolObjectTypeId) public onlyAdmin returns (EntityId) {
    EntityId tool = createEntity(toolObjectTypeId);
    InventoryUtils.addEntity(owner, tool);
    return tool;
  }

  function adminTeleportPlayer(address playerAddress, Vec3 finalCoord) public onlyAdmin {
    EntityId player = Player.get(playerAddress);
    player.activate();

    Vec3[] memory playerCoords = ObjectTypes.Player.getRelativeCoords(player.getPosition());
    EntityId[] memory players = MoveLib._getPlayers(player, playerCoords);
    require(!MoveLib._gravityApplies(finalCoord), "Cannot teleport here as gravity applies");

    for (uint256 i = 0; i < playerCoords.length; i++) {
      ReverseMovablePosition._deleteRecord(playerCoords[i]);
    }

    Vec3[] memory newPlayerCoords = ObjectTypes.Player.getRelativeCoords(finalCoord);
    for (uint256 i = 0; i < newPlayerCoords.length; i++) {
      Vec3 newCoord = newPlayerCoords[i];

      ObjectTypeId newObjectTypeId = safeGetObjectTypeIdAt(newCoord);
      require(ObjectTypeMetadata._getCanPassThrough(newObjectTypeId), "Cannot teleport to a non-passable block");
      require(!getMovableEntityAt(newCoord).exists(), "Cannot teleport where a player already exists");

      setMovableEntityAt(newCoord, players[i]);
    }
  }
}
