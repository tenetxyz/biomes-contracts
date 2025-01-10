// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { IChip } from "./IChip.sol";

// Interface for a chest chip
interface IChestChip is IChip {
  function onTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) external payable returns (bool isAllowed);

  function onPipeTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) external payable returns (bool isAllowed);
}
