// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";

// Interface for a chip
interface IChip is IERC165 {
  function onAttached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onDetached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onPowered(bytes32 playerEntityId, bytes32 entityId, uint16 numBattery) external;

  function onChipHit(bytes32 playerEntityId, bytes32 entityId) external;
}
