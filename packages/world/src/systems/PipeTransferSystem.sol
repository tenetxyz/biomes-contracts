// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";

import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { IN_MAINTENANCE } from "../Constants.sol";
import { ChipOnPipeTransferData, PipeTransferData } from "../Types.sol";
import { ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { isStorageContainer } from "../utils/ObjectTypeUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { requirePipeTransferAllowed, pipeTransferCommon, PipeTransferCommonContext } from "../utils/TransferUtils.sol";

contract PipeTransferSystem is System {
  function pipeTransfer(bytes32 callerEntityId, bool isDeposit, PipeTransferData memory pipeTransferData) public {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    uint8 callerObjectTypeId = ObjectType._get(callerEntityId);
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

    PipeTransferCommonContext memory pipeCtx = pipeTransferCommon(
      callerEntityId,
      callerObjectTypeId,
      callerCoord,
      isDeposit,
      pipeTransferData
    );

    if (pipeCtx.targetObjectTypeId != ForceFieldObjectID) {
      requirePipeTransferAllowed(
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
