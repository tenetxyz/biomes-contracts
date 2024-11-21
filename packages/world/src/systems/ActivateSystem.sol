// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";

import { IN_MAINTENANCE } from "../Constants.sol";
import { PlayerObjectID, NullObjectTypeId } from "../ObjectTypeIds.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";

contract ActivateSystem is System {
  function activate(bytes32 entityId) public {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");

    require(entityId != bytes32(0), "ActivateSystem: entity does not exist");
    uint8 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId != NullObjectTypeId, "ActivateSystem: entity has no object type");

    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;
    if (objectTypeId == PlayerObjectID) {
      requireValidPlayer(ReversePlayer._get(baseEntityId));
    } else {
      // if there's no chip, it'll just do nothing
      updateChipBatteryLevel(baseEntityId);
    }
  }

  function activatePlayer(address player) public {
    requireValidPlayer(player);
  }
}
