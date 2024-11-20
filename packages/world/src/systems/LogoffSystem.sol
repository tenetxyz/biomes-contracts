// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";

import { MIN_TIME_TO_LOGOFF_AFTER_HIT, MIN_TIME_BEFORE_AUTO_LOGOFF } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity } from "../Utils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

contract LogoffSystem is System {
  function removePlayerFromCoord(bytes32 playerEntityId, VoxelCoord memory playerCoord) internal {
    Position._deleteRecord(playerEntityId);

    // Create air entity at this position
    bytes32 airEntityId = getUniqueEntity();
    ObjectType._set(airEntityId, AirObjectID);
    Position._set(airEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, airEntityId);
  }

  function logoffCommon(bytes32 playerEntityId, VoxelCoord memory playerCoord) internal {
    uint256 lastHitTime = PlayerMetadata._getLastHitTime(playerEntityId);
    require(
      block.timestamp - lastHitTime > MIN_TIME_TO_LOGOFF_AFTER_HIT,
      "LogoffSystem: player needs to wait before logging off as they were recently hit"
    );
    LastKnownPosition._set(playerEntityId, playerCoord.x, playerCoord.y, playerCoord.z);
    PlayerMetadata._setIsLoggedOff(playerEntityId, true);

    removePlayerFromCoord(playerEntityId, playerCoord);

    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        playerCoord.x + schemaData.relativePositionsX[i],
        playerCoord.y + schemaData.relativePositionsY[i],
        playerCoord.z + schemaData.relativePositionsZ[i]
      );
      bytes32 relativeEntityId = ReversePosition._get(relativeCoord.x, relativeCoord.y, relativeCoord.z);
      require(BaseEntity._get(relativeEntityId) == playerEntityId, "LogoffSystem: relative entity id mismatch");
      removePlayerFromCoord(relativeEntityId, relativeCoord);
    }

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
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    logoffCommon(playerEntityId, playerCoord);
  }

  function logoffStalePlayer(address player) public {
    // Note: We need to check PlayerActivity before calling requireValidPlayer
    // as requireValidPlayer will set the PlayerActivity timestamp to the current block timestamp
    require(
      block.timestamp - PlayerActivity._get(Player._get(player)) > MIN_TIME_BEFORE_AUTO_LOGOFF,
      "LogoffSystem: player has recent actions and cannot be logged off"
    );
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(player);
    logoffCommon(playerEntityId, playerCoord);
  }
}
