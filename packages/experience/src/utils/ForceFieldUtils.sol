// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "@biomesaw/world/src/Vec3.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ForceField } from "@biomesaw/world/src/utils/Vec3Storage.sol";

import { getPosition } from "./EntityUtils.sol";

function getForceField(EntityId entityId) view returns (EntityId) {
  Vec3 coord = getPosition(entityId);
  Vec3 shardCoord = coord.toForceFieldShardCoord();
  return ForceField.get(shardCoord);
}
