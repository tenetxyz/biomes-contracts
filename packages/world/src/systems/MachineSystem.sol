// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Program } from "../codegen/tables/Program.sol";

import { removeFromInventory } from "../utils/InventoryUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { notify, PowerMachineNotifData } from "../utils/NotifUtils.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract MachineSystem is System {
  function fuelMachine(EntityId callerEntityId, EntityId machineEntityId, uint16 fuelAmount) public {
    callerEntityId.activate();
    callerEntityId.requireConnected(machineEntityId);

    EntityId baseEntityId = machineEntityId.baseEntityId();

    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    require(ObjectTypeLib.isMachine(objectTypeId), "Can only power machines");

    removeFromInventory(callerEntityId, ObjectTypes.Fuel, fuelAmount);

    (EnergyData memory machineData, ) = updateMachineEnergy(baseEntityId);

    uint128 newEnergyLevel = machineData.energy + uint128(fuelAmount) * ObjectTypeMetadata._getEnergy(ObjectTypes.Fuel);

    Energy._setEnergy(baseEntityId, newEnergyLevel);

    baseEntityId.getProgram().onFuel(callerEntityId, baseEntityId, fuelAmount);
  }
}
