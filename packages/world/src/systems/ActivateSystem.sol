// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { PlayerObjectID, NullObjectTypeId } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";

contract ActivateSystem is System {
  function activate(bytes32 entityId) public {
    require(entityId != bytes32(0), "ActivateSystem: entity does not exist");
    uint8 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId != NullObjectTypeId, "ActivateSystem: entity has no object type");

    if (objectTypeId == PlayerObjectID) {
      require(!PlayerMetadata._getIsLoggedOff(entityId), "ActivateSystem: player isn't logged in");
      VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(entityId));
      regenHealth(entityId);
      regenStamina(entityId, playerCoord);
      PlayerActivity._set(entityId, block.timestamp);
    } else {
      // if there's no chip, it'll just do nothing
      updateChipBatteryLevel(entityId);
    }
  }
}
