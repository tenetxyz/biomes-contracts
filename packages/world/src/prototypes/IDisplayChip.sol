// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IChip } from "./IChip.sol";

import { DisplayContent } from "../Types.sol";

// Interface for a display chip
interface IDisplayChip is IChip {
  function getDisplayContent(bytes32 entityId) external view returns (DisplayContent memory);
}
