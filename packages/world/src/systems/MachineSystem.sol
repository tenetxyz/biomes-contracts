// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ObjectTypeId, PlayerObjectID, ChipBatteryObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel } from "../utils/EnergyUtils.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { notify, PowerMachineNotifData } from "../utils/NotifUtils.sol";

import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

import { EntityId } from "../EntityId.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract MachineSystem is System {
  function powerMachine(EntityId entityId, uint16 numBattery) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);

    EntityId baseEntityId = entityId.baseEntityId();

    removeFromInventoryCount(playerEntityId, ChipBatteryObjectID, numBattery);

    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);
    require(objectTypeId == ForceFieldObjectID, "Invalid object type");
    EnergyData memory machineData = updateEnergyLevel(baseEntityId);

    uint128 newEnergyLevel = machineData.energy + (uint128(numBattery) * 10);

    baseEntityId.setEnergy(newEnergyLevel);

    notify(
      playerEntityId,
      PowerMachineNotifData({ machineEntityId: baseEntityId, machineCoord: entityCoord, numBattery: numBattery })
    );

    callChipOrRevert(
      baseEntityId.getChipAddress(),
      abi.encodeCall(IForceFieldChip.onPowered, (playerEntityId, baseEntityId, numBattery))
    );
  }
}
