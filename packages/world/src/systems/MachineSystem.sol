// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { PlayerObjectID, ChipBatteryObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { safeCallChip } from "../Utils.sol";

import { IChip } from "../prototypes/IChip.sol";

contract MachineSystem is System {
  function powerMachine(bytes32 entityId, uint16 numBattery) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);

    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    removeFromInventoryCount(playerEntityId, ChipBatteryObjectID, numBattery);

    uint16 objectTypeId = ObjectType._get(baseEntityId);
    require(objectTypeId == ForceFieldObjectID, "Invalid object type");
    EnergyData memory machineData = updateMachineEnergyLevel(baseEntityId);
    uint256 newEnergyLevel = machineData.energyLevel + (uint256(numBattery) * 10);

    Energy._setEnergyLevel(baseEntityId, newEnergyLevel);
    Energy._setLastUpdatedTime(baseEntityId, block.timestamp);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.PowerChip,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: entityCoord.x,
        coordY: entityCoord.y,
        coordZ: entityCoord.z,
        amount: numBattery
      })
    );

    safeCallChip(chipData.chipAddress, abi.encodeCall(IChip.onPowered, (playerEntityId, baseEntityId, numBattery)));
  }
}
