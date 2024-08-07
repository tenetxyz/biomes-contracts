// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { requireInterface } from "@latticexyz/world/src/requireInterface.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { PLAYER_HAND_DAMAGE, HIT_STAMINA_COST, TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "../Constants.sol";
import { PlayerObjectID, ChipObjectID, ChipBatteryObjectID, ChestObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer } from "../utils/PlayerUtils.sol";
import { canAttachChip } from "../utils/ObjectTypeUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";

import { IChip } from "../prototypes/IChip.sol";

contract ChipSystem is System {
  function attachChip(bytes32 entityId, address chipAddress) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireBesidePlayer(playerCoord, entityId);

    uint8 objectTypeId = ObjectType._get(entityId);
    require(canAttachChip(objectTypeId), "ChipSystem: cannot attach a chip to this object");
    require(Chip._getChipAddress(entityId) == address(0), "ChipSystem: chip already attached");

    require(chipAddress != address(0), "ChipSystem: invalid chip address");
    requireInterface(chipAddress, type(IChip).interfaceId);

    removeFromInventoryCount(playerEntityId, ChipObjectID, 1);

    Chip._set(entityId, ChipData({ chipAddress: chipAddress, batteryLevel: 0, lastUpdatedTime: block.timestamp }));

    // Don't safe call here because we want to revert if the chip doesn't allow the attachment
    IChip(chipAddress).onAttached(playerEntityId, entityId);
  }

  function detachChip(bytes32 entityId) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireBesidePlayer(playerCoord, entityId);

    ChipData memory chipData = updateChipBatteryLevel(entityId);
    require(chipData.batteryLevel == 0, "ChipSystem: battery level is not zero");
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");

    addToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);

    Chip._deleteRecord(entityId);

    // TODO: Figure out a way to accurately estimate gas in the client to then change this to be a safe call instead
    // chipData.chipAddress.call(abi.encodeCall(IChip.onDetached, (playerEntityId, entityId)));
    IChip(chipData.chipAddress).onDetached(playerEntityId, entityId);
  }

  function powerChip(bytes32 entityId, uint16 numBattery) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireBesidePlayer(playerCoord, entityId);

    ChipData memory chipData = updateChipBatteryLevel(entityId);
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");

    removeFromInventoryCount(playerEntityId, ChipBatteryObjectID, numBattery);

    uint8 objectTypeId = ObjectType._get(entityId);
    uint256 increasePerBattery = 0;
    if (objectTypeId == ForceFieldObjectID) {
      // 1 battery adds 2 days of charge
      increasePerBattery = 2 days;
    } else if (objectTypeId == ChestObjectID) {
      // 1 battery adds 1 week of charge
      increasePerBattery = 1 weeks;
    } else {
      revert("ChipSystem: cannot power this object");
    }
    uint256 newBatteryLevel = chipData.batteryLevel + (uint256(numBattery) * increasePerBattery);

    Chip._setBatteryLevel(entityId, newBatteryLevel);
    Chip._setLastUpdatedTime(entityId, block.timestamp);

    // TODO: Figure out a way to accurately estimate gas in the client to then change this to be a safe call instead
    // chipData.chipAddress.call(abi.encodeCall(IChip.onPowered, (playerEntityId, entityId, numBattery)));
    IChip(chipData.chipAddress).onPowered(playerEntityId, entityId, numBattery);
  }

  function hitChip(bytes32 entityId) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireBesidePlayer(playerCoord, entityId);

    ChipData memory chipData = updateChipBatteryLevel(entityId);
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");

    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint16 staminaRequired = HIT_STAMINA_COST;
    require(currentStamina >= staminaRequired, "ChipSystem: player does not have enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    uint16 receiverDamage = PLAYER_HAND_DAMAGE;
    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    if (equippedEntityId != bytes32(0)) {
      receiverDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }

    useEquipped(playerEntityId, equippedEntityId);

    uint256 currentBatteryLevel = chipData.batteryLevel;
    uint256 newBatteryLevel = currentBatteryLevel > receiverDamage ? currentBatteryLevel - receiverDamage : 0;
    if (newBatteryLevel == 0) {
      addToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);

      Chip._deleteRecord(entityId);

      // TODO: Figure out a way to accurately estimate gas in the client to then change this to be a safe call instead
      // chipData.chipAddress.call(abi.encodeCall(IChip.onDetached, (playerEntityId, entityId)));
      IChip(chipData.chipAddress).onDetached(playerEntityId, entityId);
    } else {
      Chip._setBatteryLevel(entityId, newBatteryLevel);

      // TODO: Figure out a way to accurately estimate gas in the client to then change this to be a safe call instead
      // chipData.chipAddress.call(abi.encodeCall(IChip.onChipHit, (playerEntityId, entityId)));
      IChip(chipData.chipAddress).onChipHit(playerEntityId, entityId);
    }
  }
}
