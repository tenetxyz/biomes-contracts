// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCubeIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { LastKnownPosition } from "../codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";
import { ActionType } from "../codegen/common.sol";

import { MAX_PLAYER_RESPAWN_HALF_WIDTH, IN_MAINTENANCE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { lastKnownPositionDataToVoxelCoord, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";

contract LoginSystem is System {
  function placePlayerAtCoord(
    bytes32 basePlayerEntityId,
    bytes32 playerEntityId,
    VoxelCoord memory respawnCoord
  ) internal returns (bytes32) {
    require(inWorldBorder(respawnCoord), "LoginSystem: cannot respawn outside world border");

    bytes32 respawnEntityId = ReversePosition._get(respawnCoord.x, respawnCoord.y, respawnCoord.z);
    if (respawnEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(respawnCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "LoginSystem: cannot respawn on terrain non-air block"
      );
    } else {
      require(ObjectType._get(respawnEntityId) == AirObjectID, "LoginSystem: cannot respawn on non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(respawnEntityId, basePlayerEntityId, PlayerObjectID);

      Position._deleteRecord(respawnEntityId);
    }

    Position._set(playerEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition._set(respawnCoord.x, respawnCoord.y, respawnCoord.z, playerEntityId);

    return respawnEntityId;
  }

  function loginPlayer(VoxelCoord memory respawnCoord) public {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "Player does not exist");
    require(PlayerMetadata._getIsLoggedOff(playerEntityId), "LoginSystem: player already logged in");

    VoxelCoord memory lastKnownCoord = lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(playerEntityId));
    require(
      inSurroundingCubeIgnoreY(lastKnownCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH, respawnCoord),
      "LoginSystem: respawn coord too far from last known position"
    );

    placePlayerAtCoord(playerEntityId, playerEntityId, respawnCoord);
    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        respawnCoord.x + schemaData.relativePositionsX[i],
        respawnCoord.y + schemaData.relativePositionsY[i],
        respawnCoord.z + schemaData.relativePositionsZ[i]
      );
      bytes32 newRelativeEntityId = getUniqueEntity();
      placePlayerAtCoord(playerEntityId, newRelativeEntityId, relativeCoord);
      ObjectType._set(newRelativeEntityId, PlayerObjectID);
      BaseEntity._set(newRelativeEntityId, playerEntityId);
    }

    LastKnownPosition._deleteRecord(playerEntityId);
    PlayerMetadata._setIsLoggedOff(playerEntityId, false);

    uint256 timeSinceLogoff = block.timestamp - PlayerActivity._get(playerEntityId);
    // After a grace period of 5 days, the player loses 75% of their XP every day
    uint256 daysSinceLogoff = timeSinceLogoff / 1 days;
    if (daysSinceLogoff > 5) {
      uint256 newXP = ExperiencePoints._get(playerEntityId);
      for (uint256 i = 0; i < daysSinceLogoff - 5; i++) {
        newXP = (newXP * 3) / 4;
      }
      ExperiencePoints._set(playerEntityId, newXP);
    }

    PlayerActivity._set(playerEntityId, block.timestamp);

    // Reset update time to current time
    Health._setLastUpdatedTime(playerEntityId, block.timestamp);
    Stamina._setLastUpdatedTime(playerEntityId, block.timestamp);

    // We let the user pick a y coord, so we need to apply gravity
    (bool gravityApplies, ) = gravityApplies(respawnCoord);
    require(!gravityApplies, "LoginSystem: cannot respawn player with gravity");

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
