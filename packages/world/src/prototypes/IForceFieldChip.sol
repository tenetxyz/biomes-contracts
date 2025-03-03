// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Vec3 } from "../Vec3.sol";
import { IChip } from "./IChip.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";

// Interface for a force field chip
interface IForceFieldChip is IChip {
  function onBuild(
    EntityId targetEntityId,
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) external payable;

  function onMine(
    EntityId targetEntityId,
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    Vec3 coord,
    bytes memory extraData
  ) external payable;

  function onPowered(EntityId callerEntityId, EntityId targetEntityId, uint16 numBattery) external;

  function onForceFieldHit(EntityId callerEntityId, EntityId targetEntityId) external;
}
