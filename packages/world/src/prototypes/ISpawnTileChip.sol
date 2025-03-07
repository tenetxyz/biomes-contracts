// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
import { IChip } from "./IChip.sol";
import { EntityId } from "../EntityId.sol";

// Interface for a force field chip
interface ISpawnTileChip is IChip {
  function onSpawn(EntityId callerEntityId, EntityId spawnTileEntityId, bytes memory extraData) external payable;
}
