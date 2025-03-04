// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel } from "../utils/EnergyUtils.sol";
import { checkWorldStatus } from "../Utils.sol";

import { EntityId } from "../EntityId.sol";

contract ActivateSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function activate(EntityId entityId) public {
    checkWorldStatus();

    require(entityId.exists(), "Entity does not exist");
    EntityId baseEntityId = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    require(!objectTypeId.isNull(), "Entity has no object type");

    if (objectTypeId == ObjectTypes.Player) {
      requireValidPlayer(ReversePlayer._get(baseEntityId));
    } else {
      // if there's no chip, it'll just do nothing
      updateEnergyLevel(baseEntityId);
    }
  }

  function activatePlayer(address player) public {
    requireValidPlayer(player);
  }
}
