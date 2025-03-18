// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { ActionType } from "../codegen/common.sol";

import { Position } from "../utils/Vec3Storage.sol";

import { useEquipped } from "../utils/InventoryUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy, massToEnergy, addEnergyToLocalPool } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { safeCallChip } from "../utils/callChip.sol";
import { notify, HitMachineNotifData } from "../utils/NotifUtils.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { PLAYER_HIT_ENERGY_COST } from "../Constants.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

contract HitMachineSystem is System {
  using ObjectTypeLib for ObjectTypeId;

  function hitForceField(Vec3 entityCoord) public {
    (EntityId playerEntityId, Vec3 playerCoord, EnergyData memory playerEnergyData) = PlayerUtils.requireValidPlayer(
      _msgSender()
    );

    PlayerUtils.requireInPlayerInfluence(playerCoord, entityCoord);
    (EntityId forceFieldEntityId, ) = getForceField(entityCoord);
    require(forceFieldEntityId.exists(), "No force field at this location");
    Vec3 forceFieldCoord = Position._get(forceFieldEntityId);
    (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
    require(machineData.energy > 0, "Cannot hit depleted forcefield");

    (uint128 toolMassReduction, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId, type(uint128).max);
    require(toolObjectTypeId.isWhacker(), "You must use a whacker to hit machines");

    uint128 energyReduction = PLAYER_HIT_ENERGY_COST + massToEnergy(toolMassReduction);
    uint128 newMachineEnergy = energyReduction <= machineData.energy ? machineData.energy - energyReduction : 0;

    require(playerEnergyData.energy >= PLAYER_HIT_ENERGY_COST, "Not enough energy");
    Energy._setEnergy(playerEntityId, playerEnergyData.energy - PLAYER_HIT_ENERGY_COST);
    Energy._setEnergy(forceFieldEntityId, newMachineEnergy);
    addEnergyToLocalPool(forceFieldCoord, PLAYER_HIT_ENERGY_COST + energyReduction);

    notify(playerEntityId, HitMachineNotifData({ machineEntityId: forceFieldEntityId, machineCoord: forceFieldCoord }));

    // Use safeCallChip to use a fixed amount of gas as we don't want the chip to prevent hitting the machine
    safeCallChip(
      forceFieldEntityId.getChip(),
      abi.encodeCall(IForceFieldChip.onForceFieldHit, (playerEntityId, forceFieldEntityId))
    );
  }
}
