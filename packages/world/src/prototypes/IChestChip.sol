// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ChipOnTransferData, ChipOnPipeTransferData } from "../Types.sol";
import { IChip } from "./IChip.sol";

// Interface for a chest chip
interface IChestChip is IChip {
  function onTransfer(ChipOnTransferData memory transferContext) external payable returns (bool isAllowed);

  function onPipeTransfer(ChipOnPipeTransferData memory transferContext) external payable returns (bool isAllowed);
}
