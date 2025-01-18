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

struct PipeMultiTransferData {
  bytes32 targetEntityId;
  VoxelCoordDirectionVonNeumann[] path;
  TransferData transferData;
  bytes extraData;
}

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
    bytes32 callerEntityId,
    bool isDeposit,
    PipeMultiTransferData[] memory pipesTransferData
  ) public payable {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    uint8 callerObjectTypeId = ObjectType._get(callerEntityId);
    require(isStorageContainer(callerObjectTypeId), "PipeTransferSystem: source object type is not a chest");

    uint8 transferObjectTypeId = NullObjectTypeId;
    uint256 totalNumToTransfer = 0;

    VoxelCoord memory callerCoord = positionDataToVoxelCoord(Position._get(callerEntityId));
    ChipData memory callerChipData = updateChipBatteryLevel(callerEntityId);
    bytes32 callerForceFieldEntityId = getForceField(callerCoord);
    if (callerForceFieldEntityId != bytes32(0)) {
      ChipData memory callerForceFieldChipData = updateChipBatteryLevel(callerForceFieldEntityId);
      callerChipData.batteryLevel += callerForceFieldChipData.batteryLevel;
    }
    require(callerChipData.chipAddress == _msgSender(), "PipeTransferSystem: caller is not the chip of the smart item");
    require(callerChipData.batteryLevel > 0, "PipeTransferSystem: caller has no charge");

    for (uint i = 0; i < pipesTransferData.length; i++) {
      PipeMultiTransferData memory pipeTransferData = pipesTransferData[i];
      if (transferObjectTypeId == NullObjectTypeId) {
        transferObjectTypeId = pipeTransferData.transferData.objectTypeId;
      } else {
        require(
          transferObjectTypeId == pipeTransferData.transferData.objectTypeId,
          "PipeTransferSystem: all transfers must be of the same object type"
        );
      }
      totalNumToTransfer += pipeTransferData.transferData.numToTransfer;

      require(pipeTransferData.targetEntityId != callerEntityId, "PipeTransferSystem: cannot transfer to self");
      VoxelCoord memory targetCoord = positionDataToVoxelCoord(Position._get(pipeTransferData.targetEntityId));
      ChipData memory targetChipData = updateChipBatteryLevel(pipeTransferData.targetEntityId);
      uint8 targetObjectTypeId = ObjectType._get(pipeTransferData.targetEntityId);
      if (targetObjectTypeId != ForceFieldObjectID) {
        bytes32 targetForceFieldEntityId = getForceField(targetCoord);
        if (targetForceFieldEntityId != bytes32(0)) {
          ChipData memory targetForceFieldChipData = updateChipBatteryLevel(targetForceFieldEntityId);
          targetChipData.batteryLevel += targetForceFieldChipData.batteryLevel;
        }
      }

      requireValidPath(callerCoord, targetCoord, pipeTransferData.path);

      if (pipeTransferData.transferData.toolEntityIds.length == 0) {
        require(
          !ObjectTypeMetadata._getIsTool(pipeTransferData.transferData.objectTypeId),
          "PipeTransferSystem: object type is not a block"
        );
        require(pipeTransferData.transferData.numToTransfer > 0, "PipeTransferSystem: amount must be greater than 0");

        if (isDeposit) {
          removeFromInventoryCount(
            callerEntityId,
            pipeTransferData.transferData.objectTypeId,
            pipeTransferData.transferData.numToTransfer
          );

          if (isStorageContainer(targetObjectTypeId)) {
            addToInventoryCount(
              targetEntityId,
              targetObjectTypeId,
              pipeTransferData.transferData.objectTypeId,
              pipeTransferData.transferData.numToTransfer
            );
          } else if (targetObjectTypeId == ForceFieldObjectID) {
            require(
              pipeTransferData.transferData.objectTypeId == ChipBatteryObjectID,
              "PipeTransferSystem: force field can only accept chip batteries"
            );
            uint256 newBatteryLevel = targetChipData.batteryLevel +
              (uint256(pipeTransferData.transferData.numToTransfer) * CHARGE_PER_BATTERY);

            Chip._setBatteryLevel(targetEntityId, newBatteryLevel);
            Chip._setLastUpdatedTime(targetEntityId, block.timestamp);

            safeCallChip(
              targetChipData.chipAddress,
              abi.encodeCall(
                IChip.onPowered,
                (callerEntityId, targetEntityId, pipeTransferData.transferData.numToTransfer)
              )
            );
          } else {
            revert("PipeTransferSystem: target object type is not valid");
          }
        } else {
          addToInventoryCount(
            callerEntityId,
            callerObjectTypeId,
            pipeTransferData.transferData.objectTypeId,
            pipeTransferData.transferData.numToTransfer
          );

          if (isStorageContainer(targetObjectTypeId)) {
            removeFromInventoryCount(
              pipeTransferData.targetEntityId,
              pipeTransferData.transferData.objectTypeId,
              pipeTransferData.transferData.numToTransfer
            );
          } else {
            revert("PipeTransferSystem: target object type is not valid");
          }
        }
      } else {
        require(
          pipeTransferData.transferData.toolEntityIds.length < type(uint16).max,
          "PipeTransferSystem: too many tools to transfer"
        );

        for (uint i = 0; i < pipeTransferData.transferData.toolEntityIds.length; i++) {
          uint8 toolObjectTypeId = transferInventoryTool(
            isDeposit ? callerEntityId : pipeTransferData.targetEntityId,
            isDeposit ? pipeTransferData.targetEntityId : callerEntityId,
            pipeTransferData.transferData.objectTypeId,
            pipeTransferData.transferData.toolEntityIds[i]
          );
          require(toolObjectTypeId == transferObjectTypeId, "PipeTransferSystem: all tools must be of the same type");
        }
      }

      // TODO: requireAllowed on target
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
}
