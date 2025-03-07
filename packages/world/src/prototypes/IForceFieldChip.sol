// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";
import { IForceFieldShardChip } from "./IForceFieldShardChip.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";

// Interface for a force field chip
interface IForceFieldChip is IForceFieldShardChip {
  function onPowered(EntityId callerEntityId, EntityId targetEntityId, uint16 numBattery) external;

  function onForceFieldHit(EntityId callerEntityId, EntityId targetEntityId) external;

  function onExpand(EntityId callerEntityId, EntityId targetEntityId) external;

  function onContract(EntityId callerEntityId, EntityId targetEntityId) external;
}
