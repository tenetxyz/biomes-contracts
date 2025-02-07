// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { TransferData, PipeTransferData, ChipOnTransferData, ChipOnPipeTransferData, TransferCommonContext, PipeTransferCommonContext } from "../Types.sol";
import { callMintXP } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool, removeFromInventoryCount, addToInventoryCount } from "../utils/InventoryUtils.sol";

import { ITransferHelperSystem } from "../codegen/world/ITransferHelperSystem.sol";
import { IPipeTransferHelperSystem } from "../codegen/world/IPipeTransferHelperSystem.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";

contract MultiTransferSystem is System {
  function requireAllowed(ChipData memory targetChipData, ChipOnTransferData memory chipOnTransferData) internal {
    if (targetChipData.chipAddress != address(0) && targetChipData.batteryLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(targetChipData.chipAddress).onTransfer{ value: _msgValue() }(
        chipOnTransferData
      );
      require(transferAllowed, "MultiTransferSystem: Player not authorized by chip to make this transfer");
    }
  }

  function requirePipeTransferAllowed(
    ChipData memory targetChipData,
    ChipOnPipeTransferData memory chipOnPipeTransferData
  ) internal {
    if (targetChipData.chipAddress != address(0) && targetChipData.batteryLevel > 0) {
      bool transferAllowed = IChestChip(targetChipData.chipAddress).onPipeTransfer(chipOnPipeTransferData);
      require(transferAllowed, "MultiTransferSystem: smart item not authorized by chip to make this transfer");
    }
  }

  function transferWithPipesWithExtraData(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    TransferData memory transferData,
    PipeTransferData[] memory pipesTransferData,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();
    require(pipesTransferData.length > 0, "MultiTransferSystem: must transfer through at least one pipe");
    TransferCommonContext memory ctx = abi.decode(
      callInternalSystem(
        abi.encodeCall(ITransferHelperSystem.transferCommon, (_msgSender(), srcEntityId, dstEntityId)),
        0
      ),
      (TransferCommonContext)
    );
    uint16 totalTransfer = transferData.numToTransfer;
    if (transferData.toolEntityIds.length == 0) {
      if (transferData.numToTransfer > 0) {
        // Note: we allow this because the main chest might be full/empty
        require(!ObjectTypeMetadata._getIsTool(transferData.objectTypeId), "Object type is not a block");
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
      require(transferData.toolEntityIds.length < type(uint16).max, "MultiTransferSystem: too many tools to transfer");
      require(
        uint16(transferData.toolEntityIds.length) == transferData.numToTransfer,
        "MultiTransferSystem: invalid tool count"
      );
      for (uint i = 0; i < transferData.toolEntityIds.length; i++) {
        uint16 toolObjectTypeId = transferInventoryTool(
          ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
          ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
          ctx.dstObjectTypeId,
          transferData.toolEntityIds[i]
        );
        require(
          toolObjectTypeId == transferData.objectTypeId,
          "MultiTransferSystem: all tools must be of the same type"
        );
      }
    }
    require(ctx.checkChipData.chipAddress != address(0), "MultiTransferSystem: chest is not a smart item");
    require(ctx.checkChipData.batteryLevel > 0, "MultiTransferSystem: chest has no charge");

    uint256 totalTools = transferData.toolEntityIds.length;
    for (uint i = 0; i < pipesTransferData.length; i++) {
      totalTools += pipesTransferData[i].transferData.toolEntityIds.length;
    }
    bytes32[] memory allToolEntityIds = new bytes32[](totalTools);
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
        "MultiTransferSystem: all pipes must be of the same object type"
      );
      pipeCtxs[i] = abi.decode(
        callInternalSystem(
          abi.encodeCall(
            IPipeTransferHelperSystem.pipeTransferCommon,
            (ctx.playerEntityId, PlayerObjectID, ctx.chestCoord, ctx.isDeposit, pipeTransferData)
          ),
          0
        ),
        (PipeTransferCommonContext)
      );

      totalTransfer += pipeTransferData.transferData.numToTransfer;
      for (uint j = 0; j < pipeTransferData.transferData.toolEntityIds.length; j++) {
        allToolEntityIds[allToolEntityIdsIdx] = pipeTransferData.transferData.toolEntityIds[j];
        allToolEntityIdsIdx++;
      }
    }

    PlayerActionNotif._set(
      ctx.playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        objectTypeId: transferData.objectTypeId,
        coordX: ctx.chestCoord.x,
        coordY: ctx.chestCoord.y,
        coordZ: ctx.chestCoord.z,
        amount: totalTransfer
      })
    );

    callMintXP(ctx.playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    for (uint i = 0; i < pipeCtxs.length; i++) {
      PipeTransferData memory pipeTransferData = pipesTransferData[i];

      // Require the pipe transfer to/from the caller entity is allowed
      requirePipeTransferAllowed(
        ctx.checkChipData,
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
          pipeCtxs[i].targetChipData,
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
      ctx.checkChipData,
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
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    TransferData memory transferData,
    PipeTransferData[] memory pipesTransferData
  ) public payable {
    transferWithPipesWithExtraData(srcEntityId, dstEntityId, transferData, pipesTransferData, new bytes(0));
  }
}
