// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ActionType } from "../codegen/common.sol";

import { MIN_TIME_BEFORE_AUTO_LOGOFF } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { notify, LogoffNotifData } from "../utils/NotifUtils.sol";

import { EntityId } from "../EntityId.sol";

contract LogoffSystem is System {
  function logoffCommon(EntityId playerEntityId, VoxelCoord memory playerCoord) internal {
    LastKnownPosition._set(playerEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    PlayerPosition._deleteRecord(playerEntityId);
    playerCoord.removePlayer();
    PlayerStatus._set(playerEntityId, true);

    notify(playerEntityId, LogoffNotifData({ logoffCoord: playerCoord }));
  }

  function logoffPlayer() public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    logoffCommon(playerEntityId, playerCoord);
  }

  function logoffStalePlayer(address player) public {
    // Note: We need to check PlayerActivity before calling requireValidPlayer
    // as requireValidPlayer will set the PlayerActivity timestamp to the current block timestamp
    require(
      block.timestamp - PlayerActivity._get(Player._get(player)) > MIN_TIME_BEFORE_AUTO_LOGOFF,
      "Player has recent actions and cannot be logged off"
    );
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(player);
    logoffCommon(playerEntityId, playerCoord);
  }
}
