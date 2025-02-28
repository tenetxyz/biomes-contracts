// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../VoxelCoord.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ForceField } from "../codegen/tables/ForceField.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ObjectTypeId, PlayerObjectID, ChipBatteryObjectID, ForceFieldObjectID, ForceFieldShardID } from "../ObjectTypeIds.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/EnergyUtils.sol";
import { getUniqueEntity } from "../Utils.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { notify, PowerMachineNotifData } from "../utils/NotifUtils.sol";

import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

import { EntityId } from "../EntityId.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract ForceFieldSystem is System {
  function expandForceField(EntityId forceFieldEntityId, VoxelCoord memory shardCoord) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    // TODO: check close to shard? or close to forcefield block?
    // VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ForceFieldObjectID, "Invalid object type");
    EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);

    EntityId shardEntity = getUniqueEntity();
    ObjectType._set(shardEntity, ForceFieldShardID);
    ForceField._set(shardCoord.x, shardCoord.y, shardCoord.z, shardEntity);
    BaseEntity._set();

    notify(
      playerEntityId,
      PowerMachineNotifData({ machineEntityId: forceFieldEntityId, machineCoord: entityCoord, numBattery: numBattery })
    );

    callChipOrRevert(
      forceFieldEntityId.getChipAddress(),
      // abi.encodeCall(IForceFieldChip.onPowered, (playerEntityId, baseEntityId, numBattery))
    );
  }
}
