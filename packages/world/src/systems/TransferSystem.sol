// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { EnergyData } from "../codegen/tables/Energy.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { transferEnergyToPool, updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { InventoryUtils } from "../utils/InventoryUtils.sol";
import { TransferNotification, notify } from "../utils/NotifUtils.sol";

import { SMART_CHEST_ENERGY_COST } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { ITransferHook } from "../ProgramInterfaces.sol";
import { Vec3 } from "../Vec3.sol";

contract TransferSystem is System {
  function transfer(
    EntityId caller,
    EntityId from,
    EntityId to,
    ObjectTypeId transferObjectTypeId,
    uint16 numToTransfer,
    bytes calldata extraData
  ) public payable {
    caller.activate();

    if (caller != from) {
      caller.requireConnected(from);
    }
    from.requireConnected(to);

    transferEnergyToPool(caller, SMART_CHEST_ENERGY_COST);

    ObjectTypeId toObjectTypeId = ObjectType._get(to);

    InventoryUtils.transfer(from, to, toObjectTypeId, transferObjectTypeId, numToTransfer);

    ObjectAmount[] memory objectAmounts = new ObjectAmount[](1);
    objectAmounts[0] = ObjectAmount(transferObjectTypeId, numToTransfer);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    TransferLib._onTransfer(caller, from, to, new EntityId[](0), objectAmounts, extraData);
  }

  function transferTool(EntityId caller, EntityId from, EntityId to, EntityId tool, bytes calldata extraData)
    public
    payable
  {
    EntityId[] memory tools = new EntityId[](1);
    tools[0] = tool;
    transferTools(caller, from, to, tools, extraData);
  }

  function transferTools(EntityId caller, EntityId from, EntityId to, EntityId[] memory tools, bytes calldata extraData)
    public
    payable
  {
    require(tools.length > 0, "Must transfer at least one tool");

    caller.activate();
    caller.requireConnected(to);

    transferEnergyToPool(caller, SMART_CHEST_ENERGY_COST);

    ObjectTypeId toObjectTypeId = ObjectType._get(to);

    for (uint256 i = 0; i < tools.length; i++) {
      transferInventoryEntity(from, to, toObjectTypeId, tools[i]);
    }

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    TransferLib._onTransfer(caller, from, to, tools, new ObjectAmount[](0), extraData);
  }
}

library TransferLib {
  function _onTransfer(
    EntityId caller,
    EntityId from,
    EntityId to,
    EntityId[] memory tools,
    ObjectAmount[] memory objectAmounts,
    bytes calldata extraData
  ) public {
    EntityId target = _getTarget(caller, from, to);

    require(ObjectType._get(target) != ObjectTypes.Player, "Cannot transfer to player");

    bytes memory onTransfer =
      abi.encodeCall(ITransferHook.onTransfer, (caller, target, from, to, objectAmounts, tools, extraData));

    target.getProgram().callOrRevert(onTransfer);

    notify(caller, TransferNotification({ transferEntityId: target, tools: tools, objectAmounts: objectAmounts }));
  }

  function _getTarget(EntityId caller, EntityId from, EntityId to) internal pure returns (EntityId) {
    if (caller == from) {
      return to;
    } else if (caller == to) {
      return from;
    } else {
      revert("Caller is not involved in transfer");
    }
  }
}
