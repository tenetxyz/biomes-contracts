// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordLib } from "../../VoxelCoord.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { Chip } from "../../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { PlayerObjectID } from "../../ObjectTypeIds.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../../Constants.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";
import { TransferCommonContext } from "../../Types.sol";

import { EntityId } from "../../EntityId.sol";

library TransferLib {
  using VoxelCoordLib for *;

  function transferCommon(
    address msgSender,
    EntityId srcEntityId,
    EntityId dstEntityId
  ) public returns (TransferCommonContext memory) {
    (EntityId playerEntityId, ) = requireValidPlayer(msgSender);

    EntityId baseSrcEntityId = srcEntityId.baseEntityId();

    EntityId baseDstEntityId = dstEntityId.baseEntityId();

    require(baseDstEntityId != baseSrcEntityId, "Cannot transfer to self");
    VoxelCoord memory srcCoord = Position._get(baseSrcEntityId).toVoxelCoord();
    VoxelCoord memory dstCoord = Position._get(baseDstEntityId).toVoxelCoord();
    require(srcCoord.inSurroundingCube(MAX_PLAYER_INFLUENCE_HALF_WIDTH, dstCoord), "Destination too far");

    uint16 srcObjectTypeId = ObjectType._get(baseSrcEntityId);
    uint16 dstObjectTypeId = ObjectType._get(baseDstEntityId);
    bool isDeposit = false;
    if (srcObjectTypeId == PlayerObjectID) {
      require(playerEntityId == baseSrcEntityId, "Caller does not own source inventory");
      isDeposit = true;
    } else if (dstObjectTypeId == PlayerObjectID) {
      require(playerEntityId == baseDstEntityId, "Caller does not own destination inventory");
      isDeposit = false;
    } else {
      revert("Invalid transfer operation");
    }

    EntityId chestEntityId = isDeposit ? baseDstEntityId : baseSrcEntityId;
    VoxelCoord memory chestCoord = isDeposit ? dstCoord : srcCoord;

    EntityId forceFieldEntityId = getForceField(chestCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
    }

    return
      TransferCommonContext({
        playerEntityId: playerEntityId,
        chestEntityId: chestEntityId,
        chestCoord: chestCoord,
        dstObjectTypeId: dstObjectTypeId,
        machineEnergyLevel: machineEnergyLevel,
        isDeposit: isDeposit,
        chestObjectTypeId: isDeposit ? dstObjectTypeId : srcObjectTypeId
      });
  }
}
