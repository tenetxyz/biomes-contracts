// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";

import { ForceField } from "../codegen/tables/ForceField.sol";

import { EntityId } from "../EntityId.sol";

function getForceField(Vec3 coord) view returns (EntityId) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  return ForceField._get(shardCoord);
}

function setupForceField(EntityId forceFieldEntityId, Vec3 coord) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceField._set(shardCoord, forceFieldEntityId);
}

function destroyForceField(EntityId forceFieldEntityId, Vec3 coord) {
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  ForceField._deleteRecord(shardCoord);
}
