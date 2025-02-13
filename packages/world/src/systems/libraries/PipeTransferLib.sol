// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "../../VoxelCoord.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectCategory } from "../../codegen/common.sol";

import { PlayerObjectID, PipeObjectID, ForceFieldObjectID, ChipBatteryObjectID } from "../../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../../Utils.sol";
import { callChip } from "../../utils/callChip.sol";
import { ChipOnPipeTransferData, PipeTransferData, PipeTransferCommonContext } from "../../Types.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";
import { isStorageContainer } from "../../utils/ObjectTypeUtils.sol";
import { transferInventoryEntity, transferInventoryNonEntity, addToInventoryCount, removeFromInventoryCount } from "../../utils/InventoryUtils.sol";

import { IForceFieldChip } from "../../prototypes/IForceFieldChip.sol";
import { EntityId } from "../../EntityId.sol";

library PipeTransferLib {
  // Validates that the path is non-empty and all coordinates correspond to pipes,
  // and that the last coordinate is adjacent to the destination.
  function validatePath(
    VoxelCoord memory src,
    VoxelCoord memory dst,
    VoxelCoordDirectionVonNeumann[] memory path
  ) internal view {
    require(path.length > 0, "Path must not be empty");
    VoxelCoord memory current = src;
    for (uint i = 0; i < path.length; i++) {
      current = current.transform(path[i]);
      EntityId entity = ReversePosition._get(current.x, current.y, current.z);
      require(entity.exists(), "Path coordinate missing in world");
      require(ObjectType._get(entity) == PipeObjectID, "Coordinate is not a pipe");
    }
    require(current.inVonNeumannNeighborhood(dst), "Destination not adjacent to last path coord");
  }

  function pipeTransferCommon(
    EntityId callerEntityId,
    uint16 callerObjectTypeId,
    VoxelCoord memory callerCoord,
    bool isDeposit,
    PipeTransferData memory pipeTransferData
  ) public returns (PipeTransferCommonContext memory) {
    require(pipeTransferData.targetEntityId != callerEntityId, "Cannot transfer to self");
    require(pipeTransferData.transferData.numToTransfer > 0, "Amount must be greater than 0");
    VoxelCoord memory targetCoord = positionDataToVoxelCoord(Position._get(pipeTransferData.targetEntityId));
    uint16 targetObjectTypeId = ObjectType._get(pipeTransferData.targetEntityId);
    uint128 machineEnergyLevel = 0;
    EntityId targetForceFieldEntityId = getForceField(targetCoord);
    if (targetForceFieldEntityId.exists()) {
      EnergyData memory machineData = updateMachineEnergyLevel(targetForceFieldEntityId);
      machineEnergyLevel = machineData.energy;
    }

    validatePath(isDeposit ? callerCoord : targetCoord, isDeposit ? targetCoord : callerCoord, pipeTransferData.path);

    // TODO: Apply cost for using pipes

    if (pipeTransferData.transferData.toolEntityIds.length == 0) {
      require(
        ObjectTypeMetadata._getObjectCategory(pipeTransferData.transferData.objectTypeId) == ObjectCategory.Block,
        "Object type is not a block"
      );
      require(pipeTransferData.transferData.numToTransfer > 0, "Amount must be greater than 0");

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
            "Force field can only accept chip batteries"
          );
          uint128 newEnergyLevel = machineEnergyLevel + (uint128(pipeTransferData.transferData.numToTransfer) * 10);

          Energy._set(
            pipeTransferData.targetEntityId,
            EnergyData({ energy: newEnergyLevel, lastUpdatedTime: uint128(block.timestamp) })
          );

          // TODO: Should this revert?
          callChip(
            pipeTransferData.targetEntityId,
            abi.encodeCall(
              IForceFieldChip.onPowered,
              (callerEntityId, pipeTransferData.targetEntityId, pipeTransferData.transferData.numToTransfer)
            )
          );
        } else {
          revert("Target object type is not valid");
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
          revert("Target object type is not valid");
        }
      }
    } else {
      require(pipeTransferData.transferData.toolEntityIds.length > 0, "No tools to transfer");
      require(
        pipeTransferData.transferData.toolEntityIds.length == pipeTransferData.transferData.numToTransfer,
        "Number of tools to transfer must match number of tools"
      );

      for (uint i = 0; i < pipeTransferData.transferData.toolEntityIds.length; i++) {
        uint16 toolObjectTypeId = transferInventoryEntity(
          isDeposit ? callerEntityId : pipeTransferData.targetEntityId,
          isDeposit ? pipeTransferData.targetEntityId : callerEntityId,
          isDeposit ? targetObjectTypeId : callerObjectTypeId,
          pipeTransferData.transferData.toolEntityIds[i]
        );
        require(toolObjectTypeId == pipeTransferData.transferData.objectTypeId, "All tools must be of the same type");
      }
    }

    return
      PipeTransferCommonContext({
        targetCoord: targetCoord,
        machineEnergyLevel: machineEnergyLevel,
        targetObjectTypeId: targetObjectTypeId
      });
  }
}
