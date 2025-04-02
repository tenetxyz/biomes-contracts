// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { EnergyData } from "../codegen/tables/Energy.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { transferEnergyToPool, updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { transferInventoryEntity, transferInventoryNonEntity } from "../utils/InventoryUtils.sol";
import { TransferNotifData, notify } from "../utils/NotifUtils.sol";

import { SMART_CHEST_ENERGY_COST } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { ITransferHook } from "../ProgramInterfaces.sol";
import { Vec3 } from "../Vec3.sol";

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

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    TransferLib._onTransfer(callerEntityId, fromEntityId, toEntityId, new EntityId[](0), objectAmounts, extraData);
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

    for (uint256 i = 0; i < toolEntityIds.length; i++) {
      transferInventoryEntity(fromEntityId, toEntityId, toObjectTypeId, toolEntityIds[i]);
    }

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    TransferLib._onTransfer(callerEntityId, fromEntityId, toEntityId, toolEntityIds, new ObjectAmount[](0), extraData);
  }
}

library TransferLib {
  function _onTransfer(
    EntityId callerEntityId,
    EntityId fromEntityId,
    EntityId toEntityId,
    EntityId[] memory toolEntityIds,
    ObjectAmount[] memory objectAmounts,
    bytes calldata extraData
  ) public {
    EntityId targetEntityId = _getTargetEntityId(callerEntityId, fromEntityId, toEntityId);

    require(ObjectType._get(targetEntityId) != ObjectTypes.Player, "Cannot transfer to player");

    bytes memory onTransfer = abi.encodeCall(
      ITransferHook.onTransfer,
      (callerEntityId, targetEntityId, fromEntityId, toEntityId, objectAmounts, toolEntityIds, extraData)
    );

    targetEntityId.getProgram().callOrRevert(onTransfer);

    notify(
      callerEntityId,
      TransferNotifData({ transferEntityId: targetEntityId, toolEntityIds: toolEntityIds, objectAmounts: objectAmounts })
    );
  }

  function _getTargetEntityId(EntityId callerEntityId, EntityId fromEntityId, EntityId toEntityId)
    internal
    pure
    returns (EntityId)
  {
    if (callerEntityId == fromEntityId) {
      return toEntityId;
    } else if (callerEntityId == toEntityId) {
      return fromEntityId;
    } else {
      revert("Caller is not involved in transfer");
    }
  }
}
