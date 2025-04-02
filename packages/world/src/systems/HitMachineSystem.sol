// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Action } from "../codegen/common.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Position } from "../utils/Vec3Storage.sol";

import { HIT_ENERGY_COST, SAFE_PROGRAM_GAS } from "../Constants.sol";
import {
  addEnergyToLocalPool,
  decreaseMachineEnergy,
  decreasePlayerEnergy,
  updateMachineEnergy
} from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { useEquipped } from "../utils/InventoryUtils.sol";
import { HitMachineNotification, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { ProgramId } from "../ProgramId.sol";
import { IHitHook } from "../ProgramInterfaces.sol";
import { Vec3 } from "../Vec3.sol";

contract HitMachineSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function hitForceField(EntityId caller, Vec3 coord) public {
    caller.activate();
    caller.requireConnected(coord);

    (EntityId forceField,) = getForceField(coord);
    require(forceField.exists(), "No force field at this location");
    Vec3 forceFieldCoord = Position._get(forceField);

    uint128 energyReduction =
      HitMachineLib._processEnergyReduction(caller, forceField, coord, forceFieldCoord);

    ProgramId program = forceField.getProgram();
    bytes memory onHit = abi.encodeCall(IHitHook.onHit, (caller, forceField, energyReduction, ""));
    // Don't revert and use a fixed amount of gas so the program can't prevent hitting
    program.call({ gas: SAFE_PROGRAM_GAS, hook: onHit });

    notify(caller, HitMachineNotification({ machine: forceField, machineCoord: forceFieldCoord }));
  }
}

library HitMachineLib {
  function _processEnergyReduction(
    EntityId caller,
    EntityId forceField,
    Vec3 playerCoord,
    Vec3 forceFieldCoord
  ) public returns (uint128) {
    (EnergyData memory machineData,) = updateMachineEnergy(forceField);
    require(machineData.energy > 0, "Cannot hit depleted forcefield");
    (uint128 toolMassReduction,) = useEquipped(caller, machineData.energy);

    uint128 playerEnergyReduction = 0;

    // if tool mass reduction is not enough, consume energy from player up to hit energy cost
    if (toolMassReduction < machineData.energy) {
      uint128 remaining = machineData.energy - toolMassReduction;
      playerEnergyReduction = HIT_ENERGY_COST <= remaining ? HIT_ENERGY_COST : remaining;
      decreasePlayerEnergy(caller, playerCoord, playerEnergyReduction);
    }

    uint128 machineEnergyReduction = playerEnergyReduction + toolMassReduction;
    decreaseMachineEnergy(forceField, machineEnergyReduction);
    addEnergyToLocalPool(forceFieldCoord, machineEnergyReduction + playerEnergyReduction);
    return machineEnergyReduction;
  }
}
