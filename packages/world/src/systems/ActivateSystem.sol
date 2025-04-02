// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Player } from "../codegen/tables/Player.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";

import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { checkWorldStatus } from "../Utils.sol";
import { updateMachineEnergy, updatePlayerEnergy } from "../utils/EnergyUtils.sol";

import { EntityId } from "../EntityId.sol";

contract ActivateSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function activate(EntityId entityId) public {
    checkWorldStatus();

    require(entityId.exists(), "Entity does not exist");
    EntityId base = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(base);
    require(!objectTypeId.isNull(), "Entity has no object type");

    if (objectTypeId == ObjectTypes.Player) {
      updatePlayerEnergy(base);
    } else {
      // if there's no program, it'll just do nothing
      updateMachineEnergy(base);
    }
  }

  function activatePlayer(address playerAddress) public {
    EntityId player = Player._get(playerAddress);
    player = player.baseEntityId();
    require(player.exists(), "Entity does not exist");
    ObjectTypeId objectTypeId = ObjectType._get(player);
    require(objectTypeId == ObjectTypes.Player, "Entity is not player");
    updatePlayerEnergy(player);
  }
}
