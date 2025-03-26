// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Program } from "../codegen/tables/Program.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";

import { IChestProgram } from "../prototypes/IChestProgram.sol";

import { transferInventoryEntity, transferInventoryNonEntity } from "../utils/InventoryUtils.sol";
import { notify, TransferNotifData } from "../utils/NotifUtils.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { updateMachineEnergy, transferEnergyToPool } from "../utils/EnergyUtils.sol";

import { ProgramOnTransferData } from "../Types.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { Vec3 } from "../Vec3.sol";
import { SMART_CHEST_ENERGY_COST } from "../Constants.sol";

contract TransferSystem is System {
  function transfer(
    EntityId callerEntityId,
    EntityId fromEntityId,
    EntityId toEntityId,
    ObjectTypeId transferObjectTypeId,
    uint16 numToTransfer,
    bytes calldata extraData
  ) public payable {
    callerEntityId.activate();

    if (callerEntityId != fromEntityId) {
      callerEntityId.requireConnected(fromEntityId);
    }
    fromEntityId.requireConnected(toEntityId);

    transferEnergyToPool(callerEntityId, SMART_CHEST_ENERGY_COST);

    ObjectTypeId toObjectTypeId = ObjectType._get(toEntityId);

    transferInventoryNonEntity(fromEntityId, toEntityId, toObjectTypeId, transferObjectTypeId, numToTransfer);

    ObjectAmount[] memory objectAmounts = new ObjectAmount[](1);
    objectAmounts[0] = ObjectAmount(transferObjectTypeId, numToTransfer);

    EntityId targetEntityId = _getTargetEntityId(callerEntityId, fromEntityId, toEntityId);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    TransferLib._callOnTransfer(
      callerEntityId,
      targetEntityId,
      fromEntityId,
      toEntityId,
      new EntityId[](0),
      objectAmounts,
      extraData
    );
  }

  function transferTool(
    EntityId callerEntityId,
    EntityId fromEntityId,
    EntityId toEntityId,
    EntityId toolEntityId,
    bytes calldata extraData
  ) public payable {
    EntityId[] memory toolEntityIds = new EntityId[](1);
    toolEntityIds[0] = toolEntityId;
    transferTools(callerEntityId, fromEntityId, toEntityId, toolEntityIds, extraData);
  }

  function transferTools(
    EntityId callerEntityId,
    EntityId fromEntityId,
    EntityId toEntityId,
    EntityId[] memory toolEntityIds,
    bytes calldata extraData
  ) public payable {
    require(toolEntityIds.length > 0, "Must transfer at least one tool");

    callerEntityId.activate();
    callerEntityId.requireConnected(toEntityId);

    transferEnergyToPool(callerEntityId, SMART_CHEST_ENERGY_COST);

    ObjectTypeId toObjectTypeId = ObjectType._get(toEntityId);

    for (uint i = 0; i < toolEntityIds.length; i++) {
      transferInventoryEntity(fromEntityId, toEntityId, toObjectTypeId, toolEntityIds[i]);
    }

    EntityId targetEntityId = _getTargetEntityId(callerEntityId, fromEntityId, toEntityId);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    TransferLib._callOnTransfer(
      callerEntityId,
      targetEntityId,
      fromEntityId,
      toEntityId,
      toolEntityIds,
      new ObjectAmount[](0),
      extraData
    );
  }

  function _getTargetEntityId(
    EntityId callerEntityId,
    EntityId fromEntityId,
    EntityId toEntityId
  ) internal pure returns (EntityId) {
    if (callerEntityId == fromEntityId) {
      return toEntityId;
    } else if (callerEntityId == toEntityId) {
      return fromEntityId;
    } else {
      revert("Caller is not involved in transfer");
    }
  }
}

library TransferLib {
  function _callOnTransfer(
    EntityId callerEntityId,
    EntityId targetEntityId,
    EntityId fromEntityId,
    EntityId toEntityId,
    EntityId[] memory toolEntityIds,
    ObjectAmount[] memory transferObjects,
    bytes calldata extraData
  ) public {
    (EntityId forceFieldEntityId, ) = getForceField(targetEntityId.getPosition());
    (EnergyData memory energyData, ) = updateMachineEnergy(forceFieldEntityId);
    if (energyData.energy > 0) {
      // Don't safe call here as we want to revert if the program doesn't allow the transfer
      bytes memory onTransferCall = abi.encodeCall(
        IChestProgram.onTransfer,
        (
          ProgramOnTransferData(
            callerEntityId,
            targetEntityId,
            fromEntityId,
            toEntityId,
            toolEntityIds,
            transferObjects,
            extraData
          )
        )
      );
      callProgramOrRevert(targetEntityId.getProgram(), onTransferCall);
    }
  }
}
