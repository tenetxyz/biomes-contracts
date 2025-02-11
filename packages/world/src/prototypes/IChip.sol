// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";

// Interface for a chip
interface IChip is IERC165 {
  function onAttached(
    bytes32 callerEntityId,
    bytes32 targetEntityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onDetached(
    bytes32 callerEntityId,
    bytes32 targetEntityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed);
}
