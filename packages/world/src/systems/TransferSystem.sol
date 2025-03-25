// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Program } from "../codegen/tables/Program.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { IChestProgram } from "../prototypes/IChestProgram.sol";

import { transferInventoryEntity, transferInventoryNonEntity } from "../utils/InventoryUtils.sol";
import { notify, TransferNotifData } from "../utils/NotifUtils.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { transferEnergyToPool } from "../utils/EnergyUtils.sol";

import { ProgramOnTransferData, TransferData, TransferCommonContext } from "../Types.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
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

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    // _callChestOnTransfer(
    //   callerEntityId,
    //   targetEntityId,
    //   TransferData({
    //     objectTypeId: transferObjectTypeId,
    //     numToTransfer: numToTransfer,
    //     toolEntityIds: new EntityId[](0)
    //   }),
    //   extraData
    // );
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

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    // _callChestOnTransfer(
    //   callerEntityId,
    //   targetEntityId,
    //   ctx.playerEntityId,
    //   ctx.chestEntityId,
    //   TransferData({
    //     objectTypeId: toolObjectTypeId,
    //     numToTransfer: uint16(toolEntityIds.length),
    //     toolEntityIds: toolEntityIds
    //   }),
    //   extraData
    // );
  }

  function _getTargetEntityId(
    EntityId callerEntityId,
    EntityId fromEntityId,
    EntityId toEntityId
  ) internal returns (EntityId) {
    if (callerEntityId == fromEntityId) {
      return toEntityId;
    } else if (callerEntityId == toEntityId) {
      return fromEntityId;
    } else {
      revert("Caller is not involved in transfer");
    }
  }

  function _callChestOnTransfer(
    EntityId callerEntityId,
    EntityId targetEntityId,
    EntityId fromEntityId,
    EntityId toEntityId,
    TransferData memory transferData,
    bytes calldata extraData
  ) internal {
    // Don't safe call here as we want to revert if the program doesn't allow the transfer
    // bytes memory onTransferCall = abi.encodeCall(
    //   IChestProgram.onTransfer,
    //   (callerEntityId, targetEntityId, fromEntityId, toEntityId, transferData, extraData)
    // );
    // callProgramOrRevert(targetEntityId.getProgram(), onTransferCall);
  }
}
