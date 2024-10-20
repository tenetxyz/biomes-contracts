// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PLAYER_HAND_DAMAGE, HIT_CHIP_STAMINA_COST, TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "../Constants.sol";
import { PlayerObjectID, ChipObjectID, ChipBatteryObjectID, ChestObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { mintXP } from "../utils/XPUtils.sol";
import { positionDataToVoxelCoord, safeCallChip } from "../Utils.sol";

import { IChip } from "../prototypes/IChip.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";

contract HitChipSystem is System {
  function hitChipCommon(
    uint256 initialGas,
    bytes32 playerEntityId,
    bytes32 chipEntityId,
    VoxelCoord memory chipCoord
  ) internal {
    ChipData memory chipData = updateChipBatteryLevel(chipEntityId);
    if (chipData.batteryLevel == 0) {
      return;
    }

    uint8 objectTypeId = ObjectType._get(chipEntityId);

    {
      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      uint16 staminaRequired = HIT_CHIP_STAMINA_COST;
      require(currentStamina >= staminaRequired, "ChipSystem: player does not have enough stamina");
      Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);
    }

    uint16 receiverDamage = PLAYER_HAND_DAMAGE;
    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    if (equippedEntityId != bytes32(0)) {
      receiverDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }
    useEquipped(playerEntityId, equippedEntityId);

    uint256 decreaseBatteryLevel = 0;
    if (objectTypeId == ForceFieldObjectID) {
      decreaseBatteryLevel = (72 * uint256(receiverDamage) * 60) / 120;
    } else if (objectTypeId == ChestObjectID) {
      decreaseBatteryLevel = (252 * uint256(receiverDamage) * 60) / 120;
    } else {
      revert("ChipSystem: cannot hit this object");
    }
    uint256 newBatteryLevel = chipData.batteryLevel > decreaseBatteryLevel
      ? chipData.batteryLevel - decreaseBatteryLevel
      : 0;
    Chip._setBatteryLevel(chipEntityId, newBatteryLevel);

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

    mintXP(playerEntityId, initialGas, 1);

    safeCallChip(chipData.chipAddress, abi.encodeCall(IChip.onChipHit, (playerEntityId, chipEntityId)));
  }

  function hitChip(bytes32 entityId) public {
    uint256 initialGas = gasleft();
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    hitChipCommon(initialGas, playerEntityId, entityId, entityCoord);
  }

  function hitForceField(bytes32 entityId) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    bytes32 forceFieldEntityId = getForceField(entityCoord);
    require(forceFieldEntityId != bytes32(0), "ChipSystem: no force field at this location");
    VoxelCoord memory forceFieldCoord = positionDataToVoxelCoord(Position._get(forceFieldEntityId));
    hitChipCommon(initialGas, playerEntityId, forceFieldEntityId, forceFieldCoord);
  }
}
