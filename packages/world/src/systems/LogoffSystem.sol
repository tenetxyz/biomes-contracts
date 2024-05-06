// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MIN_TIME_TO_LOGOFF_AFTER_HIT, MIN_TIME_BEFORE_AUTO_LOGOFF, MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getUniqueEntity } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract LogoffSystem is System {
  function logoffCommon(bytes32 playerEntityId) internal {
    uint256 lastHitTime = PlayerMetadata._getLastHitTime(playerEntityId);
    require(
      block.timestamp - lastHitTime > MIN_TIME_TO_LOGOFF_AFTER_HIT,
      "LogoffSystem: player needs to wait before logging off as they were recently hit"
    );
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "LogoffSystem: player isn't logged in");

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

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
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "LogoffSystem: player does not exist");
    logoffCommon(playerEntityId);
  }

  function logoffStalePlayer(address player) public {
    bytes32 playerEntityId = Player._get(player);
    require(playerEntityId != bytes32(0), "LogoffSystem: player does not exist");
    require(
      block.timestamp - PlayerActivity._get(playerEntityId) > MIN_TIME_BEFORE_AUTO_LOGOFF,
      "LogoffSystem: player has recent actions and cannot be logged off automatically"
    );
    logoffCommon(playerEntityId);
  }
}
