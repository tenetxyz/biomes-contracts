// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, callMintXP } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { isStorageContainer } from "../utils/ObjectTypeUtils.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { ChipOnTransferData, TransferData, PipeTransferData } from "../Types.sol";
import { transferCommon, TransferCommonContext } from "../utils/TransferUtils.sol";

contract MultiTransferSystem is System {
  function transferWithPipes(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    TransferData memory transferData,
    PipeTransferData[] memory pipesTransferData,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();
    TransferCommonContext memory ctx = transferCommon(srcEntityId, dstEntityId);
    uint8 transferObjectTypeId = transferData.objectTypeId;
    uint256 totalTransfer = transferData.numToTransfer;
    if (transferData.toolEntityIds.length == 0) {
      transferInventoryNonTool(
        ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
        ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
        ctx.dstObjectTypeId,
        transferData.objectTypeId,
        transferData.numToTransfer
      );
    } else {
      require(transferData.toolEntityIds.length > 0, "MultiTransferSystem: must transfer at least one tool");
      require(
        uint16(transferData.toolEntityIds.length) == transferData.numToTransfer,
        "MultiTransferSystem: invalid tool count"
      );
      for (uint i = 0; i < transferData.toolEntityIds.length; i++) {
        uint8 toolObjectTypeId = transferInventoryTool(
          ctx.isDeposit ? ctx.playerEntityId : ctx.chestEntityId,
          ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
          ctx.dstObjectTypeId,
          transferData.toolEntityIds[i]
        );
        require(toolObjectTypeId == transferObjectTypeId, "MultiTransferSystem: all tools must be of the same type");
      }
    }

    for (uint i = 0; i < pipesTransferData.length; i++) {
      PipeTransferData memory pipeTransferData = pipesTransferData[i];
      require(
        pipeTransferData.transferData.objectTypeId == transferObjectTypeId,
        "MultiTransferSystem: all pipes must be of the same object type"
      );
      totalTransfer += pipeTransferData.transferData.numToTransfer;
    }

    // PlayerActionNotif._set(
    //   ctx.playerEntityId,
    //   PlayerActionNotifData({
    //     actionType: ActionType.Transfer,
    //     entityId: ctx.isDeposit ? ctx.chestEntityId : ctx.playerEntityId,
    //     objectTypeId: transferObjectTypeId,
    //     coordX: ctx.chestCoord.x,
    //     coordY: ctx.chestCoord.y,
    //     coordZ: ctx.chestCoord.z,
    //     amount: numToTransfer
    //   })
    // );

    // callMintXP(ctx.playerEntityId, initialGas, 1);
    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    // requireAllowed(
    //   ctx.checkChipData,
    //   ctx.isDeposit,
    //   ctx.playerEntityId,
    //   ctx.chestEntityId,
    //   TransferData({
    //     objectTypeId: transferData.objectTypeId,
    //     numToTransfer: totalTransfer,
    //     toolEntityIds: transferData.toolEntityIds
    //   }),
    //   extraData
    // );
  }
}
