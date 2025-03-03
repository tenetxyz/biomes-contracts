// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Position, ReversePosition, PlayerPosition, ReversePlayerPosition } from "../utils/Vec3Storage.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { TerrainLib } from "../systems/libraries/TerrainLib.sol";

import { getUniqueEntity } from "../Utils.sol";
import { ObjectTypeId, ObjectTypes.Air, ObjectTypes.Player } from "../ObjectTypeIds.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

function getObjectTypeIdAt(Vec3 coord) view returns (ObjectTypeId) {
  EntityId entityId = ReversePosition._get(coord);
  if (!entityId.exists()) {
    return ObjectTypeId.wrap(TerrainLib._getBlockType(coord));
  }
  return ObjectType._get(entityId);
}

function getOrCreateEntityAt(Vec3 coord) returns (EntityId, ObjectTypeId) {
  EntityId entityId = ReversePosition._get(coord);
  ObjectTypeId objectTypeId;
  if (!entityId.exists()) {
    // TODO: move wrapping to TerrainLib?
    objectTypeId = ObjectTypeId.wrap(TerrainLib._getBlockType(coord));

    entityId = getUniqueEntity();
    Position._set(entityId, coord);
    ReversePosition._set(coord, entityId);
    ObjectType._set(entityId, objectTypeId);
    // We assume all terrain blocks are only 1 voxel (no relative entities)
    uint32 mass = ObjectTypeMetadata._getMass(objectTypeId);
    if (mass > 0) {
      Mass._setMass(entityId, mass);
    }
  } else {
    objectTypeId = ObjectType._get(entityId);
  }

  return (entityId, objectTypeId);
}

function getPlayer(Vec3 coord) view returns (EntityId) {
  return ReversePlayerPosition._get(coord);
}

function setPlayer(Vec3 coord, EntityId playerEntityId) {
  PlayerPosition._set(playerEntityId, coord);
  ReversePlayerPosition._set(coord, playerEntityId);
}
