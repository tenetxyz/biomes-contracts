// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { ChipOnPipeTransferData, PipeTransferData, PipeTransferCommonContext } from "../Types.sol";
import { ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, positionDataToVoxelCoord } from "../Utils.sol";
import { isStorageContainer } from "../utils/ObjectTypeUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";

import { IChestChip } from "../prototypes/IChestChip.sol";
import { PipeTransferLib } from "./libraries/PipeTransferLib.sol";
import { EntityId } from "../EntityId.sol";
import { callChipOrRevert } from "../utils/callChip.sol";

contract PipeTransferSystem is System {
  function pipeTransfer(
    EntityId callerEntityId,
    bool isDeposit,
    PipeTransferData memory pipeTransferData
  ) public payable {
    checkWorldStatus();
    uint16 callerObjectTypeId = ObjectType._get(callerEntityId);
    require(isStorageContainer(callerObjectTypeId), "Source object type is not a chest");

    address chipAddress = callerEntityId.getChipAddress();
    require(chipAddress == _msgSender(), "Caller is not the chip of the smart item");

    VoxelCoord memory callerCoord = positionDataToVoxelCoord(Position._get(callerEntityId));
    uint256 machineEnergyLevel = 0;
    EntityId callerForceFieldEntityId = getForceField(callerCoord);
    if (callerForceFieldEntityId.exists()) {
      EnergyData memory machineData = updateMachineEnergyLevel(callerForceFieldEntityId);
      machineEnergyLevel = machineData.energy;
    }
    require(machineEnergyLevel > 0, "Caller has no charge");
    PipeTransferCommonContext memory pipeCtx = PipeTransferLib.pipeTransferCommon(
      callerEntityId,
      callerObjectTypeId,
      callerCoord,
      isDeposit,
      pipeTransferData
    );

    if (pipeCtx.targetObjectTypeId != ForceFieldObjectID && machineEnergyLevel > 0) {
      ChipOnPipeTransferData memory chipOnPipeTransferData = ChipOnPipeTransferData({
        playerEntityId: EntityId.wrap(0), // this is a transfer initiated by a chest, not a player
        targetEntityId: pipeTransferData.targetEntityId,
        callerEntityId: callerEntityId,
        isDeposit: isDeposit,
        path: pipeTransferData.path,
        transferData: pipeTransferData.transferData,
        extraData: pipeTransferData.extraData
      });
      // we want to revert if the chip doesn't allow the transfer
      bytes memory onPipeTransferCall = abi.encodeCall(IChestChip.onPipeTransfer, (chipOnPipeTransferData));
      callChipOrRevert(chipAddress, onPipeTransferCall);
    }
  }
}
