// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ForceField } from "../codegen/tables/ForceField.sol";

import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel } from "../utils/EnergyUtils.sol";
import { getUniqueEntity } from "../Utils.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { notify, ExpandForceFieldNotifData, ContractForceFieldNotifData } from "../utils/NotifUtils.sol";
import { isForceFieldShard, isForceFieldShardActive, setupForceFieldShard, removeForceFieldShard } from "../utils/ForceFieldUtils.sol";
import { ForceFieldShard } from "../utils/Vec3Storage.sol";

import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract ForceFieldSystem is System {
  function expandForceField(
    EntityId forceFieldEntityId,
    Vec3 refShardCoord,
    Vec3 fromShardCoord,
    Vec3 toShardCoord
  ) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, forceFieldEntityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);

    require(fromShardCoord <= toShardCoord, "Invalid coordinates");

    require(
      refShardCoord <= toShardCoord + vec3(1, 1, 1) && fromShardCoord <= refShardCoord - vec3(1, 1, 1),
      "Reference shard is not adjacent to new shards"
    );

    require(isForceFieldShard(forceFieldEntityId, refShardCoord), "Reference shard is not part of forcefield");

    uint128 addedShards = 0;

    for (int32 x = fromShardCoord.x(); x <= toShardCoord.x(); x++) {
      for (int32 y = fromShardCoord.y(); y <= toShardCoord.x(); y++) {
        for (int32 z = fromShardCoord.z(); z <= toShardCoord.x(); z++) {
          Vec3 shardCoord = vec3(x, y, z);
          if (isForceFieldShard(forceFieldEntityId, shardCoord)) {
            continue;
          }
          EntityId shardEntityId = setupForceFieldShard(forceFieldEntityId, shardCoord);
          addedShards++;
        }
      }
    }

    // Increase drain rate per new shard
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + MACHINE_ENERGY_DRAIN_RATE * addedShards);

    // TODO: notifications
    // notify(
    //   playerEntityId,
    //   ExpandForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId, shardEntityId: shardEntityId })
    // );
    //
    // callChipOrRevert(
    //   forceFieldEntityId.getChipAddress(),
    //   abi.encodeCall(IForceFieldChip.onExpand, (playerEntityId, forceFieldEntityId, shardEntityId))
    // );
  }

  function contractForceField(EntityId forceFieldEntityId, Vec3 fromShardCoord, Vec3 toShardCoord) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, forceFieldEntityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");

    // Decrease drain rate
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);

    uint128 removedShards = 0;
    require(fromShardCoord <= toShardCoord, "Invalid coordinates");

    for (int32 x = fromShardCoord.x(); x <= toShardCoord.x(); x++) {
      for (int32 y = fromShardCoord.y(); y <= toShardCoord.x(); y++) {
        for (int32 z = fromShardCoord.z(); z <= toShardCoord.x(); z++) {
          Vec3 shardCoord = vec3(x, y, z);
          // Only count if the shard exists
          if (isForceFieldShard(forceFieldEntityId, shardCoord)) {
            removeForceFieldShard(shardCoord);
            removedShards++;
          }
        }
      }
    }

    // Increase drain rate per new shard
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate - MACHINE_ENERGY_DRAIN_RATE * removedShards);

    // TODO: notifications
    // Notify the player
    // notify(
    //   playerEntityId,
    //   ContractForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId, shardEntityId: shardEntityId })
    // );
    //
    // // Call the chip if it exists
    // callChipOrRevert(
    //   forceFieldEntityId.getChipAddress(),
    //   abi.encodeCall(IForceFieldChip.onContract, (playerEntityId, forceFieldEntityId, shardEntityId))
    // );
  }
}
