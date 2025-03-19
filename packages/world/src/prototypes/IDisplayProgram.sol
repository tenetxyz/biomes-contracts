// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IProgram } from "./IProgram.sol";

import { DisplayContentData } from "../codegen/tables/DisplayContent.sol";

import { EntityId } from "../EntityId.sol";

// Interface for a display program
interface IDisplayProgram is IProgram {
  function getDisplayContent(EntityId entityId) external view returns (DisplayContentData memory);
}
