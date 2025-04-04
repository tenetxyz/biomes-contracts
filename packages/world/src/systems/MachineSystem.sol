// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Action } from "../codegen/common.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { InventoryUtils } from "../utils/InventoryUtils.sol";
import { FuelMachineNotification, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { ProgramId } from "../ProgramId.sol";
import { IFuelHook } from "../ProgramInterfaces.sol";
import { Vec3 } from "../Vec3.sol";

contract MachineSystem is System {
  function fuelMachine(EntityId caller, EntityId machine, uint16 fuelAmount) public {
    caller.activate();
    caller.requireConnected(machine);

    machine = machine.baseEntityId();

    ObjectTypeId objectTypeId = ObjectType._get(machine);
    require(ObjectTypeLib.isMachine(objectTypeId), "Can only power machines");

    InventoryUtils.removeObject(caller, ObjectTypes.Fuel, fuelAmount);

    (EnergyData memory machineData,) = updateMachineEnergy(machine);

    uint128 newEnergyLevel = machineData.energy + uint128(fuelAmount) * ObjectTypeMetadata._getEnergy(ObjectTypes.Fuel);

    Energy._setEnergy(machine, newEnergyLevel);

    // TODO: pass extradata as argument
    ProgramId program = machine.getProgram();
    program.callOrRevert(abi.encodeCall(IFuelHook.onFuel, (caller, machine, fuelAmount, "")));

    // TODO: notify
  }
}
