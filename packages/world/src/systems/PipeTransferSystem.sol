// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { transformVoxelCoordVonNeumann, inVonNeumannNeighborhood } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { ChipBatteryObjectID, ForceFieldObjectID, PipeObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../Utils.sol";
import { transferInventoryTool, transferInventoryNonTool, addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { canHoldInventory } from "../utils/ObjectTypeUtils.sol";

import { IN_MAINTENANCE } from "../Constants.sol";

import { IChestChip } from "../prototypes/IChestChip.sol";

contract PipeTransferSystem is System {
  function pipeTransferCommon(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path
  ) internal returns (bytes32, uint8, bytes32, uint8) {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");

    bytes32 baseSrcEntityId = BaseEntity._get(srcEntityId);
    baseSrcEntityId = baseSrcEntityId == bytes32(0) ? srcEntityId : baseSrcEntityId;

    bytes32 baseDstEntityId = BaseEntity._get(dstEntityId);
    baseDstEntityId = baseDstEntityId == bytes32(0) ? dstEntityId : baseDstEntityId;

    require(baseDstEntityId != baseSrcEntityId, "PipeTransferSystem: cannot transfer to self");

    ChipData memory srcChipData = updateChipBatteryLevel(baseSrcEntityId);
    ChipData memory dstChipData = updateChipBatteryLevel(baseDstEntityId);

    VoxelCoord memory srcCoord = positionDataToVoxelCoord(Position._get(baseSrcEntityId));
    VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(baseDstEntityId));

    uint8 srcObjectTypeId = ObjectType._get(baseSrcEntityId);
    uint8 dstObjectTypeId = ObjectType._get(baseDstEntityId);

    {
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

      address caller = _msgSender();
      if (srcChipData.chipAddress == caller) {
        require(srcBatteryLevel > 0, "PipeTransferSystem: source chest has no charge");
      } else if (dstChipData.chipAddress == caller) {
        require(dstBatteryLevel > 0, "PipeTransferSystem: destination chest has no charge");
      } else {
        revert("PipeTransferSystem: caller is not the chip of the source or destination smart item");
      }
    }

    require(canHoldInventory(srcObjectTypeId), "Source object type is not a chest");

    requireValidPath(srcCoord, dstCoord, path);

    return (baseSrcEntityId, srcObjectTypeId, baseDstEntityId, dstObjectTypeId);
  }

  function requireValidPath(
    VoxelCoord memory srcCoord,
    VoxelCoord memory dstCoord,
    VoxelCoordDirectionVonNeumann[] memory path
  ) internal view {
    require(path.length > 0, "Path must be greater than 0");
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

  function pipeTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    VoxelCoordDirectionVonNeumann[] memory path,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes memory extraData
  ) public payable {
    uint256 initialGas = gasleft();

    (
      bytes32 baseSrcEntityId,
      uint8 srcObjectTypeId,
      bytes32 baseDstEntityId,
      uint8 dstObjectTypeId
    ) = pipeTransferCommon(srcEntityId, dstEntityId, path);

    require(!ObjectTypeMetadata._getIsTool(transferObjectTypeId), "Object type is not a block");
    require(numToTransfer > 0, "Amount must be greater than 0");
    removeFromInventoryCount(srcEntityId, transferObjectTypeId, numToTransfer);

    if (canHoldInventory(dstObjectTypeId)) {
      addToInventoryCount(dstEntityId, dstObjectTypeId, transferObjectTypeId, numToTransfer);
    } else if (dstObjectTypeId == ForceFieldObjectID) {
      require(transferObjectTypeId == ChipBatteryObjectID, "Force field can only accept chip batteries");
    } else {
      revert("PipeTransferSystem: destination object type is not valid");
    }

    // Note: we call this after the transfer state has been updated, to prevent re-entrancy attacks
    // requireAllowed(
    //   getForceField(chestCoord),
    //   playerEntityId,
    //   baseSrcEntityId,
    //   baseDstEntityId,
    //   transferObjectTypeId,
    //   numToTransfer,
    //   new bytes32[](0),
    //   extraData
    // );
  }
}
