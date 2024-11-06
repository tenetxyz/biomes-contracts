// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PLAYER_HAND_DAMAGE, HIT_CHIP_STAMINA_COST, TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "../Constants.sol";
import { PlayerObjectID, ChipObjectID, ChipBatteryObjectID, ChestObjectID, ForceFieldObjectID, TextSignObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount, useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { safeCallChip, callMintXP } from "../Utils.sol";

import { IChip } from "../prototypes/IChip.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { IDisplayChip } from "../prototypes/IDisplayChip.sol";

contract ChipSystem is System {
  function attachChip(bytes32 entityId, address chipAddress, bytes memory extraData) public payable {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    uint8 objectTypeId = ObjectType._get(baseEntityId);
    ChipData memory chipData = updateChipBatteryLevel(baseEntityId);
    require(chipData.chipAddress == address(0), "ChipSystem: chip already attached");
    require(chipAddress != address(0), "ChipSystem: invalid chip address");

    if (objectTypeId == ChestObjectID) {
      require(
        ERC165Checker.supportsInterface(chipAddress, type(IChestChip).interfaceId),
        "ChipSystem: chip does not implement the required interface"
      );
    } else if (objectTypeId == ForceFieldObjectID) {
      require(
        ERC165Checker.supportsInterface(chipAddress, type(IForceFieldChip).interfaceId),
        "ChipSystem: chip does not implement the required interface"
      );
    } else if (objectTypeId == TextSignObjectID) {
      require(
        ERC165Checker.supportsInterface(chipAddress, type(IDisplayChip).interfaceId),
        "ChipSystem: chip does not implement the required interface"
      );
    } else {
      revert("ChipSystem: cannot attach a chip to this object");
    }

    removeFromInventoryCount(playerEntityId, ChipObjectID, 1);

    Chip._setChipAddress(baseEntityId, chipAddress);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.AttachChip,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: entityCoord.x,
        coordY: entityCoord.y,
        coordZ: entityCoord.z,
        amount: 1
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    // Don't safe call here because we want to revert if the chip doesn't allow the attachment
    bool isAllowed = IChip(chipAddress).onAttached{ value: _msgValue() }(playerEntityId, baseEntityId, extraData);
    require(isAllowed, "ChipSystem: chip does not allow attachment");
  }

  function attachChip(bytes32 entityId, address chipAddress) public {
    attachChip(entityId, chipAddress, new bytes(0));
  }

  function detachChip(bytes32 entityId, bytes memory extraData) public payable {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    ChipData memory chipData = updateChipBatteryLevel(baseEntityId);
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");

    uint8 objectTypeId = ObjectType._get(baseEntityId);

    addToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);

    Chip._setChipAddress(baseEntityId, address(0));

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.DetachChip,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: entityCoord.x,
        coordY: entityCoord.y,
        coordZ: entityCoord.z,
        amount: 1
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    if (chipData.batteryLevel > 0) {
      // Don't safe call here because we want to revert if the chip doesn't allow the detachment
      bool isAllowed = IChip(chipData.chipAddress).onDetached{ value: _msgValue() }(
        playerEntityId,
        baseEntityId,
        extraData
      );
      require(isAllowed, "ChipSystem: chip does not allow detachment");
    } else {
      safeCallChip(chipData.chipAddress, abi.encodeCall(IChip.onDetached, (playerEntityId, baseEntityId, extraData)));
    }
  }

  function detachChip(bytes32 entityId) public {
    detachChip(entityId, new bytes(0));
  }

  function powerChip(bytes32 entityId, uint16 numBattery) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);

    bytes32 baseEntityId = BaseEntity._get(entityId);
    baseEntityId = baseEntityId == bytes32(0) ? entityId : baseEntityId;

    ChipData memory chipData = updateChipBatteryLevel(baseEntityId);
    require(chipData.chipAddress != address(0), "ChipSystem: no chip attached");
    removeFromInventoryCount(playerEntityId, ChipBatteryObjectID, numBattery);

    uint8 objectTypeId = ObjectType._get(baseEntityId);
    require(objectTypeId == ForceFieldObjectID, "ChipSystem: cannot power this object");
    uint256 increasePerBattery = 4 days;
    uint256 newBatteryLevel = chipData.batteryLevel + (uint256(numBattery) * increasePerBattery);

    Chip._setBatteryLevel(baseEntityId, newBatteryLevel);
    Chip._setLastUpdatedTime(baseEntityId, block.timestamp);

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

    callMintXP(playerEntityId, initialGas, 1);

    safeCallChip(chipData.chipAddress, abi.encodeCall(IChip.onPowered, (playerEntityId, baseEntityId, numBattery)));
  }

  function hitChip(bytes32 entityId) public {
    revert("ChipSystem: renamed to hitChippedEntity");
  }
}
