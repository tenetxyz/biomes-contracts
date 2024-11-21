// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../codegen/tables/ObjectTypeSchema.sol";

import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, IN_MAINTENANCE } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity, gravityApplies, inWorldBorder, inSpawnArea, getTerrainObjectTypeId } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";

contract SpawnSystem is System {
  function placePlayerAtCoord(bytes32 basePlayerEntityId, VoxelCoord memory coord) internal returns (bytes32) {
    require(inWorldBorder(coord), "SpawnSystem: cannot spawn outside world border");
    require(inSpawnArea(coord), "SpawnSystem: cannot spawn outside spawn area");

    bytes32 playerEntityId = getUniqueEntity();

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "SpawnSystem: cannot spawn on terrain non-air block"
      );
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "SpawnSystem: spawn coord is not air");

      // Transfer any dropped items
      transferAllInventoryEntities(
        entityId,
        basePlayerEntityId == bytes32(0) ? playerEntityId : basePlayerEntityId,
        PlayerObjectID
      );

      Position._deleteRecord(entityId);
    }

    Position._set(playerEntityId, coord.x, coord.y, coord.z);
    ReversePosition._set(coord.x, coord.y, coord.z, playerEntityId);

    ObjectType._set(playerEntityId, PlayerObjectID);

    return playerEntityId;
  }

  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (bytes32) {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    address newPlayer = _msgSender();
    require(Player._get(newPlayer) == bytes32(0), "SpawnSystem: player already exists");

    bytes32 basePlayerEntityId = placePlayerAtCoord(bytes32(0), spawnCoord);
    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        spawnCoord.x + schemaData.relativePositionsX[i],
        spawnCoord.y + schemaData.relativePositionsY[i],
        spawnCoord.z + schemaData.relativePositionsZ[i]
      );
      bytes32 entityId = placePlayerAtCoord(basePlayerEntityId, relativeCoord);
      BaseEntity._set(entityId, basePlayerEntityId);
    }

    Player._set(newPlayer, basePlayerEntityId);
    ReversePlayer._set(basePlayerEntityId, newPlayer);
    Health._set(basePlayerEntityId, block.timestamp, MAX_PLAYER_HEALTH);
    Stamina._set(basePlayerEntityId, block.timestamp, MAX_PLAYER_STAMINA);
    // initial ExperiencePoints is 0

    PlayerActivity._set(basePlayerEntityId, block.timestamp);
    PlayerMetadata._set(basePlayerEntityId, false, 0);

    // We let the user pick a y coord, so we need to apply gravity
    (bool gravityApplies, ) = gravityApplies(spawnCoord);
    require(!gravityApplies, "SpawnSystem: cannot spawn player with gravity");

    PlayerActionNotif._set(
      basePlayerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Spawn,
        entityId: basePlayerEntityId,
        objectTypeId: PlayerObjectID,
        coordX: spawnCoord.x,
        coordY: spawnCoord.y,
        coordZ: spawnCoord.z,
        amount: 1
      })
    );

    return basePlayerEntityId;
  }
}
