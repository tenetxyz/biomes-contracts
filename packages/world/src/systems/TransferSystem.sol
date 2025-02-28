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
import { ObjectType } from "../ObjectType.sol";
import { callChipOrRevert } from "../utils/callChip.sol";

contract TransferSystem is System {
  function requireAllowed(
    uint256 machineEnergyLevel,
    bool isDeposit,
    EntityId playerEntityId,
    EntityId chestEntityId,
    TransferData memory transferData,
    bytes memory extraData
  ) internal {
    address chipAddress = chestEntityId.getChipAddress();
    if (chipAddress != address(0) && machineEnergyLevel > 0) {
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
      callChipOrRevert(chipAddress, onTransferCall);
    }
  }

  function transferWithExtraData(
    EntityId chestEntityId,
    bool isDeposit,
    ObjectType transferObjectType,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    TransferCommonContext memory ctx = TransferLib.transferCommon(_msgSender(), chestEntityId, isDeposit);
    transferInventoryNonEntity(
      ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
      ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
      ctx.dstObjectType,
      transferObjectType,
      numToTransfer
    );

    notify(
      ctx.playerEntityId,
      TransferNotifData({
        transferEntityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        transferCoord: ctx.chestCoord,
        transferObjectType: transferObjectType,
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
        objectType: transferObjectType,
        numToTransfer: numToTransfer,
        toolEntityIds: new EntityId[](0)
      }),
      extraData
    );
  }

  function transferToolWithExtraData(
    EntityId chestEntityId,
    bool isDeposit,
    EntityId toolEntityId,
    bytes memory extraData
  ) public payable {
    EntityId[] memory toolEntityIds = new EntityId[](1);
    toolEntityIds[0] = toolEntityId;
    transferToolsWithExtraData(chestEntityId, isDeposit, toolEntityIds, extraData);
  }

  function transferToolsWithExtraData(
    EntityId chestEntityId,
    bool isDeposit,
    EntityId[] memory toolEntityIds,
    bytes memory extraData
  ) public payable {
    require(toolEntityIds.length > 0, "Must transfer at least one tool");
    TransferCommonContext memory ctx = TransferLib.transferCommon(_msgSender(), chestEntityId, isDeposit);
    ObjectType toolObjectType;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      ObjectType currentToolObjectType = transferInventoryEntity(
        ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
        ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        ctx.dstObjectType,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectType == currentToolObjectType, "All tools must be of the same type");
      } else {
        toolObjectType = currentToolObjectType;
      }
    }

    notify(
      ctx.playerEntityId,
      TransferNotifData({
        transferEntityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        transferCoord: ctx.chestCoord,
        transferObjectType: toolObjectType,
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
        objectType: toolObjectType,
        numToTransfer: uint16(toolEntityIds.length),
        toolEntityIds: toolEntityIds
      }),
      extraData
    );
  }

  function transfer(
    EntityId chestEntityId,
    bool isDeposit,
    ObjectType transferObjectType,
    uint16 numToTransfer
  ) public payable {
    transferWithExtraData(chestEntityId, isDeposit, transferObjectType, numToTransfer, new bytes(0));
  }

  function transferTool(EntityId chestEntityId, bool isDeposit, EntityId toolEntityId) public payable {
    transferToolWithExtraData(chestEntityId, isDeposit, toolEntityId, new bytes(0));
  }

  function transferTools(EntityId chestEntityId, bool isDeposit, EntityId[] memory toolEntityIds) public payable {
    transferToolsWithExtraData(chestEntityId, isDeposit, toolEntityIds, new bytes(0));
  }
}
