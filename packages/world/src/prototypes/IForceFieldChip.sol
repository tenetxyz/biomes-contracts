// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../Types.sol";
import { IChip } from "./IChip.sol";

import { EntityId } from "../EntityId.sol";

// Interface for a force field chip
interface IForceFieldChip is IChip {
  function onBuild(
    EntityId targetEntityId,
    EntityId callerEntityId,
    uint16 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable;

  function onMine(
    EntityId targetEntityId,
    EntityId callerEntityId,
    uint16 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable;

  function onPowered(EntityId callerEntityId, EntityId targetEntityId, uint16 numBattery) external;

  function onForceFieldHit(EntityId callerEntityId, EntityId targetEntityId) external;
}
