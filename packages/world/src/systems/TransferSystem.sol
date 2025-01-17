// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { callMintXP } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { ChipOnTransferData, TransferData } from "../Types.sol";
import { transferCommon } from "../utils/TransferUtils.sol";

contract TransferSystem is System {
  function requireAllowed(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    TransferData memory transferData,
    bytes memory extraData
  ) internal {
    bool isDeposit = playerEntityId == srcEntityId;
    bytes32 chestEntityId = isDeposit ? dstEntityId : srcEntityId;
    ChipData memory chipData = updateChipBatteryLevel(chestEntityId);
    uint256 batteryLevel = chipData.batteryLevel;
    if (forceFieldEntityId != bytes32(0)) {
      ChipData memory forceFieldChipData = updateChipBatteryLevel(forceFieldEntityId);
      batteryLevel += forceFieldChipData.batteryLevel;
    }
    if (chipData.chipAddress != address(0) && batteryLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(chipData.chipAddress).onTransfer{ value: _msgValue() }(
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

    (
      bytes32 playerEntityId,
      uint8 dstObjectTypeId,
      bytes32 baseSrcEntityId,
      bytes32 baseDstEntityId,
      VoxelCoord memory chestCoord
    ) = transferCommon(srcEntityId, dstEntityId);
    transferInventoryNonTool(baseSrcEntityId, baseDstEntityId, dstObjectTypeId, transferObjectTypeId, numToTransfer);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: playerEntityId == baseSrcEntityId ? baseDstEntityId : baseSrcEntityId,
        objectTypeId: transferObjectTypeId,
        coordX: chestCoord.x,
        coordY: chestCoord.y,
        coordZ: chestCoord.z,
        amount: numToTransfer
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      getForceField(chestCoord),
      playerEntityId,
      baseSrcEntityId,
      baseDstEntityId,
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

    (
      bytes32 playerEntityId,
      uint8 dstObjectTypeId,
      bytes32 baseSrcEntityId,
      bytes32 baseDstEntityId,
      VoxelCoord memory chestCoord
    ) = transferCommon(srcEntityId, dstEntityId);
    uint8 toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      uint8 currentToolObjectTypeId = transferInventoryTool(
        baseSrcEntityId,
        baseDstEntityId,
        dstObjectTypeId,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "TransferSystem: all tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: playerEntityId == baseSrcEntityId ? baseDstEntityId : baseSrcEntityId,
        objectTypeId: toolObjectTypeId,
        coordX: chestCoord.x,
        coordY: chestCoord.y,
        coordZ: chestCoord.z,
        amount: toolEntityIds.length
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      getForceField(chestCoord),
      playerEntityId,
      baseSrcEntityId,
      baseDstEntityId,
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
