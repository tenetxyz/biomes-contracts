// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
import { IProgram } from "./IProgram.sol";
import { EntityId } from "../EntityId.sol";

// Interface for a force field program
interface ISpawnTileProgram is IProgram {
  function onSpawn(EntityId callerEntityId, EntityId spawnTileEntityId, bytes memory extraData) external payable;
}
