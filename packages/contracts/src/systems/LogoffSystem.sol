// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MIN_TIME_TO_LOGOFF_AFTER_HIT, MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord } from "../Utils.sol";
import { useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract LogoffSystem is System {
  function logoffPlayer() public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "LogoffSystem: player does not exist");
    uint256 lastHitTime = PlayerMetadata._getLastHitTime(playerEntityId);
    require(
      block.timestamp - lastHitTime > MIN_TIME_TO_LOGOFF_AFTER_HIT,
      "LogoffSystem: player needs to wait before logging off as they were recently hit"
    );
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "LogoffSystem: player isn't logged in");

    VoxelCoord memory coord = positionDataToVoxelCoord(Position._get(playerEntityId));
    LastKnownPosition._set(playerEntityId, coord.x, coord.y, coord.z);
    Position._deleteRecord(playerEntityId);
    PlayerMetadata._setIsLoggedOff(playerEntityId, true);

    // Create air entity at this position
    bytes32 airEntityId = getUniqueEntity();
    ObjectType._set(airEntityId, AirObjectID);
    Position._set(airEntityId, coord.x, coord.y, coord.z);
    ReversePosition._set(coord.x, coord.y, coord.z, airEntityId);
  }
}
