// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { ActionType } from "../codegen/common.sol";

import { Position } from "../utils/Vec3Storage.sol";

import { useEquipped } from "../utils/InventoryUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy, addEnergyToLocalPool, decreasePlayerEnergy, decreaseMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { notify, HitMachineNotifData } from "../utils/NotifUtils.sol";
import { HIT_ENERGY_COST } from "../Constants.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

contract HitMachineSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function hitForceField(EntityId callerEntityId, Vec3 coord) public {
    callerEntityId.activate();
    callerEntityId.requireConnected(coord);

    (EntityId forceFieldEntityId, ) = getForceField(coord);
    require(forceFieldEntityId.exists(), "No force field at this location");
    Vec3 forceFieldCoord = Position._get(forceFieldEntityId);

    uint128 energyReduction = HitMachineLib._processEnergyReduction(
      callerEntityId,
      forceFieldEntityId,
      coord,
      forceFieldCoord
    );

    // TODO: does it make sense to pass extradata to onHit?
    forceFieldEntityId.getProgram().onHit(callerEntityId, forceFieldEntityId, energyReduction, "");

    notify(callerEntityId, HitMachineNotifData({ machineEntityId: forceFieldEntityId, machineCoord: forceFieldCoord }));
  }
}

library HitMachineLib {
  function _processEnergyReduction(
    EntityId callerEntityId,
    EntityId forceFieldEntityId,
    Vec3 playerCoord,
    Vec3 forceFieldCoord
  ) public returns (uint128) {
    (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
    require(machineData.energy > 0, "Cannot hit depleted forcefield");
    (uint128 toolMassReduction, ) = useEquipped(callerEntityId, machineData.energy);

    uint128 playerEnergyReduction = 0;

    // if tool mass reduction is not enough, consume energy from player up to hit energy cost
    if (toolMassReduction < machineData.energy) {
      uint128 remaining = machineData.energy - toolMassReduction;
      playerEnergyReduction = HIT_ENERGY_COST <= remaining ? HIT_ENERGY_COST : remaining;
      decreasePlayerEnergy(callerEntityId, playerCoord, playerEnergyReduction);
    }

    uint128 machineEnergyReduction = playerEnergyReduction + toolMassReduction;
    decreaseMachineEnergy(forceFieldEntityId, machineEnergyReduction);
    addEnergyToLocalPool(forceFieldCoord, machineEnergyReduction + playerEnergyReduction);
    return machineEnergyReduction;
  }
}
