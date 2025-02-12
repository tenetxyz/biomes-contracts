// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ObjectCategory, ActionType } from "../codegen/common.sol";

import { PlayerObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { TransferData, PipeTransferData, ChipOnTransferData, ChipOnPipeTransferData, TransferCommonContext, PipeTransferCommonContext } from "../Types.sol";
import { transferInventoryEntity, removeFromInventoryCount, addToInventoryCount } from "../utils/InventoryUtils.sol";
import { notify, TransferNotifData } from "../utils/NotifUtils.sol";

import { TransferLib } from "./libraries/TransferLib.sol";
import { PipeTransferLib } from "./libraries/PipeTransferLib.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { EntityId } from "../EntityId.sol";

contract MultiTransferSystem is System {
  function requireAllowed(
    address chipAddress,
    uint256 machineEnergyLevel,
    ChipOnTransferData memory chipOnTransferData
  ) internal {
    if (chipAddress != address(0) && machineEnergyLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(chipAddress).onTransfer{ value: _msgValue() }(chipOnTransferData);
      require(transferAllowed, "Transfer not allowed by chip");
    }
  }

  function requirePipeTransferAllowed(
    address chipAddress,
    uint256 machineEnergyLevel,
    ChipOnPipeTransferData memory chipOnPipeTransferData
  ) internal {
    if (chipAddress != address(0) && machineEnergyLevel > 0) {
      bool transferAllowed = IChestChip(chipAddress).onPipeTransfer(chipOnPipeTransferData);
      require(transferAllowed, "Transfer not allowed by chip");
    }
  }

  function transferWithPipesWithExtraData(
    EntityId srcEntityId,
    EntityId dstEntityId,
    TransferData memory transferData,
    PipeTransferData[] memory pipesTransferData,
    bytes memory extraData
  ) public payable {
    require(pipesTransferData.length > 0, "Must transfer through at least one pipe");
    TransferCommonContext memory ctx = TransferLib.transferCommon(_msgSender(), srcEntityId, dstEntityId);
    uint16 totalTransfer = transferData.numToTransfer;
    if (transferData.toolEntityIds.length == 0) {
      if (transferData.numToTransfer > 0) {
        // Note: we allow this because the main chest might be full/empty
        require(
          ObjectTypeMetadata._getObjectCategory(transferData.objectTypeId) == ObjectCategory.Block,
          "Object type is not a block"
        );
        removeFromInventoryCount(
          ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
          transferData.objectTypeId,
          transferData.numToTransfer
        );
        addToInventoryCount(
          ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
          ctx.dstObjectTypeId,
          transferData.objectTypeId,
          transferData.numToTransfer
        );
      }
    } else {
      require(uint16(transferData.toolEntityIds.length) == transferData.numToTransfer, "Invalid tool count");
      for (uint i = 0; i < transferData.toolEntityIds.length; i++) {
        uint16 toolObjectTypeId = transferInventoryEntity(
          ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
          ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
          ctx.dstObjectTypeId,
          transferData.toolEntityIds[i]
        );
        require(toolObjectTypeId == transferData.objectTypeId, "All tools must be of the same type");
      }
    }
    require(ctx.chipAddress != address(0), "Chest is not a smart item");
    require(ctx.machineEnergyLevel > 0, "Chest has no charge");

    uint256 totalTools = transferData.toolEntityIds.length;
    for (uint i = 0; i < pipesTransferData.length; i++) {
      totalTools += pipesTransferData[i].transferData.toolEntityIds.length;
    }
    EntityId[] memory allToolEntityIds = new EntityId[](totalTools);
    uint16 allToolEntityIdsIdx = 0;
    for (uint i = 0; i < transferData.toolEntityIds.length; i++) {
      allToolEntityIds[allToolEntityIdsIdx] = transferData.toolEntityIds[i];
      allToolEntityIdsIdx++;
    }

    PipeTransferCommonContext[] memory pipeCtxs = new PipeTransferCommonContext[](pipesTransferData.length);
    for (uint i = 0; i < pipesTransferData.length; i++) {
      PipeTransferData memory pipeTransferData = pipesTransferData[i];
      require(
        pipeTransferData.transferData.objectTypeId == transferData.objectTypeId,
        "All pipes must be of the same object type"
      );
      pipeCtxs[i] = PipeTransferLib.pipeTransferCommon(
        ctx.playerEntityId,
        PlayerObjectID,
        ctx.chestCoord,
        ctx.isDeposit,
        pipeTransferData
      );

      totalTransfer += pipeTransferData.transferData.numToTransfer;
      for (uint j = 0; j < pipeTransferData.transferData.toolEntityIds.length; j++) {
        allToolEntityIds[allToolEntityIdsIdx] = pipeTransferData.transferData.toolEntityIds[j];
        allToolEntityIdsIdx++;
      }
    }

    notify(
      ctx.playerEntityId,
      TransferNotifData({
        transferEntityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        transferCoord: ctx.chestCoord,
        transferObjectTypeId: transferData.objectTypeId,
        transferAmount: totalTransfer
      })
    );

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    for (uint i = 0; i < pipeCtxs.length; i++) {
      PipeTransferData memory pipeTransferData = pipesTransferData[i];

      // Require the pipe transfer to/from the caller entity is allowed
      requirePipeTransferAllowed(
        ctx.chipAddress,
        ctx.machineEnergyLevel,
        ChipOnPipeTransferData({
          playerEntityId: ctx.playerEntityId,
          targetEntityId: ctx.chestEntityId,
          callerEntityId: pipeTransferData.targetEntityId,
          isDeposit: ctx.isDeposit,
          path: pipeTransferData.path,
          transferData: pipeTransferData.transferData,
          extraData: pipeTransferData.extraData
        })
      );

      // Require the pipe transfer to/from the target entity is allowed
      if (pipeCtxs[i].targetObjectTypeId != ForceFieldObjectID) {
        requirePipeTransferAllowed(
          pipeCtxs[i].chipAddress,
          pipeCtxs[i].machineEnergyLevel,
          ChipOnPipeTransferData({
            playerEntityId: ctx.playerEntityId,
            targetEntityId: pipeTransferData.targetEntityId,
            callerEntityId: ctx.chestEntityId,
            isDeposit: ctx.isDeposit,
            path: pipeTransferData.path,
            transferData: pipeTransferData.transferData,
            extraData: pipeTransferData.extraData
          })
        );
      }
    }

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.chipAddress,
      ctx.machineEnergyLevel,
      ChipOnTransferData({
        targetEntityId: ctx.chestEntityId,
        callerEntityId: ctx.playerEntityId,
        isDeposit: ctx.isDeposit,
        transferData: TransferData({
          objectTypeId: transferData.objectTypeId,
          numToTransfer: totalTransfer,
          toolEntityIds: allToolEntityIds
        }),
        extraData: extraData
      })
    );
  }

  function transferWithPipes(
    EntityId srcEntityId,
    EntityId dstEntityId,
    TransferData memory transferData,
    PipeTransferData[] memory pipesTransferData
  ) public payable {
    transferWithPipesWithExtraData(srcEntityId, dstEntityId, transferData, pipesTransferData, new bytes(0));
  }
}
