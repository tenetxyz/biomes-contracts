// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";

import { ObjectTypeId, PlayerObjectID, NullObjectTypeId } from "../ObjectTypeIds.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel } from "../utils/EnergyUtils.sol";
import { checkWorldStatus } from "../Utils.sol";

import { EntityId } from "../EntityId.sol";

contract ActivateSystem is System {
  function activate(EntityId entityId) public {
    checkWorldStatus();

    require(entityId.exists(), "Entity does not exist");
    EntityId baseEntityId = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    require(!objectTypeId.isNull(), "Entity has no object type");

    if (objectTypeId == PlayerObjectID) {
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
