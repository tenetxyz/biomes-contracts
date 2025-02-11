// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { PlayerObjectID, ChipBatteryObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { safeCallChip } from "../Utils.sol";

import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

import { EntityId } from "../EntityId.sol";

contract MachineSystem is System {
  function powerMachine(EntityId entityId, uint16 numBattery) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);

    EntityId baseEntityId = entityId.baseEntityId();

    removeFromInventoryCount(playerEntityId, ChipBatteryObjectID, numBattery);

    uint16 objectTypeId = ObjectType._get(baseEntityId);
    require(objectTypeId == ForceFieldObjectID, "Invalid object type");
    EnergyData memory machineData = updateMachineEnergyLevel(baseEntityId);
    uint128 newEnergyLevel = machineData.energy + (uint128(numBattery) * 10);

    Energy._set(baseEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: newEnergyLevel }));

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.PowerMachine,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: entityCoord.x,
        coordY: entityCoord.y,
        coordZ: entityCoord.z,
        amount: numBattery
      })
    );

    safeCallChip(
      Chip._getChipAddress(baseEntityId),
      abi.encodeCall(IForceFieldChip.onPowered, (playerEntityId, baseEntityId, numBattery))
    );
  }
}
