// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";

import { EntityId } from "../EntityId.sol";

// Interface for a chip
interface IChip is IERC165 {
  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable;

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable;
}
