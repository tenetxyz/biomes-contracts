// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { ChipBatteryObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { transferInventoryTool, transferInventoryNonTool, addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { safeCallChip } from "../Utils.sol";

import { CHARGE_PER_BATTERY } from "../Constants.sol";

import { IChip } from "../prototypes/IChip.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { ChipOnPipeTransferData, TransferData } from "../Types.sol";
import { isStorageContainer } from "../utils/ObjectTypeUtils.sol";
import { pipeTransferCommon, PipeTransferCommonContext } from "../utils/TransferUtils.sol";

contract PipeTransferSystem is System {
  function requireAllowed(
    ChipData memory checkChipData,
    bool isDeposit,
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) internal {
    if (checkChipData.chipAddress != address(0) && checkChipData.batteryLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(checkChipData.chipAddress).onPipeTransfer{ value: _msgValue() }(
        ChipOnPipeTransferData({
          playerEntityId: bytes32(0), // this is a transfer initiated by a chest, not a player
          targetEntityId: isDeposit ? dstEntityId : srcEntityId,
          callerEntityId: isDeposit ? srcEntityId : dstEntityId,
          isDeposit: isDeposit,
          path: path,
          transferData: TransferData({
            objectTypeId: transferObjectTypeId,
            numToTransfer: numToTransfer,
            toolEntityIds: toolEntityIds
          }),
          extraData: extraData
        })
      );
      require(transferAllowed, "PipeTransferSystem: smart item not authorized by chip to make this transfer");
    }
  }

  function pipeTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    PipeTransferCommonContext memory ctx = pipeTransferCommon(srcEntityId, dstEntityId, path);

    require(!ObjectTypeMetadata._getIsTool(transferObjectTypeId), "PipeTransferSystem: object type is not a block");
    require(numToTransfer > 0, "PipeTransferSystem: amount must be greater than 0");
    removeFromInventoryCount(ctx.baseSrcEntityId, transferObjectTypeId, numToTransfer);

    if (isStorageContainer(ctx.dstObjectTypeId)) {
      addToInventoryCount(ctx.baseDstEntityId, ctx.dstObjectTypeId, transferObjectTypeId, numToTransfer);
    } else if (ctx.dstObjectTypeId == ForceFieldObjectID) {
      require(
        transferObjectTypeId == ChipBatteryObjectID,
        "PipeTransferSystem: force field can only accept chip batteries"
      );
      uint256 newBatteryLevel = ctx.checkChipData.batteryLevel + (uint256(numToTransfer) * CHARGE_PER_BATTERY);

      Chip._setBatteryLevel(ctx.baseDstEntityId, newBatteryLevel);
      Chip._setLastUpdatedTime(ctx.baseDstEntityId, block.timestamp);

      safeCallChip(
        ctx.checkChipData.chipAddress,
        abi.encodeCall(IChip.onPowered, (ctx.baseSrcEntityId, ctx.baseDstEntityId, numToTransfer))
      );
    } else {
      revert("PipeTransferSystem: destination object type is not valid");
    }

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    if (ctx.dstObjectTypeId != ForceFieldObjectID) {
      requireAllowed(
        ctx.checkChipData,
        ctx.isDeposit,
        ctx.baseSrcEntityId,
        ctx.baseDstEntityId,
        path,
        transferObjectTypeId,
        numToTransfer,
        new bytes32[](0),
        extraData
      );
    }
  }

  function pipeTransferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    bytes32 toolEntityId,
    bytes memory extraData
  ) public payable {
    bytes32[] memory toolEntityIds = new bytes32[](1);
    toolEntityIds[0] = toolEntityId;
    pipeTransferTools(srcEntityId, dstEntityId, path, toolEntityIds, extraData);
  }

  function pipeTransferTools(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) public payable {
    require(toolEntityIds.length > 0, "PipeTransferSystem: must transfer at least one tool");
    require(toolEntityIds.length < type(uint16).max, "PipeTransferSystem: too many tools to transfer");

    PipeTransferCommonContext memory ctx = pipeTransferCommon(srcEntityId, dstEntityId, path);
    require(isStorageContainer(ctx.dstObjectTypeId), "PipeTransferSystem: destination object type is not valid");

    uint8 toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      uint8 currentToolObjectTypeId = transferInventoryTool(
        ctx.baseSrcEntityId,
        ctx.baseDstEntityId,
        ctx.dstObjectTypeId,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "PipeTransferSystem: all tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.checkChipData,
      ctx.isDeposit,
      ctx.baseSrcEntityId,
      ctx.baseDstEntityId,
      path,
      toolObjectTypeId,
      uint16(toolEntityIds.length),
      toolEntityIds,
      extraData
    );
  }

  function pipeTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    uint8 transferObjectTypeId,
    uint16 numToTransfer
  ) public payable {
    pipeTransfer(srcEntityId, dstEntityId, path, transferObjectTypeId, numToTransfer, new bytes(0));
  }

  function pipeTransferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    bytes32 toolEntityId
  ) public payable {
    pipeTransferTool(srcEntityId, dstEntityId, path, toolEntityId, new bytes(0));
  }

  function pipeTransferTools(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    bytes32[] memory toolEntityIds
  ) public payable {
    pipeTransferTools(srcEntityId, dstEntityId, path, toolEntityIds, new bytes(0));
  }
}
