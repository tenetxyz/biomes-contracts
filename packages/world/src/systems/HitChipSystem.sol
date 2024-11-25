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
import { PlayerObjectID, ChipObjectID, ChipBatteryObjectID, ChestObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { positionDataToVoxelCoord, safeCallChip, callMintXP, getL1GasPrice } from "../Utils.sol";

import { IChip } from "../prototypes/IChip.sol";

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

    // uint256 l1GasPriceWei = getL1GasPrice();
    // // Ensure that the gas price is at least 8 gwei
    // if (l1GasPriceWei < 8 gwei) {
    //   l1GasPriceWei = 8 gwei;
    // }

    uint256 decreaseBatteryLevel = (receiverDamage * 117) / 100;
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

    callMintXP(playerEntityId, initialGas, 1);

    safeCallChip(chipData.chipAddress, abi.encodeCall(IChip.onChipHit, (playerEntityId, chipEntityId)));
  }

  function hitChippedEntity(bytes32 entityId) public {
    uint256 initialGas = gasleft();
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    hitChipCommon(initialGas, playerEntityId, baseEntityId, entityCoord);
  }

  function hitForceField(VoxelCoord memory entityCoord) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, entityCoord);
    bytes32 forceFieldEntityId = getForceField(entityCoord);
    require(forceFieldEntityId != bytes32(0), "ChipSystem: no force field at this location");
    VoxelCoord memory forceFieldCoord = positionDataToVoxelCoord(Position._get(forceFieldEntityId));
    hitChipCommon(initialGas, playerEntityId, forceFieldEntityId, forceFieldCoord);
  }
}
