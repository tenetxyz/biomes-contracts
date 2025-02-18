// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordLib } from "../../VoxelCoord.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../../codegen/tables/LocalEnergyPool.sol";

import { ObjectTypeId, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_TRANSFER_ENERGY_COST, SMART_CHEST_ENERGY_COST } from "../../Constants.sol";
import { updateMachineEnergyLevel } from "../../utils/EnergyUtils.sol";
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
    (EntityId playerEntityId, , EnergyData memory playerEnergyData) = requireValidPlayer(msgSender);

    EntityId chestEntityId;
    VoxelCoord memory chestCoord;
    ObjectTypeId chestObjectTypeId;
    ObjectTypeId dstObjectTypeId;
    bool isDeposit;
    {
      EntityId baseSrcEntityId = srcEntityId.baseEntityId();
      EntityId baseDstEntityId = dstEntityId.baseEntityId();
      require(baseDstEntityId != baseSrcEntityId, "Cannot transfer to self");
      VoxelCoord memory srcCoord = Position._get(baseSrcEntityId).toVoxelCoord();
      VoxelCoord memory dstCoord = Position._get(baseDstEntityId).toVoxelCoord();
      require(srcCoord.inSurroundingCube(MAX_PLAYER_INFLUENCE_HALF_WIDTH, dstCoord), "Destination too far");
      ObjectTypeId srcObjectTypeId = ObjectType._get(baseSrcEntityId);
      dstObjectTypeId = ObjectType._get(baseDstEntityId);

      chestEntityId = isDeposit ? baseDstEntityId : baseSrcEntityId;
      chestCoord = isDeposit ? dstCoord : srcCoord;
      chestObjectTypeId = isDeposit ? dstObjectTypeId : srcObjectTypeId;

      isDeposit = false;
      if (srcObjectTypeId == PlayerObjectID) {
        require(playerEntityId == baseSrcEntityId, "Caller does not own source inventory");
        isDeposit = true;
      } else if (dstObjectTypeId == PlayerObjectID) {
        require(playerEntityId == baseDstEntityId, "Caller does not own destination inventory");
        isDeposit = false;
      } else {
        revert("Invalid transfer operation");
      }
    }

    uint128 energyCost = PLAYER_TRANSFER_ENERGY_COST;

    EntityId forceFieldEntityId = getForceField(chestCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      energyCost += SMART_CHEST_ENERGY_COST;
      EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
      forceFieldEntityId.decreaseEnergy(machineData, SMART_CHEST_ENERGY_COST);
    }

    playerEntityId.decreaseEnergy(playerEnergyData, PLAYER_TRANSFER_ENERGY_COST);
    chestCoord.addEnergyToLocalPool(energyCost);

    return
      TransferCommonContext({
        playerEntityId: playerEntityId,
        chestEntityId: chestEntityId,
        chestCoord: chestCoord,
        dstObjectTypeId: dstObjectTypeId,
        machineEnergyLevel: machineEnergyLevel,
        isDeposit: isDeposit,
        chestObjectTypeId: chestObjectTypeId
      });
  }
}
