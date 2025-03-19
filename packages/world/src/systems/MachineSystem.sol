// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Program } from "../codegen/tables/Program.sol";

import { IForceFieldProgram } from "../prototypes/IForceFieldProgram.sol";

import { removeFromInventory } from "../utils/InventoryUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { notify, PowerMachineNotifData } from "../utils/NotifUtils.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract MachineSystem is System {
  function powerMachine(EntityId entityId, uint16 fuelAmount) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());
    Vec3 entityCoord = PlayerUtils.requireInPlayerInfluence(playerCoord, entityId);

    EntityId baseEntityId = entityId.baseEntityId();

    removeFromInventory(playerEntityId, ObjectTypes.Fuel, fuelAmount);

    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    require(ObjectTypeLib.isMachine(objectTypeId), "Can only power machines");
    (EnergyData memory machineData, ) = updateMachineEnergy(baseEntityId);

    uint128 newEnergyLevel = machineData.energy + uint128(fuelAmount) * ObjectTypeMetadata._getEnergy(ObjectTypes.Fuel);

    Energy._setEnergy(baseEntityId, newEnergyLevel);

    notify(
      playerEntityId,
      PowerMachineNotifData({ machineEntityId: baseEntityId, machineCoord: entityCoord, fuelAmount: fuelAmount })
    );

    callProgramOrRevert(
      baseEntityId.getProgram(),
      abi.encodeCall(IForceFieldProgram.onPowered, (playerEntityId, baseEntityId, fuelAmount))
    );
  }
}
