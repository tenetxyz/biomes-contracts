// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ForceFieldMetadata } from "../codegen/tables/ForceFieldMetadata.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { ActionType } from "../codegen/common.sol";

import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel, massToEnergy } from "../utils/EnergyUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { safeCallChip } from "../utils/callChip.sol";
import { notify, HitMachineNotifData } from "../utils/NotifUtils.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { PLAYER_HIT_ENERGY_COST } from "../Constants.sol";

import { ObjectTypeId } from "../ObjectTypeIds.sol";
import { EntityId } from "../EntityId.sol";

contract HitMachineSystem is System {
  using VoxelCoordLib for *;

  function hitMachineCommon(
    EntityId playerEntityId,
    EnergyData memory playerEnergyData,
    EntityId machineEntityId,
    VoxelCoord memory machineCoord
  ) internal {
    EnergyData memory machineData = updateMachineEnergyLevel(machineEntityId);
    if (machineData.energy == 0) {
      return;
    }

    (uint128 toolMassReduction, ObjectTypeId toolObjectTypeId) = useEquipped(playerEntityId);
    require(toolObjectTypeId.isWhacker(), "You must use a whacker to hit machines");

    uint128 baseEnergyReduction = PLAYER_HIT_ENERGY_COST + massToEnergy(toolMassReduction);
    VoxelCoord memory forceFieldShardCoord = machineCoord.toForceFieldShardCoord();
    uint128 protection = ForceFieldMetadata._getTotalMassInside(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );
    // TODO: scale protection otherwise, targetEnergyReduction will be 0
    uint128 targetEnergyReduction = baseEnergyReduction / protection;
    uint128 newMachineEnergy = targetEnergyReduction <= machineData.energy
      ? machineData.energy - targetEnergyReduction
      : 0;

    require(playerEnergyData.energy > PLAYER_HIT_ENERGY_COST, "Not enough energy");
    playerEntityId.setEnergy(playerEnergyData.energy - PLAYER_HIT_ENERGY_COST);
    machineEntityId.setEnergy(newMachineEnergy);
    machineCoord.addEnergyToLocalPool(PLAYER_HIT_ENERGY_COST + targetEnergyReduction);

    notify(playerEntityId, HitMachineNotifData({ machineEntityId: machineEntityId, machineCoord: machineCoord }));

    // Use safeCallChip to use a fixed amount of gas as we don't want the chip to prevent hitting the machine
    safeCallChip(
      machineEntityId.getChipAddress(),
      abi.encodeCall(IForceFieldChip.onForceFieldHit, (playerEntityId, machineEntityId))
    );
  }

  function hitMachine(EntityId entityId) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    EntityId baseEntityId = entityId.baseEntityId();

    hitMachineCommon(playerEntityId, playerEnergyData, baseEntityId, entityCoord);
  }

  function hitForceField(VoxelCoord memory entityCoord) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      _msgSender()
    );
    requireInPlayerInfluence(playerCoord, entityCoord);
    EntityId forceFieldEntityId = getForceField(entityCoord);
    require(forceFieldEntityId.exists(), "No force field at this location");
    VoxelCoord memory forceFieldCoord = Position._get(forceFieldEntityId).toVoxelCoord();
    hitMachineCommon(playerEntityId, playerEnergyData, forceFieldEntityId, forceFieldCoord);
  }
}
