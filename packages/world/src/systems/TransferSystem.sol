// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { callMintXP } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { ChipOnTransferData, TransferData, TransferCommonContext } from "../Types.sol";

import { ITransferHelperSystem } from "../codegen/world/ITransferHelperSystem.sol";

contract TransferSystem is System {
  function requireAllowed(
    ChipData memory checkChipData,
    bool isDeposit,
    bytes32 playerEntityId,
    bytes32 chestEntityId,
    TransferData memory transferData,
    bytes memory extraData
  ) internal {
    if (checkChipData.chipAddress != address(0) && checkChipData.batteryLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(checkChipData.chipAddress).onTransfer{ value: _msgValue() }(
        ChipOnTransferData({
          targetEntityId: chestEntityId,
          callerEntityId: playerEntityId,
          isDeposit: isDeposit,
          transferData: transferData,
          extraData: extraData
        })
      );
      require(transferAllowed, "TransferSystem: Player not authorized by chip to make this transfer");
    }
  }

  function transfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();

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

    callMintXP(ctx.playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.checkChipData,
      ctx.isDeposit,
      ctx.playerEntityId,
      ctx.chestEntityId,
      TransferData({
        objectTypeId: transferObjectTypeId,
        numToTransfer: numToTransfer,
        toolEntityIds: new bytes32[](0)
      }),
      extraData
    );
  }

  function transferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 toolEntityId,
    bytes memory extraData
  ) public payable {
    bytes32[] memory toolEntityIds = new bytes32[](1);
    toolEntityIds[0] = toolEntityId;
    transferTools(srcEntityId, dstEntityId, toolEntityIds, extraData);
  }

  function transferTools(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();
    require(toolEntityIds.length > 0, "TransferSystem: must transfer at least one tool");
    require(toolEntityIds.length < type(uint16).max, "TransferSystem: too many tools to transfer");

    TransferCommonContext memory ctx = abi.decode(
      callInternalSystem(
        abi.encodeCall(ITransferHelperSystem.transferCommon, (_msgSender(), srcEntityId, dstEntityId)),
        0
      ),
      (TransferCommonContext)
    );
    uint8 toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      uint8 currentToolObjectTypeId = transferInventoryTool(
        ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
        ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        ctx.dstObjectTypeId,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "TransferSystem: all tools must be of the same type");
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

    callMintXP(ctx.playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      ctx.checkChipData,
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
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer
  ) public payable {
    transfer(srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, new bytes(0));
  }

  function transferTool(bytes32 srcEntityId, bytes32 dstEntityId, bytes32 toolEntityId) public payable {
    transferTool(srcEntityId, dstEntityId, toolEntityId, new bytes(0));
  }

  function transferTools(bytes32 srcEntityId, bytes32 dstEntityId, bytes32[] memory toolEntityIds) public payable {
    transferTools(srcEntityId, dstEntityId, toolEntityIds, new bytes(0));
  }

  function transferWithExtraData(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    transfer(srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, extraData);
  }

  function transferToolWithExtraData(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 toolEntityId,
    bytes memory extraData
  ) public payable {
    transferTool(srcEntityId, dstEntityId, toolEntityId, extraData);
  }

  function transferToolsWithExtraData(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) public payable {
    transferTools(srcEntityId, dstEntityId, toolEntityIds, extraData);
  }
}
