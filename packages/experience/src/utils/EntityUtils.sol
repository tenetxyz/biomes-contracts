// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "@biomesaw/world/src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "@biomesaw/world/src/codegen/tables/Player.sol";
import { ReversePlayer } from "@biomesaw/world/src/codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "@biomesaw/world/src/codegen/tables/PlayerStatus.sol";
import { ObjectType } from "@biomesaw/world/src/codegen/tables/ObjectType.sol";
import { Equipped } from "@biomesaw/world/src/codegen/tables/Equipped.sol";
import { InventoryObjects } from "@biomesaw/world/src/codegen/tables/InventoryObjects.sol";
import { InventoryEntity } from "@biomesaw/world/src/codegen/tables/InventoryEntity.sol";
import { ReverseInventoryEntity } from "@biomesaw/world/src/codegen/tables/ReverseInventoryEntity.sol";
import { InventorySlots } from "@biomesaw/world/src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "@biomesaw/world/src/codegen/tables/InventoryCount.sol";

import { Position, ReversePosition } from "@biomesaw/world/src/utils/Vec3Storage.sol";

import { ObjectTypeId } from "@biomesaw/world/src/ObjectTypeIds.sol";
import { ObjectTypes } from "@biomesaw/world/src/ObjectTypes.sol";
import { Vec3 } from "@biomesaw/world/src/Vec3.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

function getObjectTypeAtCoord(Vec3 coord) view returns (ObjectTypeId) {
  EntityId entityId = getEntityAtCoord(coord);

  ObjectTypeId objectTypeId = getObjectType(entityId);

  return objectTypeId;
}

function getPosition(EntityId entityId) view returns (Vec3) {
  return Position.get(entityId);
}

function getObjectType(EntityId entityId) view returns (ObjectTypeId) {
  return ObjectType.get(entityId);
}

function getStackable(ObjectTypeId objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getStackable(objectTypeId);
}

function getEntityFromPlayer(address playerAddress) view returns (EntityId) {
  return Player.getEntityId(playerAddress);
}

function getPlayerFromEntity(EntityId entityId) view returns (address) {
  return ReversePlayer.getPlayer(entityId);
}

function getEquipped(EntityId playerEntityId) view returns (EntityId) {
  return Equipped.get(playerEntityId);
}

function getIsSleeping(EntityId playerEntityId) view returns (bool) {
  return PlayerStatus.getBedEntityId(playerEntityId).exists();
}

function getInventoryEntityIds(EntityId playerEntityId) view returns (bytes32[] memory) {
  return ReverseInventoryEntity.getEntityIds(playerEntityId);
}

function getInventoryObjects(EntityId entityId) view returns (uint16[] memory) {
  return InventoryObjects.getObjectTypeIds(entityId);
}

function getNumInventoryObjects(EntityId entityId) view returns (uint256) {
  return InventoryObjects.lengthObjectTypeIds(entityId);
}

function getCount(EntityId entityId, ObjectTypeId objectTypeId) view returns (uint16) {
  return InventoryCount.getCount(entityId, objectTypeId);
}

function getNumSlotsUsed(EntityId entityId) view returns (uint16) {
  return InventorySlots.getNumSlotsUsed(entityId);
}

function getEntityAtCoord(Vec3 coord) view returns (EntityId) {
  return ReversePosition.get(coord);
}

function numMaxInChest(ObjectTypeId objectTypeId) view returns (uint16) {
  return getStackable(objectTypeId) * ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Chest);
}
