// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord } from "../Types.sol";
import { IChip } from "./IChip.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";

// Interface for a force field chip
interface IForceFieldShardChip is IChip {
  function onBuild(
    EntityId targetEntityId,
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable;

  function onMine(
    EntityId targetEntityId,
    EntityId callerEntityId,
    ObjectTypeId objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable;
}
