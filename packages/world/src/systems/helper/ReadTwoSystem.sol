// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { staticCallInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../../codegen/tables/LastKnownPosition.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { Health, HealthData } from "../../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";
import { PlayerMetadata, PlayerMetadataData } from "../../codegen/tables/PlayerMetadata.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { InventoryCount } from "../../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { ReverseInventoryTool } from "../../codegen/tables/ReverseInventoryTool.sol";
import { ItemMetadata } from "../../codegen/tables/ItemMetadata.sol";
import { Equipped } from "../../codegen/tables/Equipped.sol";
import { ExperiencePoints } from "../../codegen/tables/ExperiencePoints.sol";

import { getTerrainObjectTypeId, lastKnownPositionDataToVoxelCoord, positionDataToVoxelCoord } from "../../Utils.sol";
import { getEntityInventory } from "../../utils/ReadUtils.sol";
import { InventoryObject, PlayerEntityData } from "../../Types.sol";

import { IReadSystem } from "../../codegen/world/IReadSystem.sol";

// Public getters so clients can read the world state more easily
contract ReadTwoSystem is System {
  function getPlayerEntityData(address player) public view returns (PlayerEntityData memory) {
    bytes32 entityId = Player._get(player);
    if (entityId == bytes32(0)) {
      return
        PlayerEntityData({
          playerAddress: player,
          entityId: bytes32(0),
          position: VoxelCoord(0, 0, 0),
          metadata: PlayerMetadataData({ isLoggedOff: false, lastHitTime: 0 }),
          equippedEntityId: bytes32(0),
          inventory: new InventoryObject[](0),
          health: HealthData({ health: 0, lastUpdatedTime: 0 }),
          stamina: StaminaData({ stamina: 0, lastUpdatedTime: 0 }),
          xp: 0,
          lastActionTime: 0
        });
    }

    PlayerMetadataData memory metadata = PlayerMetadata._get(entityId);
    VoxelCoord memory playerPos = metadata.isLoggedOff
      ? lastKnownPositionDataToVoxelCoord(LastKnownPosition._get(entityId))
      : positionDataToVoxelCoord(Position._get(entityId));

    return
      PlayerEntityData({
        playerAddress: player,
        entityId: entityId,
        position: playerPos,
        metadata: metadata,
        equippedEntityId: Equipped._get(entityId),
        inventory: getEntityInventory(entityId),
        health: Health._get(entityId),
        stamina: Stamina._get(entityId),
        xp: ExperiencePoints._get(entityId),
        lastActionTime: PlayerActivity._get(entityId)
      });
  }

  function getPlayersEntityData(address[] memory players) public view returns (PlayerEntityData[] memory) {
    PlayerEntityData[] memory playersEntityData = new PlayerEntityData[](players.length);
    for (uint256 i = 0; i < players.length; i++) {
      playersEntityData[i] = getPlayerEntityData(players[i]);
    }
    return playersEntityData;
  }
}
