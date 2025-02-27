// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
import { VoxelCoord } from "../Types.sol";
import { IChip } from "./IChip.sol";
import { EntityId } from "../EntityId.sol";

// Interface for a force field chip
interface IBedChip is IChip {
  function onSleep(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable;

  function onWakeup(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable;
}
