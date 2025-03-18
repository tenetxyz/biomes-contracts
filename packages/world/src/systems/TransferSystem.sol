// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Chip } from "../codegen/tables/Chip.sol";
import { ActionType } from "../codegen/common.sol";

import { transferInventoryEntity, transferInventoryNonEntity } from "../utils/InventoryUtils.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { ChipOnTransferData, TransferData, TransferCommonContext } from "../Types.sol";
import { notify, TransferNotifData } from "../utils/NotifUtils.sol";
import { TransferLib } from "./libraries/TransferLib.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { callChipOrRevert } from "../utils/callChip.sol";

contract TransferSystem is System {
  function requireAllowed(
    uint256 machineEnergyLevel,
    bool isDeposit,
    EntityId playerEntityId,
    EntityId chestEntityId,
    TransferData memory transferData,
    bytes calldata extraData
  ) internal {
    if (machineEnergyLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bytes memory onTransferCall = abi.encodeCall(
        IChestChip.onTransfer,
        (
          ChipOnTransferData({
            targetEntityId: chestEntityId,
            callerEntityId: playerEntityId,
            isDeposit: isDeposit,
            transferData: transferData,
            extraData: extraData
          })
        )
      );
      callChipOrRevert(chestEntityId.getChip(), onTransferCall);
    }
  }

  function transfer(
    EntityId chestEntityId,
    bool isDeposit,
    ObjectTypeId transferObjectTypeId,
    uint16 numToTransfer,
    bytes calldata extraData
  ) public payable {
    TransferCommonContext memory ctx = TransferLib.transferCommon(_msgSender(), chestEntityId, isDeposit);
    transferInventoryNonEntity(
      ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
      ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
      ctx.dstObjectTypeId,
      transferObjectTypeId,
      numToTransfer
    );

    notify(
      ctx.playerEntityId,
      TransferNotifData({
        transferEntityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        transferCoord: ctx.chestCoord,
        transferObjectTypeId: transferObjectTypeId,
        transferAmount: numToTransfer
      })
    );

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.machineEnergyLevel,
      ctx.isDeposit,
      ctx.playerEntityId,
      ctx.chestEntityId,
      TransferData({
        objectTypeId: transferObjectTypeId,
        numToTransfer: numToTransfer,
        toolEntityIds: new EntityId[](0)
      }),
      extraData
    );
  }

  function transferTool(
    EntityId chestEntityId,
    bool isDeposit,
    EntityId toolEntityId,
    bytes calldata extraData
  ) public payable {
    EntityId[] memory toolEntityIds = new EntityId[](1);
    toolEntityIds[0] = toolEntityId;
    transferTools(chestEntityId, isDeposit, toolEntityIds, extraData);
  }

  function transferTools(
    EntityId chestEntityId,
    bool isDeposit,
    EntityId[] memory toolEntityIds,
    bytes calldata extraData
  ) public payable {
    require(toolEntityIds.length > 0, "Must transfer at least one tool");
    TransferCommonContext memory ctx = TransferLib.transferCommon(_msgSender(), chestEntityId, isDeposit);
    ObjectTypeId toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      ObjectTypeId currentToolObjectTypeId = transferInventoryEntity(
        ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
        ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        ctx.dstObjectTypeId,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "All tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    notify(
      ctx.playerEntityId,
      TransferNotifData({
        transferEntityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        transferCoord: ctx.chestCoord,
        transferObjectTypeId: toolObjectTypeId,
        transferAmount: uint16(toolEntityIds.length)
      })
    );

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.machineEnergyLevel,
      ctx.isDeposit,
      ctx.playerEntityId,
      ctx.chestEntityId,
      TransferData({
        objectTypeId: toolObjectTypeId,
        numToTransfer: uint16(toolEntityIds.length),
        toolEntityIds: toolEntityIds
      }),
      extraData
    );
  }
}
