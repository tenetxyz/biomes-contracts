// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_RESPAWN_HALF_WIDTH, IN_MAINTENANCE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { lastKnownPositionDataToVoxelCoord, gravityApplies, inWorldBorder } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";

contract LoginSystem is System {
  function loginPlayer(VoxelCoord memory respawnCoord) public {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "Player does not exist");
    require(PlayerStatus._getIsLoggedOff(playerEntityId), "Player is already logged in");

    VoxelCoord memory lastKnownCoord = lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(playerEntityId));
    require(inWorldBorder(respawnCoord), "Cannot respawn outside world border");
    require(
      inSurroundingCube(lastKnownCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH, respawnCoord),
      "Respawn coord too far from logged off coord"
    );

    bytes32 respawnEntityId = ReversePosition._get(respawnCoord.x, respawnCoord.y, respawnCoord.z);
    require(respawnEntityId != bytes32(0), "Cannot respawn on an unrevealed block");
    require(ObjectType._get(respawnEntityId) == AirObjectID, "Cannot respawn on non-air block");

    // Transfer any dropped items
    transferAllInventoryEntities(respawnEntityId, playerEntityId, PlayerObjectID);

    Position._deleteRecord(respawnEntityId);

    Position._set(playerEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition._set(respawnCoord.x, respawnCoord.y, respawnCoord.z, playerEntityId);
    LastKnownPosition._deleteRecord(playerEntityId);
    PlayerStatus._set(playerEntityId, false);

    PlayerActivity._set(playerEntityId, uint128(block.timestamp));

    // TODO: apply cost for being logged off

    // We let the user pick a y coord, so we need to apply gravity
    require(!gravityApplies(respawnCoord), "Cannot respawn player here as gravity applies");

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Login,
        entityId: playerEntityId,
        objectTypeId: PlayerObjectID,
        coordX: respawnCoord.x,
        coordY: respawnCoord.y,
        coordZ: respawnCoord.z,
        amount: 1
      })
    );
  }
}
