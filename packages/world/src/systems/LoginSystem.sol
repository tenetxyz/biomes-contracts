// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_RESPAWN_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, gravityApplies, inWorldBorder } from "../Utils.sol";
import { notify, LoginNotifData } from "../utils/NotifUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";

contract LoginSystem is System {
  using VoxelCoordLib for *;

  function loginPlayer(VoxelCoord memory respawnCoord) public {
    checkWorldStatus();
    EntityId playerEntityId = Player._get(_msgSender());
    require(playerEntityId.exists(), "Player does not exist");
    require(PlayerStatus._getIsLoggedOff(playerEntityId), "Player is already logged in");

    VoxelCoord memory lastKnownCoord = LastKnownPosition._get(playerEntityId).toVoxelCoord();
    require(inWorldBorder(respawnCoord), "Cannot respawn outside world border");
    require(
      lastKnownCoord.inSurroundingCube(MAX_PLAYER_RESPAWN_HALF_WIDTH, respawnCoord),
      "Respawn coord too far from logged off coord"
    );

    (, ObjectTypeId respawnObjectTypeId) = respawnCoord.getOrCreateEntity();
    require(
      respawnObjectTypeId == AirObjectID && !respawnCoord.getPlayer().exists(),
      "Cannot respawn on a non-air block"
    );

    respawnCoord.setPlayer(playerEntityId);

    LastKnownPosition._deleteRecord(playerEntityId);
    PlayerStatus._set(playerEntityId, false);

    PlayerActivity._set(playerEntityId, uint128(block.timestamp));

    // TODO: apply cost for being logged off

    // We let the user pick a y coord, so we need to apply gravity
    require(!gravityApplies(respawnCoord), "Cannot respawn player here as gravity applies");

    notify(playerEntityId, LoginNotifData({ loginCoord: respawnCoord }));
  }
}
