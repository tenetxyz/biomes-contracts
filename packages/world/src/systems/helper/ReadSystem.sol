// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { Vec3, vec3 } from "../../Vec3.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { Mass } from "../../codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { Program } from "../../codegen/tables/Program.sol";
import { Equipped } from "../../codegen/tables/Equipped.sol";
import { PlayerStatus } from "../../codegen/tables/PlayerStatus.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { InventoryCount } from "../../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { Orientation } from "../../codegen/tables/Orientation.sol";
import { Direction } from "../../codegen/common.sol";

import { Position, MovablePosition, ReversePosition, ReverseMovablePosition } from "../../utils/Vec3Storage.sol";

import { getEntityInventory } from "../../utils/ReadUtils.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { InventoryObject, EntityData, PlayerEntityData } from "../../Types.sol";
import { EntityId } from "../../EntityId.sol";
import { TerrainLib } from "../libraries/TerrainLib.sol";

// Public getters so clients can read the world state more easily
contract ReadSystem is System {
  function getCoordForEntityId(EntityId entityId) internal view returns (Vec3) {
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    if (objectTypeId == ObjectTypes.Player) {
      EntityId bedEntityId = PlayerStatus._getBedEntityId(entityId);
      if (bedEntityId.exists()) {
        return Position._get(bedEntityId);
      } else {
        return MovablePosition._get(entityId);
      }
    } else {
      return entityId.getPosition();
    }
  }

  function getEntityData(EntityId entityId) public view returns (EntityData memory) {
    if (!entityId.exists()) {
      return
        EntityData({
          entityId: EntityId.wrap(0),
          baseEntityId: EntityId.wrap(0),
          objectTypeId: ObjectTypes.Null,
          inventory: new InventoryObject[](0),
          position: vec3(0, 0, 0),
          orientation: Direction.PositiveX,
          programSystemId: ResourceId.wrap(0),
          mass: 0,
          energy: EnergyData({ energy: 0, lastUpdatedTime: 0, drainRate: 0 })
        });
    }

    EntityId rawBaseEntityId = BaseEntity._get(entityId);
    EntityId baseEntityId = rawBaseEntityId.exists() ? rawBaseEntityId : entityId;

    return
      EntityData({
        entityId: entityId,
        baseEntityId: rawBaseEntityId,
        objectTypeId: ObjectType._get(entityId),
        position: getCoordForEntityId(entityId),
        orientation: Orientation._get(baseEntityId),
        inventory: getEntityInventory(baseEntityId),
        programSystemId: Program._get(baseEntityId),
        mass: Mass._get(baseEntityId),
        energy: Energy._get(baseEntityId)
      });
  }

  function getEntityDataAtCoord(Vec3 coord) public view returns (EntityData memory) {
    EntityId entityId = ReversePosition._get(coord);
    if (!entityId.exists()) {
      return
        EntityData({
          entityId: EntityId.wrap(0),
          baseEntityId: EntityId.wrap(0),
          objectTypeId: TerrainLib._getBlockType(coord),
          inventory: new InventoryObject[](0),
          position: coord,
          orientation: Direction.PositiveX,
          programSystemId: ResourceId.wrap(0),
          mass: 0,
          energy: EnergyData({ energy: 0, lastUpdatedTime: 0, drainRate: 0 })
        });
    }

    EntityId rawBaseEntityId = BaseEntity._get(entityId);
    EntityId baseEntityId = rawBaseEntityId.exists() ? rawBaseEntityId : entityId;

    return
      EntityData({
        entityId: entityId,
        baseEntityId: rawBaseEntityId,
        objectTypeId: ObjectType._get(entityId),
        position: coord,
        orientation: Orientation._get(baseEntityId),
        inventory: getEntityInventory(baseEntityId),
        programSystemId: Program._get(baseEntityId),
        mass: Mass._get(baseEntityId),
        energy: Energy._get(baseEntityId)
      });
  }

  function getMultipleEntityData(EntityId[] memory entityIds) public view returns (EntityData[] memory) {
    EntityData[] memory entityData = new EntityData[](entityIds.length);
    for (uint256 i = 0; i < entityIds.length; i++) {
      entityData[i] = getEntityData(entityIds[i]);
    }
    return entityData;
  }

  function getMultipleEntityDataAtCoord(Vec3[] memory coord) public view returns (EntityData[] memory) {
    EntityData[] memory entityData = new EntityData[](coord.length);
    for (uint256 i = 0; i < coord.length; i++) {
      entityData[i] = getEntityDataAtCoord(coord[i]);
    }
    return entityData;
  }

  function getPlayerEntityData(address player) public view returns (PlayerEntityData memory) {
    EntityId entityId = Player._get(player);
    if (!entityId.exists()) {
      return
        PlayerEntityData({
          playerAddress: player,
          bedEntityId: EntityId.wrap(0),
          equippedEntityId: EntityId.wrap(0),
          entityData: getEntityData(entityId)
        });
    }

    return
      PlayerEntityData({
        playerAddress: player,
        bedEntityId: PlayerStatus._getBedEntityId(entityId),
        equippedEntityId: Equipped._get(entityId),
        entityData: getEntityData(entityId)
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
