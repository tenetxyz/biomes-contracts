// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { EnergyData } from "../codegen/tables/Energy.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { transferEnergyToPool, updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { InventoryUtils, SlotAmount } from "../utils/InventoryUtils.sol";
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
    SlotAmount[] memory slotAmounts,
    bytes calldata extraData
  ) public payable {
    caller.activate();

    if (caller != from) {
      caller.requireConnected(from);
    }
    from.requireConnected(to);

    transferEnergyToPool(caller, SMART_CHEST_ENERGY_COST);

    InventoryUtils.transfer(from, to, slotAmounts);

    // TODO: hook might need to change
    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    // TransferLib._onTransfer(caller, from, to, new EntityId[](0), objectAmounts, extraData);
  }
}

// TODO: adapt
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
