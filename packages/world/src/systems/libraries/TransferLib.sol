// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { VoxelCoord, VoxelCoordLib } from "../../VoxelCoord.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../../codegen/tables/LocalEnergyPool.sol";

import { ObjectTypeId, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_TRANSFER_ENERGY_COST, SMART_CHEST_ENERGY_COST } from "../../Constants.sol";
import { updateEnergyLevel } from "../../utils/EnergyUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";
import { TransferCommonContext } from "../../Types.sol";

import { EntityId } from "../../EntityId.sol";

library TransferLib {
  using VoxelCoordLib for *;

  function transferCommon(
    address msgSender,
    EntityId chestEntityId,
    bool isDeposit
  ) public returns (TransferCommonContext memory) {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, EnergyData memory playerEnergyData) = requireValidPlayer(
      msgSender
    );

    VoxelCoord memory chestCoord = Position._get(chestEntityId).toVoxelCoord();
    require(playerCoord.inSurroundingCube(MAX_PLAYER_INFLUENCE_HALF_WIDTH, chestCoord), "Destination too far");
    ObjectTypeId chestObjectTypeId = ObjectType._get(chestEntityId);
    ObjectTypeId dstObjectTypeId = isDeposit ? chestObjectTypeId : PlayerObjectID;

    uint128 energyCost = PLAYER_TRANSFER_ENERGY_COST;

    // TODO: what if it is not a smart chest?
    EntityId forceFieldEntityId = getForceField(chestCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      energyCost += SMART_CHEST_ENERGY_COST;
      EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
      require(machineData.energy >= SMART_CHEST_ENERGY_COST, "Not enough energy");
      forceFieldEntityId.setEnergy(machineData.energy - SMART_CHEST_ENERGY_COST);
    }

    require(playerEnergyData.energy > PLAYER_TRANSFER_ENERGY_COST, "Not enough energy");
    playerEntityId.setEnergy(playerEnergyData.energy - PLAYER_TRANSFER_ENERGY_COST);
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
