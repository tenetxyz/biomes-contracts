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

import { Position, ForceFieldMetadata } from "../utils/Vec3Storage.sol";

import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel, massToEnergy, addEnergyToLocalPool } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { safeCallChip } from "../utils/callChip.sol";
import { notify, HitMachineNotifData } from "../utils/NotifUtils.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { PLAYER_HIT_ENERGY_COST } from "../Constants.sol";

import { ObjectTypeId } from "../ObjectTypeIds.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";

contract HitMachineSystem is System {
  function hitMachineCommon(
    EntityId playerEntityId,
    EnergyData memory playerEnergyData,
    EntityId machineEntityId,
    Vec3 machineCoord
  ) internal {
    EnergyData memory machineData = updateEnergyLevel(machineEntityId);
    if (machineData.energy == 0) {
      return;
    }

    (uint128 toolMassReduction, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId);
    require(toolObjectTypeId.isWhacker(), "You must use a whacker to hit machines");

    uint128 baseEnergyReduction = PLAYER_HIT_ENERGY_COST + massToEnergy(toolMassReduction);
    Vec3 forceFieldShardCoord = machineCoord.toForceFieldShardCoord();
    uint128 protection = ForceFieldMetadata._getTotalMassInside(forceFieldShardCoord);
    // TODO: scale protection otherwise, targetEnergyReduction will be 0
    uint128 targetEnergyReduction = baseEnergyReduction / protection;
    uint128 newMachineEnergy = targetEnergyReduction <= machineData.energy
      ? machineData.energy - targetEnergyReduction
      : 0;

    require(playerEnergyData.energy > PLAYER_HIT_ENERGY_COST, "Not enough energy");
    playerEntityId.setEnergy(playerEnergyData.energy - PLAYER_HIT_ENERGY_COST);
    machineEntityId.setEnergy(newMachineEnergy);
    addEnergyToLocalPool(machineCoord, PLAYER_HIT_ENERGY_COST + targetEnergyReduction);

    notify(playerEntityId, HitMachineNotifData({ machineEntityId: machineEntityId, machineCoord: machineCoord }));

    // Use safeCallChip to use a fixed amount of gas as we don't want the chip to prevent hitting the machine
    safeCallChip(
      machineEntityId.getChipAddress(),
      abi.encodeCall(IForceFieldChip.onForceFieldHit, (playerEntityId, machineEntityId))
    );
  }

  function hitMachine(EntityId entityId) public {
    (EntityId playerEntityId, Vec3 playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(_msgSender());
    Vec3 entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    EntityId baseEntityId = entityId.baseEntityId();

    hitMachineCommon(playerEntityId, playerEnergyData, baseEntityId, entityCoord);
  }

  function hitForceField(Vec3 entityCoord) public {
    (EntityId playerEntityId, Vec3 playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, entityCoord);
    EntityId forceFieldEntityId = getForceField(entityCoord);
    require(forceFieldEntityId.exists(), "No force field at this location");
    Vec3 forceFieldCoord = Position._get(forceFieldEntityId);
    hitMachineCommon(playerEntityId, playerEnergyData, forceFieldEntityId, forceFieldCoord);
  }
}
