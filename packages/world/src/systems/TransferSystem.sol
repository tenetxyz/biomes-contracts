// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { callInternalSystem } from "../utils/CallUtils.sol";

import { Chip } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { ChipOnTransferData, TransferData, TransferCommonContext } from "../Types.sol";

import { ITransferHelperSystem } from "../codegen/world/ITransferHelperSystem.sol";
import { EntityId } from "../EntityId.sol";

contract TransferSystem is System {
  function requireAllowed(
    uint256 machineEnergyLevel,
    address chipAddress,
    bool isDeposit,
    EntityId playerEntityId,
    EntityId chestEntityId,
    TransferData memory transferData,
    bytes memory extraData
  ) internal {
    if (chipAddress != address(0) && machineEnergyLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(chipAddress).onTransfer{ value: _msgValue() }(
        ChipOnTransferData({
          targetEntityId: chestEntityId,
          callerEntityId: playerEntityId,
          isDeposit: isDeposit,
          transferData: transferData,
          extraData: extraData
        })
      );
      require(transferAllowed, "Transfer not allowed by chip");
    }
  }

  function transferWithExtraData(
    EntityId srcEntityId,
    EntityId dstEntityId,
    uint16 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    TransferCommonContext memory ctx = abi.decode(
      callInternalSystem(
        abi.encodeCall(ITransferHelperSystem.transferCommon, (_msgSender(), srcEntityId, dstEntityId)),
        0
      ),
      (TransferCommonContext)
    );
    transferInventoryNonTool(
      ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
      ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
      ctx.dstObjectTypeId,
      transferObjectTypeId,
      numToTransfer
    );

    PlayerActionNotif._set(
      ctx.playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        objectTypeId: transferObjectTypeId,
        coordX: ctx.chestCoord.x,
        coordY: ctx.chestCoord.y,
        coordZ: ctx.chestCoord.z,
        amount: numToTransfer
      })
    );

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.machineEnergyLevel,
      ctx.chipAddress,
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

  function transferToolWithExtraData(
    EntityId srcEntityId,
    EntityId dstEntityId,
    EntityId toolEntityId,
    bytes memory extraData
  ) public payable {
    EntityId[] memory toolEntityIds = new EntityId[](1);
    toolEntityIds[0] = toolEntityId;
    transferToolsWithExtraData(srcEntityId, dstEntityId, toolEntityIds, extraData);
  }

  function transferToolsWithExtraData(
    EntityId srcEntityId,
    EntityId dstEntityId,
    EntityId[] memory toolEntityIds,
    bytes memory extraData
  ) public payable {
    require(toolEntityIds.length > 0, "Must transfer at least one tool");

    TransferCommonContext memory ctx = abi.decode(
      callInternalSystem(
        abi.encodeCall(ITransferHelperSystem.transferCommon, (_msgSender(), srcEntityId, dstEntityId)),
        0
      ),
      (TransferCommonContext)
    );
    uint16 toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      uint16 currentToolObjectTypeId = transferInventoryTool(
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

    PlayerActionNotif._set(
      ctx.playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        objectTypeId: toolObjectTypeId,
        coordX: ctx.chestCoord.x,
        coordY: ctx.chestCoord.y,
        coordZ: ctx.chestCoord.z,
        amount: toolEntityIds.length
      })
    );

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.machineEnergyLevel,
      ctx.chipAddress,
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

  function transfer(
    EntityId srcEntityId,
    EntityId dstEntityId,
    uint16 transferObjectTypeId,
    uint16 numToTransfer
  ) public payable {
    transferWithExtraData(srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, new bytes(0));
  }

  function transferTool(EntityId srcEntityId, EntityId dstEntityId, EntityId toolEntityId) public payable {
    transferToolWithExtraData(srcEntityId, dstEntityId, toolEntityId, new bytes(0));
  }

  function transferTools(EntityId srcEntityId, EntityId dstEntityId, EntityId[] memory toolEntityIds) public payable {
    transferToolsWithExtraData(srcEntityId, dstEntityId, toolEntityIds, new bytes(0));
  }
}
