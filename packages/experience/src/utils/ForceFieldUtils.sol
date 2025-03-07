// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "@biomesaw/world/src/Vec3.sol";
import { EntityId } from "@biomesaw/world/src/EntityId.sol";

import { ForceFieldFragment, ForceFieldFragmentData } from "@biomesaw/world/src/utils/Vec3Storage.sol";
import { ForceField } from "@biomesaw/world/src/codegen/tables/ForceField.sol";

import { getPosition } from "./EntityUtils.sol";

function getForceField(EntityId entityId) view returns (EntityId) {
  Vec3 coord = getPosition(entityId);
  Vec3 shardCoord = coord.toForceFieldFragmentCoord();
  ForceFieldFragmentData memory shardData = ForceFieldFragment.get(shardCoord);
  if (
    !shardData.forceFieldId.exists() || shardData.forceFieldCreatedAt != ForceField.getCreatedAt(shardData.forceFieldId)
  ) {
    return EntityId.wrap(0);
  }

  return shardData.forceFieldId;
}
