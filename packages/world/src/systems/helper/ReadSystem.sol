// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Vec3, vec3 } from "../../Vec3.sol";
import { ObjectTypeId } from "../../ObjectTypeId.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";
import { PlayerStatus } from "../../codegen/tables/PlayerStatus.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { InventoryCount } from "../../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";

import { Position, PlayerPosition, ReversePosition, ReversePlayerPosition } from "../../utils/Vec3Storage.sol";

import { getEntityInventory } from "../../utils/ReadUtils.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { InventoryObject, EntityData } from "../../Types.sol";
import { EntityId } from "../../EntityId.sol";
import { TerrainLib } from "../libraries/TerrainLib.sol";

// Public getters so clients can read the world state more easily
contract ReadSystem is System {
  function getEntityIdAtCoord(Vec3 coord) public view returns (EntityId) {
    return ReversePosition._get(coord);
  }

  function getEntityData(EntityId entityId) public view returns (EntityData memory) {
    if (!entityId.exists()) {
      return
        EntityData({
          objectTypeId: ObjectTypes.Null,
          entityId: EntityId.wrap(0),
          baseEntityId: EntityId.wrap(0),
          inventory: new InventoryObject[](0),
          position: vec3(0, 0, 0)
        });
    }

    EntityId baseEntityId = entityId.baseEntityId();

    return
      EntityData({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        baseEntityId: baseEntityId,
        inventory: getInventory(baseEntityId),
        position: getCoordForEntityId(entityId)
      });
  }

  function getEntityDataAtCoord(Vec3 coord) public view returns (EntityData memory) {
    EntityId entityId = ReversePosition._get(coord);
    if (!entityId.exists()) {
      return
        EntityData({
          objectTypeId: TerrainLib._getBlockType(coord),
          entityId: EntityId.wrap(0),
          baseEntityId: EntityId.wrap(0),
          inventory: new InventoryObject[](0),
          position: coord
        });
    }

    EntityId baseEntityId = entityId.baseEntityId();

    return
      EntityData({
        objectTypeId: ObjectType._get(entityId),
        entityId: entityId,
        baseEntityId: baseEntityId,
        inventory: getInventory(baseEntityId),
        position: coord
      });
  }

  function getMultipleEntityDataAtCoord(Vec3[] memory coord) public view returns (EntityData[] memory) {
    EntityData[] memory entityData = new EntityData[](coord.length);
    for (uint256 i = 0; i < coord.length; i++) {
      entityData[i] = getEntityDataAtCoord(coord[i]);
    }
    return entityData;
  }

  function getLastActivityTime(address player) public view returns (uint256) {
    EntityId playerEntityId = Player._get(player);
    if (PlayerStatus._getBedEntityId(playerEntityId).exists()) {
      return 0;
    }
    return PlayerActivity._get(playerEntityId);
  }

  function getInventory(address player) public view returns (InventoryObject[] memory) {
    EntityId playerEntityId = Player._get(player);
    require(playerEntityId.exists(), "Player not found");
    return getInventory(playerEntityId);
  }

  function getInventory(EntityId entityId) public view returns (InventoryObject[] memory) {
    return getEntityInventory(entityId);
  }

  function getCoordForEntityId(EntityId entityId) public view returns (Vec3) {
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    if (objectTypeId == ObjectTypes.Player) {
      EntityId bedEntityId = PlayerStatus._getBedEntityId(entityId);
      if (bedEntityId.exists()) {
        return Position._get(bedEntityId);
      } else {
        return PlayerPosition._get(entityId);
      }
    } else {
      return Position._get(entityId);
    }
  }

  function getPlayerCoord(address player) public view returns (Vec3) {
    EntityId playerEntityId = Player._get(player);
    require(playerEntityId.exists(), "Player not found");
    return getCoordForEntityId(playerEntityId);
  }
}
