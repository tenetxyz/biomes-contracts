// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";

import { PlayerObjectID, NullObjectTypeId } from "../ObjectTypeIds.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";

contract ActivateSystem is System {
  function activate(bytes32 entityId) public {
    require(entityId != bytes32(0), "ActivateSystem: entity does not exist");
    uint8 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId != NullObjectTypeId, "ActivateSystem: entity has no object type");

    if (objectTypeId == PlayerObjectID) {
      requireValidPlayer(ReversePlayer._get(entityId));
    } else {
      // if there's no chip, it'll just do nothing
      updateChipBatteryLevel(entityId);
    }
  }
}
