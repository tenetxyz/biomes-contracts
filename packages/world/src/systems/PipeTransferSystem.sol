// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";

import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { IN_MAINTENANCE } from "../Constants.sol";
import { ChipOnPipeTransferData, PipeTransferData, PipeTransferCommonContext } from "../Types.sol";
import { ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { isStorageContainer } from "../utils/ObjectTypeUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";

import { IPipeTransferHelperSystem } from "../codegen/world/IPipeTransferHelperSystem.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";

contract PipeTransferSystem is System {
  function requireAllowed(
    ChipData memory targetChipData,
    ChipOnPipeTransferData memory chipOnPipeTransferData
  ) internal {
    if (targetChipData.chipAddress != address(0) && targetChipData.batteryLevel > 0) {
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(targetChipData.chipAddress).onPipeTransfer{ value: _msgValue() }(
        chipOnPipeTransferData
      );
      require(transferAllowed, "PipeTransferSystem: smart item not authorized by chip to make this transfer");
    }
  }

  function pipeTransfer(
    bytes32 callerEntityId,
    bool isDeposit,
    PipeTransferData memory pipeTransferData
  ) public payable {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    uint16 callerObjectTypeId = ObjectType._get(callerEntityId);
    require(isStorageContainer(callerObjectTypeId), "PipeTransferSystem: source object type is not a chest");

    VoxelCoord memory callerCoord = positionDataToVoxelCoord(Position._get(callerEntityId));
    ChipData memory callerChipData = updateChipBatteryLevel(callerEntityId);
    bytes32 callerForceFieldEntityId = getForceField(callerCoord);
    if (callerForceFieldEntityId != bytes32(0)) {
      ChipData memory callerForceFieldChipData = updateChipBatteryLevel(callerForceFieldEntityId);
      callerChipData.batteryLevel += callerForceFieldChipData.batteryLevel;
    }
    require(callerChipData.chipAddress == _msgSender(), "PipeTransferSystem: caller is not the chip of the smart item");
    require(callerChipData.batteryLevel > 0, "PipeTransferSystem: caller has no charge");

    PipeTransferCommonContext memory pipeCtx = abi.decode(
      callInternalSystem(
        abi.encodeCall(
          IPipeTransferHelperSystem.pipeTransferCommon,
          (callerEntityId, callerObjectTypeId, callerCoord, isDeposit, pipeTransferData)
        ),
        0
      ),
      (PipeTransferCommonContext)
    );

    if (pipeCtx.targetObjectTypeId != ForceFieldObjectID) {
      requireAllowed(
        pipeCtx.targetChipData,
        ChipOnPipeTransferData({
          playerEntityId: bytes32(0), // this is a transfer initiated by a chest, not a player
          targetEntityId: pipeTransferData.targetEntityId,
          callerEntityId: callerEntityId,
          isDeposit: isDeposit,
          path: pipeTransferData.path,
          transferData: pipeTransferData.transferData,
          extraData: pipeTransferData.extraData
        })
      );
    }
  }
}
