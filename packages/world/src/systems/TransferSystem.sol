// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool } from "../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../Constants.sol";
import { mintXP } from "../utils/XPUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";

import { IChestChip } from "../prototypes/IChestChip.sol";

contract TransferSystem is System {
  function transferCommon(
    bytes32 srcEntityId,
    bytes32 dstEntityId
  ) internal returns (bytes32, uint8, VoxelCoord memory) {
    (bytes32 playerEntityId, ) = requireValidPlayer(_msgSender());

    require(dstEntityId != srcEntityId, "TransferSystem: cannot transfer to self");
    VoxelCoord memory srcCoord = positionDataToVoxelCoord(Position._get(srcEntityId));
    VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(dstEntityId));
    require(
      inSurroundingCube(srcCoord, MAX_PLAYER_INFLUENCE_HALF_WIDTH, dstCoord),
      "TransferSystem: destination too far"
    );

    uint8 srcObjectTypeId = ObjectType._get(srcEntityId);
    uint8 dstObjectTypeId = ObjectType._get(dstEntityId);
    if (srcObjectTypeId == PlayerObjectID) {
      require(playerEntityId == srcEntityId, "TransferSystem: player does not own source inventory");
      require(dstObjectTypeId == ChestObjectID, "TransferSystem: cannot transfer to non-chest");
    } else if (dstObjectTypeId == PlayerObjectID) {
      require(playerEntityId == dstEntityId, "TransferSystem: player does not own destination inventory");
      require(srcObjectTypeId == ChestObjectID, "TransferSystem: cannot transfer from non-chest");
    } else {
      revert("TransferSystem: invalid transfer operation");
    }

    return (playerEntityId, dstObjectTypeId, playerEntityId == srcEntityId ? dstCoord : srcCoord);
  }

  function requireAllowed(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
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
        toolEntityId,
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

    (bytes32 playerEntityId, uint8 dstObjectTypeId, VoxelCoord memory chestCoord) = transferCommon(
      srcEntityId,
      dstEntityId
    );
    transferInventoryNonTool(srcEntityId, dstEntityId, dstObjectTypeId, transferObjectTypeId, numToTransfer);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: playerEntityId == srcEntityId ? dstEntityId : srcEntityId,
        objectTypeId: transferObjectTypeId,
        coordX: chestCoord.x,
        coordY: chestCoord.y,
        coordZ: chestCoord.z,
        amount: numToTransfer
      })
    );

    mintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      getForceField(chestCoord),
      playerEntityId,
      srcEntityId,
      dstEntityId,
      transferObjectTypeId,
      numToTransfer,
      bytes32(0),
      extraData
    );
  }

  function transferTool(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 toolEntityId,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, uint8 dstObjectTypeId, VoxelCoord memory chestCoord) = transferCommon(
      srcEntityId,
      dstEntityId
    );
    uint8 toolObjectTypeId = transferInventoryTool(srcEntityId, dstEntityId, dstObjectTypeId, toolEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Transfer,
        entityId: playerEntityId == srcEntityId ? dstEntityId : srcEntityId,
        objectTypeId: toolObjectTypeId,
        coordX: chestCoord.x,
        coordY: chestCoord.y,
        coordZ: chestCoord.z,
        amount: 1
      })
    );

    mintXP(playerEntityId, initialGas, 1);

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    requireAllowed(
      getForceField(chestCoord),
      playerEntityId,
      srcEntityId,
      dstEntityId,
      toolObjectTypeId,
      1,
      toolEntityId,
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
}
