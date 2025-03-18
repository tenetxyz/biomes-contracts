// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;
import { IProgram } from "./IProgram.sol";
import { EntityId } from "../EntityId.sol";

// Interface for a force field program
interface IBedProgram is IProgram {
  function onSleep(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable;

  function onWakeup(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable;
}
