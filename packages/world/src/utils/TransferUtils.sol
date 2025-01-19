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

import { PlayerObjectID, PipeObjectID, ForceFieldObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, IN_MAINTENANCE } from "../Constants.sol";
import { updateChipBatteryLevel } from "./ChipUtils.sol";
import { getForceField } from "./ForceFieldUtils.sol";
import { isStorageContainer } from "./ObjectTypeUtils.sol";
import { requireValidPlayer } from "./PlayerUtils.sol";

struct TransferCommonContext {
  bytes32 playerEntityId;
  bytes32 chestEntityId;
  VoxelCoord chestCoord;
  uint8 dstObjectTypeId;
  ChipData checkChipData;
  bool isDeposit;
}

struct PipeTransferCommonContext {
  bytes32 baseSrcEntityId;
  bytes32 baseDstEntityId;
  uint8 srcObjectTypeId;
  uint8 dstObjectTypeId;
  ChipData checkChipData;
  bool isDeposit;
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
      isDeposit: isDeposit
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
    uint8 pathObjectTypeId = ObjectType._get(pathEntityId);
    require(pathObjectTypeId == PipeObjectID, "PipeTransferSystem: path coord is not a pipe");
  }

  // check if last coord and dstCoord are in von neumann distance of 1
  require(
    inVonNeumannNeighborhood(pathCoords[path.length - 1], dstCoord),
    "PipeTransferSystem: last path coord is not in von neumann distance of 1 from dstCoord"
  );
}

function pipeTransferCommon(
  bytes32 srcEntityId,
  bytes32 dstEntityId,
  VoxelCoordDirectionVonNeumann[] memory path
) returns (PipeTransferCommonContext memory) {
  require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");

  bytes32 baseSrcEntityId = BaseEntity._get(srcEntityId);
  baseSrcEntityId = baseSrcEntityId == bytes32(0) ? srcEntityId : baseSrcEntityId;

  bytes32 baseDstEntityId = BaseEntity._get(dstEntityId);
  baseDstEntityId = baseDstEntityId == bytes32(0) ? dstEntityId : baseDstEntityId;

  require(baseDstEntityId != baseSrcEntityId, "PipeTransferSystem: cannot transfer to self");

  uint8 srcObjectTypeId = ObjectType._get(baseSrcEntityId);
  uint8 dstObjectTypeId = ObjectType._get(baseDstEntityId);
  require(isStorageContainer(srcObjectTypeId), "PipeTransferSystem: source object type is not a chest");

  VoxelCoord memory srcCoord = positionDataToVoxelCoord(Position._get(baseSrcEntityId));
  VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(baseDstEntityId));
  requireValidPath(srcCoord, dstCoord, path);

  ChipData memory checkChipData;
  bool isDeposit;
  {
    ChipData memory srcChipData = updateChipBatteryLevel(baseSrcEntityId);
    ChipData memory dstChipData = updateChipBatteryLevel(baseDstEntityId);

    uint256 srcBatteryLevel = srcChipData.batteryLevel;
    uint256 dstBatteryLevel = dstChipData.batteryLevel;

    if (srcObjectTypeId != ForceFieldObjectID) {
      bytes32 srcForceFieldEntityId = getForceField(srcCoord);
      if (srcForceFieldEntityId != bytes32(0)) {
        ChipData memory srcForceFieldChipData = updateChipBatteryLevel(srcForceFieldEntityId);
        srcBatteryLevel += srcForceFieldChipData.batteryLevel;
      }
    }

    if (dstObjectTypeId != ForceFieldObjectID) {
      bytes32 dstForceFieldEntityId = getForceField(dstCoord);
      if (dstForceFieldEntityId != bytes32(0)) {
        ChipData memory dstForceFieldChipData = updateChipBatteryLevel(dstForceFieldEntityId);
        dstBatteryLevel += dstForceFieldChipData.batteryLevel;
      }
    }

    address caller = WorldContextConsumerLib._msgSender();
    if (srcChipData.chipAddress == caller) {
      isDeposit = true;
      require(srcBatteryLevel > 0, "PipeTransferSystem: caller has no charge");
      checkChipData = dstChipData;
      checkChipData.batteryLevel = dstBatteryLevel;
    } else if (dstChipData.chipAddress == caller) {
      isDeposit = false;
      require(dstBatteryLevel > 0, "PipeTransferSystem: caller has no charge");
      checkChipData = srcChipData;
      checkChipData.batteryLevel = srcBatteryLevel;
    } else {
      revert("PipeTransferSystem: caller is not the chip of the source or destination smart item");
    }
  }

  return
    PipeTransferCommonContext({
      baseSrcEntityId: baseSrcEntityId,
      baseDstEntityId: baseDstEntityId,
      srcObjectTypeId: srcObjectTypeId,
      dstObjectTypeId: dstObjectTypeId,
      checkChipData: checkChipData,
      isDeposit: isDeposit
    });
}
