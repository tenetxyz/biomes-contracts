// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { MIN_TIME_TO_LOGOFF_AFTER_HIT, MIN_TIME_BEFORE_AUTO_LOGOFF } from "../Constants.sol";
import { AirObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

contract LogoffSystem is System {
  function logoffCommon(bytes32 playerEntityId, VoxelCoord memory playerCoord) internal {
    uint256 lastHitTime = PlayerMetadata._getLastHitTime(playerEntityId);
    require(
      block.timestamp - lastHitTime > MIN_TIME_TO_LOGOFF_AFTER_HIT,
      "LogoffSystem: player needs to wait before logging off as they were recently hit"
    );

    PlayerActivity._set(playerEntityId, block.timestamp);
    LastKnownPosition._set(playerEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    Position._deleteRecord(playerEntityId);
    PlayerMetadata._setIsLoggedOff(playerEntityId, true);

    // Create air entity at this position
    bytes32 airEntityId = getUniqueEntity();
    ObjectType._set(airEntityId, AirObjectID);
    Position._set(airEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, airEntityId);
  }

  function logoffPlayer() public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    logoffCommon(playerEntityId, playerCoord);
  }

  function logoffStalePlayer(address player) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(player);
    require(
      block.timestamp - PlayerActivity._get(playerEntityId) > MIN_TIME_BEFORE_AUTO_LOGOFF,
      "LogoffSystem: player has recent actions and cannot be logged off"
    );
    logoffCommon(playerEntityId, playerCoord);
  }
}
