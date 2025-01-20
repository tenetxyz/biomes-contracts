// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, transformVoxelCoordVonNeumann, inVonNeumannNeighborhood } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { PlayerObjectID, PipeObjectID, ForceFieldObjectID, ChipBatteryObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, safeCallChip } from "../Utils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, CHARGE_PER_BATTERY } from "../Constants.sol";
import { ChipOnPipeTransferData, PipeTransferData } from "../Types.sol";
import { updateChipBatteryLevel } from "./ChipUtils.sol";
import { getForceField } from "./ForceFieldUtils.sol";
import { isStorageContainer } from "./ObjectTypeUtils.sol";
import { requireValidPlayer } from "./PlayerUtils.sol";
import { transferInventoryTool, transferInventoryNonTool, addToInventoryCount, removeFromInventoryCount } from "./InventoryUtils.sol";

import { IChip } from "../prototypes/IChip.sol";

struct TransferCommonContext {
  bytes32 playerEntityId;
  bytes32 chestEntityId;
  VoxelCoord chestCoord;
  uint8 chestObjectTypeId;
  uint8 dstObjectTypeId;
  ChipData checkChipData;
  bool isDeposit;
}

struct PipeTransferCommonContext {
  VoxelCoord targetCoord;
  ChipData targetChipData;
  uint8 targetObjectTypeId;
}

function transferCommon(bytes32 srcEntityId, bytes32 dstEntityId) returns (TransferCommonContext memory) {
  (bytes32 playerEntityId, ) = requireValidPlayer(WorldContextConsumerLib._msgSender());

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
  bool isDeposit = false;
  if (srcObjectTypeId == PlayerObjectID) {
    require(playerEntityId == baseSrcEntityId, "TransferSystem: player does not own source inventory");
    require(isStorageContainer(dstObjectTypeId), "TransferSystem: this object type does not have an inventory");
    isDeposit = true;
  } else if (dstObjectTypeId == PlayerObjectID) {
    require(playerEntityId == baseDstEntityId, "TransferSystem: player does not own destination inventory");
    require(isStorageContainer(srcObjectTypeId), "TransferSystem: this object type does not have an inventory");
    isDeposit = false;
  } else {
    revert("TransferSystem: invalid transfer operation");
  }

  bytes32 chestEntityId = isDeposit ? baseDstEntityId : baseSrcEntityId;
  VoxelCoord memory chestCoord = isDeposit ? dstCoord : srcCoord;

  ChipData memory checkChipData = updateChipBatteryLevel(chestEntityId);
  bytes32 forceFieldEntityId = getForceField(chestCoord);
  if (forceFieldEntityId != bytes32(0)) {
    ChipData memory forceFieldChipData = updateChipBatteryLevel(forceFieldEntityId);
    checkChipData.batteryLevel += forceFieldChipData.batteryLevel;
  }

  return
    TransferCommonContext({
      playerEntityId: playerEntityId,
      chestEntityId: chestEntityId,
      chestCoord: chestCoord,
      dstObjectTypeId: dstObjectTypeId,
      checkChipData: checkChipData,
      isDeposit: isDeposit,
      chestObjectTypeId: isDeposit ? dstObjectTypeId : srcObjectTypeId
    });
}

function requireValidPath(
  VoxelCoord memory srcCoord,
  VoxelCoord memory dstCoord,
  VoxelCoordDirectionVonNeumann[] memory path
) view {
  require(path.length > 0, "PipeTransferSystem: path must be greater than 0");
  VoxelCoord[] memory pathCoords = new VoxelCoord[](path.length);
  for (uint i = 0; i < path.length; i++) {
    pathCoords[i] = transformVoxelCoordVonNeumann(i == 0 ? srcCoord : pathCoords[i - 1], path[i]);
    bytes32 pathEntityId = ReversePosition._get(pathCoords[i].x, pathCoords[i].y, pathCoords[i].z);
    require(pathEntityId != bytes32(0), "PipeTransferSystem: path coord is not in the world");
    require(ObjectType._get(pathEntityId) == PipeObjectID, "PipeTransferSystem: path coord is not a pipe");
  }

  // check if last coord and dstCoord are in von neumann distance of 1
  require(
    inVonNeumannNeighborhood(pathCoords[path.length - 1], dstCoord),
    "PipeTransferSystem: last path coord is not in von neumann distance of 1 from dstCoord"
  );
}

function pipeTransferCommon(
  bytes32 callerEntityId,
  uint8 callerObjectTypeId,
  VoxelCoord memory callerCoord,
  bool isDeposit,
  PipeTransferData memory pipeTransferData
) returns (PipeTransferCommonContext memory) {
  require(pipeTransferData.targetEntityId != callerEntityId, "PipeTransferSystem: cannot transfer to self");
  VoxelCoord memory targetCoord = positionDataToVoxelCoord(Position._get(pipeTransferData.targetEntityId));
  ChipData memory targetChipData = updateChipBatteryLevel(pipeTransferData.targetEntityId);
  uint8 targetObjectTypeId = ObjectType._get(pipeTransferData.targetEntityId);
  if (targetObjectTypeId != ForceFieldObjectID) {
    bytes32 targetForceFieldEntityId = getForceField(targetCoord);
    if (targetForceFieldEntityId != bytes32(0)) {
      ChipData memory targetForceFieldChipData = updateChipBatteryLevel(targetForceFieldEntityId);
      targetChipData.batteryLevel += targetForceFieldChipData.batteryLevel;
    }
  }

  requireValidPath(isDeposit ? callerCoord : targetCoord, isDeposit ? targetCoord : callerCoord, pipeTransferData.path);

  if (pipeTransferData.transferData.toolEntityIds.length == 0) {
    require(
      !ObjectTypeMetadata._getIsTool(pipeTransferData.transferData.objectTypeId),
      "PipeTransferSystem: object type is not a block"
    );
    require(pipeTransferData.transferData.numToTransfer > 0, "PipeTransferSystem: amount must be greater than 0");

    if (isDeposit) {
      removeFromInventoryCount(
        callerEntityId,
        pipeTransferData.transferData.objectTypeId,
        pipeTransferData.transferData.numToTransfer
      );

      if (isStorageContainer(targetObjectTypeId)) {
        addToInventoryCount(
          pipeTransferData.targetEntityId,
          targetObjectTypeId,
          pipeTransferData.transferData.objectTypeId,
          pipeTransferData.transferData.numToTransfer
        );
      } else if (targetObjectTypeId == ForceFieldObjectID) {
        require(
          pipeTransferData.transferData.objectTypeId == ChipBatteryObjectID,
          "PipeTransferSystem: force field can only accept chip batteries"
        );
        uint256 newBatteryLevel = targetChipData.batteryLevel +
          (uint256(pipeTransferData.transferData.numToTransfer) * CHARGE_PER_BATTERY);

        Chip._setBatteryLevel(pipeTransferData.targetEntityId, newBatteryLevel);
        Chip._setLastUpdatedTime(pipeTransferData.targetEntityId, block.timestamp);

        safeCallChip(
          targetChipData.chipAddress,
          abi.encodeCall(
            IChip.onPowered,
            (callerEntityId, pipeTransferData.targetEntityId, pipeTransferData.transferData.numToTransfer)
          )
        );
      } else {
        revert("PipeTransferSystem: target object type is not valid");
      }
    } else {
      addToInventoryCount(
        callerEntityId,
        callerObjectTypeId,
        pipeTransferData.transferData.objectTypeId,
        pipeTransferData.transferData.numToTransfer
      );

      if (isStorageContainer(targetObjectTypeId)) {
        removeFromInventoryCount(
          pipeTransferData.targetEntityId,
          pipeTransferData.transferData.objectTypeId,
          pipeTransferData.transferData.numToTransfer
        );
      } else {
        revert("PipeTransferSystem: target object type is not valid");
      }
    }
  } else {
    require(pipeTransferData.transferData.toolEntityIds.length > 0, "PipeTransferSystem: no tools to transfer");
    require(
      pipeTransferData.transferData.toolEntityIds.length < type(uint16).max,
      "PipeTransferSystem: too many tools to transfer"
    );
    require(
      pipeTransferData.transferData.toolEntityIds.length == pipeTransferData.transferData.numToTransfer,
      "PipeTransferSystem: number of tools to transfer must match number of tools"
    );

    for (uint i = 0; i < pipeTransferData.transferData.toolEntityIds.length; i++) {
      uint8 toolObjectTypeId = transferInventoryTool(
        isDeposit ? callerEntityId : pipeTransferData.targetEntityId,
        isDeposit ? pipeTransferData.targetEntityId : callerEntityId,
        isDeposit ? targetObjectTypeId : callerObjectTypeId,
        pipeTransferData.transferData.toolEntityIds[i]
      );
      require(
        toolObjectTypeId == pipeTransferData.transferData.objectTypeId,
        "PipeTransferSystem: all tools must be of the same type"
      );
    }
  }

  return
    PipeTransferCommonContext({
      targetCoord: targetCoord,
      targetChipData: targetChipData,
      targetObjectTypeId: targetObjectTypeId
    });
}
