// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, callMintXP } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { canHoldInventory } from "../utils/ObjectTypeUtils.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";

contract TransferSystem is System {
  function transferCommon(
    bytes32 srcEntityId,
    bytes32 dstEntityId
  ) internal returns (bytes32, uint8, bytes32, bytes32, VoxelCoord memory) {
    (bytes32 playerEntityId, ) = requireValidPlayer(_msgSender());

    bytes32 baseSrcEntityId = BaseEntity._get(srcEntityId);
    baseSrcEntityId = baseSrcEntityId == bytes32(0) ? srcEntityId : baseSrcEntityId;

    bytes32 baseDstEntityId = BaseEntity._get(dstEntityId);
    baseDstEntityId = baseDstEntityId == bytes32(0) ? dstEntityId : baseDstEntityId;

    require(baseDstEntityId != baseSrcEntityId, "TransferSystem: cannot transfer to self");
    VoxelCoord memory srcCoord = positionDataToVoxelCoord(Position._get(baseSrcEntityId));
    VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(baseDstEntityId));
    require(
      inSurroundingCube(srcCoord, MAX_PLAYER_INFLUENCE_HALF_WIDTH, dstCoord),
      "TransferSystem: destination too far"
    );

    uint8 srcObjectTypeId = ObjectType._get(baseSrcEntityId);
    uint8 dstObjectTypeId = ObjectType._get(baseDstEntityId);
    if (srcObjectTypeId == PlayerObjectID) {
      require(playerEntityId == baseSrcEntityId, "TransferSystem: player does not own source inventory");
      require(canHoldInventory(dstObjectTypeId), "TransferSystem: this object type does not have an inventory");
    } else if (dstObjectTypeId == PlayerObjectID) {
      require(playerEntityId == baseDstEntityId, "TransferSystem: player does not own destination inventory");
      require(canHoldInventory(srcObjectTypeId), "TransferSystem: this object type does not have an inventory");
    } else {
      revert("TransferSystem: invalid transfer operation");
    }

    return (
      playerEntityId,
      dstObjectTypeId,
      baseSrcEntityId,
      baseDstEntityId,
      playerEntityId == baseSrcEntityId ? dstCoord : srcCoord
    );
  }

  function requireAllowed(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) internal {
    bytes32 chestEntityId = playerEntityId == srcEntityId ? dstEntityId : srcEntityId;
    ChipData memory chipData = updateChipBatteryLevel(chestEntityId);
    uint256 batteryLevel = chipData.batteryLevel;
    if (forceFieldEntityId != bytes32(0)) {
      ChipData memory forceFieldChipData = updateChipBatteryLevel(forceFieldEntityId);
      batteryLevel += forceFieldChipData.batteryLevel;
    }
    if (chipData.chipAddress != address(0) && batteryLevel > 0) {
      // Forward any ether sent with the transaction to the hook
      // Don't safe call here as we want to revert if the chip doesn't allow the transfer
      bool transferAllowed = IChestChip(chipData.chipAddress).onTransfer{ value: _msgValue() }(
        srcEntityId,
        dstEntityId,
        transferObjectTypeId,
        numToTransfer,
        toolEntityIds,
        extraData
      );
      require(transferAllowed, "TransferSystem: Player not authorized by chip to make this transfer");
    }
  }

  function transfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();

    (
      bytes32 playerEntityId,
      uint8 dstObjectTypeId,
      bytes32 baseSrcEntityId,
      bytes32 baseDstEntityId,
      VoxelCoord memory chestCoord
    ) = transferCommon(srcEntityId, dstEntityId);
    transferInventoryNonTool(baseSrcEntityId, baseDstEntityId, dstObjectTypeId, transferObjectTypeId, numToTransfer);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: playerEntityId == baseSrcEntityId ? baseDstEntityId : baseSrcEntityId,
        objectTypeId: transferObjectTypeId,
        coordX: chestCoord.x,
        coordY: chestCoord.y,
        coordZ: chestCoord.z,
        amount: numToTransfer
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      getForceField(chestCoord),
      playerEntityId,
      baseSrcEntityId,
      baseDstEntityId,
      transferObjectTypeId,
      numToTransfer,
      new bytes32[](0),
      extraData
    );
  }

  function transferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 toolEntityId,
    bytes memory extraData
  ) public payable {
    bytes32[] memory toolEntityIds = new bytes32[](1);
    toolEntityIds[0] = toolEntityId;
    transferTools(srcEntityId, dstEntityId, toolEntityIds, extraData);
  }

  function transferTools(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32[] memory toolEntityIds,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();
    require(toolEntityIds.length > 0, "TransferSystem: must transfer at least one tool");
    require(toolEntityIds.length < type(uint16).max, "TransferSystem: too many tools to transfer");

    (
      bytes32 playerEntityId,
      uint8 dstObjectTypeId,
      bytes32 baseSrcEntityId,
      bytes32 baseDstEntityId,
      VoxelCoord memory chestCoord
    ) = transferCommon(srcEntityId, dstEntityId);
    uint8 toolObjectTypeId;
    for (uint i = 0; i < toolEntityIds.length; i++) {
      uint8 currentToolObjectTypeId = transferInventoryTool(
        baseSrcEntityId,
        baseDstEntityId,
        dstObjectTypeId,
        toolEntityIds[i]
      );
      if (i > 0) {
        require(toolObjectTypeId == currentToolObjectTypeId, "TransferSystem: all tools must be of the same type");
      } else {
        toolObjectTypeId = currentToolObjectTypeId;
      }
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: playerEntityId == baseSrcEntityId ? baseDstEntityId : baseSrcEntityId,
        objectTypeId: toolObjectTypeId,
        coordX: chestCoord.x,
        coordY: chestCoord.y,
        coordZ: chestCoord.z,
        amount: toolEntityIds.length
      })
    );

    callMintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      getForceField(chestCoord),
      playerEntityId,
      baseSrcEntityId,
      baseDstEntityId,
      toolObjectTypeId,
      uint16(toolEntityIds.length),
      toolEntityIds,
      extraData
    );
  }

  function transfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer
  ) public payable {
    transfer(srcEntityId, dstEntityId, transferObjectTypeId, numToTransfer, new bytes(0));
  }

  function transferTool(bytes32 srcEntityId, bytes32 dstEntityId, bytes32 toolEntityId) public payable {
    transferTool(srcEntityId, dstEntityId, toolEntityId, new bytes(0));
  }

  function transferTools(bytes32 srcEntityId, bytes32 dstEntityId, bytes32[] memory toolEntityIds) public payable {
    transferTools(srcEntityId, dstEntityId, toolEntityIds, new bytes(0));
  }
}
