// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { TerrainLib } from "../systems/libraries/TerrainLib.sol";
import { MovablePosition, Position, ReverseMovablePosition, ReversePosition } from "../utils/Vec3Storage.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { getUniqueEntity } from "../Utils.sol";

import { Vec3 } from "../Vec3.sol";

using ObjectTypeLib for ObjectTypeId;

/// @notice Get the object type id at a given coordinate.
/// @dev Returns ObjectTypes.Null if the chunk is not explored yet.
function getObjectTypeIdAt(Vec3 coord) view returns (ObjectTypeId) {
  EntityId entityId = ReversePosition._get(coord);
  return entityId.exists() ? ObjectType._get(entityId) : TerrainLib._getBlockType(coord);
}

/// @notice Get the object type id at a given coordinate.
/// @dev Reverts if the chunk is not explored yet.
function safeGetObjectTypeIdAt(Vec3 coord) view returns (ObjectTypeId) {
  ObjectTypeId objectTypeId = getObjectTypeIdAt(coord);
  require(!objectTypeId.isNull(), "Chunk not explored yet");
  return objectTypeId;
}

function getEntityAt(Vec3 coord) view returns (EntityId, ObjectTypeId) {
  EntityId entityId = ReversePosition._get(coord);
  ObjectTypeId objectTypeId;
  if (!entityId.exists()) {
    objectTypeId = TerrainLib._getBlockType(coord);
    require(!objectTypeId.isNull(), "Chunk not explored yet");
  } else {
    objectTypeId = ObjectType._get(entityId);
  }

  return (entityId, objectTypeId);
}

function getOrCreateEntityAt(Vec3 coord) returns (EntityId, ObjectTypeId) {
  EntityId entityId = ReversePosition._get(coord);
  ObjectTypeId objectTypeId;
  if (!entityId.exists()) {
    objectTypeId = TerrainLib._getBlockType(coord);
    require(!objectTypeId.isNull(), "Chunk not explored yet");

    entityId = createEntityAt(coord, objectTypeId);
  } else {
    objectTypeId = ObjectType._get(entityId);
  }

  return (entityId, objectTypeId);
}

function createEntityAt(Vec3 coord, ObjectTypeId objectTypeId) returns (EntityId) {
  EntityId entityId = createEntity(objectTypeId);
  Position._set(entityId, coord);
  ReversePosition._set(coord, entityId);
  return entityId;
}

function createEntity(ObjectTypeId objectType) returns (EntityId) {
  EntityId entityId = getUniqueEntity();
  ObjectType._set(entityId, objectType);
  uint128 mass = ObjectTypeMetadata._getMass(objectType);
  if (mass > 0) {
    Mass._setMass(entityId, mass);
  }

  return entityId;
}

function getMovableEntityAt(Vec3 coord) view returns (EntityId) {
  return ReverseMovablePosition._get(coord);
}

function setMovableEntityAt(Vec3 coord, EntityId entityId) {
  MovablePosition._set(entityId, coord);
  ReverseMovablePosition._set(coord, entityId);
}
