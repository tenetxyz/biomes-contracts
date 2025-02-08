// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PLAYER_HAND_DAMAGE, HIT_CHIP_STAMINA_COST, TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "../Constants.sol";
import { PlayerObjectID, ChipObjectID, ChipBatteryObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { isWhacker } from "../utils/ObjectTypeUtils.sol";
import { positionDataToVoxelCoord, safeCallChip, callMintXP } from "../Utils.sol";

import { IChip } from "../prototypes/IChip.sol";

contract HitMachineSystem is System {
  function hitMachineCommon(bytes32 playerEntityId, bytes32 machineEntityId, VoxelCoord memory machineCoord) internal {
    EnergyData memory machineData = updateMachineEnergyLevel(machineEntityId);
    if (machineData.energyLevel == 0) {
      return;
    }

    uint16 objectTypeId = ObjectType._get(machineEntityId);
    uint16 miningDifficulty = ObjectTypeMetadata._getMass(objectTypeId);

    // TODO: decrease energy

    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    require(equippedEntityId != bytes32(0), "You must use a whacker to hit machines");
    uint16 equippedObjectTypeId = ObjectType._get(equippedEntityId);
    require(isWhacker(equippedObjectTypeId), "You must use a whacker to hit machines");
    uint16 equippedToolDamage = ObjectTypeMetadata._getDamage(equippedObjectTypeId);
    useEquipped(
      playerEntityId,
      equippedEntityId,
      equippedObjectTypeId,
      (uint24(miningDifficulty) * uint24(1000)) / equippedToolDamage
    );

    uint256 decreaseEnergyLevel = (equippedToolDamage * 117) / 100;
    uint256 newEnergyLevel = machineData.energyLevel > decreaseEnergyLevel
      ? machineData.energyLevel - decreaseEnergyLevel
      : 0;
    Energy._setEnergyLevel(machineEntityId, newEnergyLevel);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.HitChip,
        entityId: chipEntityId,
        objectTypeId: objectTypeId,
        coordX: chipCoord.x,
        coordY: chipCoord.y,
        coordZ: chipCoord.z,
        amount: newBatteryLevel
      })
    );

    safeCallChip(
      Chip._getChipAddress(machineEntityId),
      abi.encodeCall(IChip.onChipHit, (playerEntityId, machineEntityId))
    );
  }

  function hitMachine(bytes32 entityId) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    hitMachineCommon(playerEntityId, baseEntityId, entityCoord);
  }

  function hitForceField(VoxelCoord memory entityCoord) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, entityCoord);
    bytes32 forceFieldEntityId = getForceField(entityCoord);
    require(forceFieldEntityId != bytes32(0), "No force field at this location");
    VoxelCoord memory forceFieldCoord = positionDataToVoxelCoord(Position._get(forceFieldEntityId));
    hitMachineCommon(playerEntityId, forceFieldEntityId, forceFieldCoord);
  }
}
