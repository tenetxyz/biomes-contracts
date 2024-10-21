// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IV1Chip } from "./IV1Chip.sol";

// Interface for a chest chip
interface IChestV1Chip is IV1Chip {
  function onTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed);
}
