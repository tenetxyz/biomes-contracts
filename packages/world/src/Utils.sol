// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "./Vec3.sol";

import { UniqueEntity } from "./codegen/tables/UniqueEntity.sol";
import { WorldStatus } from "./codegen/tables/WorldStatus.sol";

import { EntityId } from "./EntityId.sol";

function checkWorldStatus() view {
  require(!WorldStatus._getInMaintenance(), "DUST is in maintenance mode. Try again later");
}

function getUniqueEntity() returns (EntityId) {
  uint256 uniqueEntity = UniqueEntity._get() + 1;
  UniqueEntity._set(uniqueEntity);

  return EntityId.wrap(bytes32(uniqueEntity));
}
