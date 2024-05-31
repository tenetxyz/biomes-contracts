// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IERC165 } from "@latticexyz/store/src/IERC165.sol";

interface IChestTransferHook is IERC165 {
  function allowTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable returns (bool);
}
