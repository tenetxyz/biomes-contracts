// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { ChipOnTransferData, ChipOnPipeTransferData } from "../Types.sol";
import { IChip } from "./IChip.sol";

// Interface for a chest chip
interface IChestChip is IChip {
  function onTransfer(
    ChipOnTransferData memory transferContext,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onPipeTransfer(
    ChipOnPipeTransferData memory transferContext,
    bytes memory extraData
  ) external payable returns (bool isAllowed);
}
