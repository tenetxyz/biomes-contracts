// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { Vec3, vec3 } from "../../Vec3.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { Direction } from "../../codegen/common.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { EntityProgram } from "../../codegen/tables/EntityProgram.sol";
import { Equipped } from "../../codegen/tables/Equipped.sol";

import { InventoryCount } from "../../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../../codegen/tables/InventoryObjects.sol";
import { Machine, MachineData } from "../../codegen/tables/Machine.sol";
import { Mass } from "../../codegen/tables/Mass.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";

import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { Orientation } from "../../codegen/tables/Orientation.sol";
import { Player } from "../../codegen/tables/Player.sol";
import { PlayerStatus } from "../../codegen/tables/PlayerStatus.sol";

import { MovablePosition, Position, ReverseMovablePosition, ReversePosition } from "../../utils/Vec3Storage.sol";

import { EntityId } from "../../EntityId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { EntityData, InventoryObject, PlayerEntityData, getEntityInventory } from "../../utils/ReadUtils.sol";

import { TerrainLib } from "../libraries/TerrainLib.sol";

// Public getters so clients can read the world state more easily
contract ReadSystem is System {
  function getCoordFor(EntityId entityId) internal view returns (Vec3) {
    ObjectTypeId objectTypeId = ObjectType._get(entityId);
    if (objectTypeId == ObjectTypes.Player) {
      EntityId bed = PlayerStatus._getBedEntityId(entityId);
      if (bed.exists()) {
        return Position._get(bed);
      } else {
        return MovablePosition._get(entityId);
      }
    } else {
      return entityId.getPosition();
    }
  }

  function getEntityData(EntityId entityId) public view returns (EntityData memory) {
    if (!entityId.exists()) {
      return EntityData({
        entityId: EntityId.wrap(0),
        baseEntityId: EntityId.wrap(0),
        objectTypeId: ObjectTypes.Null,
        inventory: new InventoryObject[](0),
        position: vec3(0, 0, 0),
        orientation: Direction.PositiveX,
        programSystemId: ResourceId.wrap(0),
        mass: 0,
        energy: EnergyData({ energy: 0, lastUpdatedTime: 0, drainRate: 0 }),
        machine: MachineData({ createdAt: 0, depletedTime: 0 })
      });
    }

    EntityId rawBase = BaseEntity._get(entityId);
    EntityId base = rawBase.exists() ? rawBase : entityId;

    return EntityData({
      entityId: entityId,
      baseEntityId: rawBase,
      objectTypeId: ObjectType._get(entityId),
      position: getCoordFor(entityId),
      orientation: Orientation._get(base),
      inventory: getEntityInventory(base),
      programSystemId: EntityProgram._get(base).toResourceId(),
      mass: Mass._get(base),
      energy: Energy._get(base),
      machine: Machine._get(base)
    });
  }

  function getEntityDataAtCoord(Vec3 coord) public view returns (EntityData memory) {
    EntityId entityId = ReversePosition._get(coord);
    if (!entityId.exists()) {
      return EntityData({
        entityId: EntityId.wrap(0),
        baseEntityId: EntityId.wrap(0),
        objectTypeId: TerrainLib._getBlockType(coord),
        inventory: new InventoryObject[](0),
        position: coord,
        orientation: Direction.PositiveX,
        programSystemId: ResourceId.wrap(0),
        mass: 0,
        energy: EnergyData({ energy: 0, lastUpdatedTime: 0, drainRate: 0 }),
        machine: MachineData({ createdAt: 0, depletedTime: 0 })
      });
    }

    EntityId rawBase = BaseEntity._get(entityId);
    EntityId base = rawBase.exists() ? rawBase : entityId;

    return EntityData({
      entityId: entityId,
      baseEntityId: rawBase,
      objectTypeId: ObjectType._get(entityId),
      position: coord,
      orientation: Orientation._get(base),
      inventory: getEntityInventory(base),
      programSystemId: EntityProgram._get(base).toResourceId(),
      mass: Mass._get(base),
      energy: Energy._get(base),
      machine: Machine._get(base)
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
      return PlayerEntityData({
        playerAddress: player,
        bed: EntityId.wrap(0),
        equipped: EntityId.wrap(0),
        entityData: getEntityData(entityId)
      });
    }

    return PlayerEntityData({
      playerAddress: player,
      bed: PlayerStatus._getBedEntityId(entityId),
      equipped: Equipped._get(entityId),
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
