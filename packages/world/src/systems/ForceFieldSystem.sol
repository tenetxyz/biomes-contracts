// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ForceField } from "../utils/Vec3Storage.sol";

import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateEnergyLevel } from "../utils/EnergyUtils.sol";
import { getUniqueEntity } from "../Utils.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { notify, ExpandForceFieldNotifData } from "../utils/NotifUtils.sol";

import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { MACHINE_ENERGY_DRAIN_RATE } from "../Constants.sol";

contract ForceFieldSystem is System {
  function expandForceField(EntityId forceFieldEntityId, Vec3 shardCoord) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());
    // TODO: check close to shard? or close to forcefield block?
    // VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);

    ObjectTypeId objectTypeId = ObjectType._get(forceFieldEntityId);
    require(objectTypeId == ObjectTypes.ForceField, "Invalid object type");
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);

    // Increase drain rate per new shard
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + MACHINE_ENERGY_DRAIN_RATE);

    EntityId shardEntityId = getUniqueEntity();
    ForceField._set(shardCoord, shardEntityId);
    BaseEntity._set(shardEntityId, forceFieldEntityId);

    notify(
      playerEntityId,
      ExpandForceFieldNotifData({ forceFieldEntityId: forceFieldEntityId, shardEntityId: shardEntityId })
    );

    callChipOrRevert(
      forceFieldEntityId.getChipAddress(),
      abi.encodeCall(IForceFieldChip.onExpand, (playerEntityId, forceFieldEntityId, shardEntityId))
    );
  }
}
