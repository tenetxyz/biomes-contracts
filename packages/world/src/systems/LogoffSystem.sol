// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { MIN_TIME_BEFORE_AUTO_LOGOFF } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";

contract LogoffSystem is System {
  function logoffCommon(EntityId playerEntityId, VoxelCoord memory playerCoord) internal {
    LastKnownPosition._set(playerEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    Position._deleteRecord(playerEntityId);
    PlayerStatus._set(playerEntityId, true);

    // Create air entity at this position
    EntityId airEntityId = getUniqueEntity();
    ObjectType._set(airEntityId, AirObjectID);
    Position._set(airEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, airEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Logoff,
        entityId: playerEntityId,
        objectTypeId: PlayerObjectID,
        coordX: playerCoord.x,
        coordY: playerCoord.y,
        coordZ: playerCoord.z,
        amount: 1
      })
    );
  }

  function logoffPlayer() public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    logoffCommon(playerEntityId, playerCoord);
  }

  function logoffStalePlayer(address player) public {
    // Note: We need to check PlayerActivity before calling requireValidPlayer
    // as requireValidPlayer will set the PlayerActivity timestamp to the current block timestamp
    require(
      block.timestamp - PlayerActivity._get(Player._get(player)) > MIN_TIME_BEFORE_AUTO_LOGOFF,
      "Player has recent actions and cannot be logged off"
    );
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(player);
    logoffCommon(playerEntityId, playerCoord);
  }
}
