// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";
import { LocalEnergyPool } from "../../codegen/tables/LocalEnergyPool.sol";

import { Position } from "../../utils/Vec3Storage.sol";

import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH, SMART_CHEST_ENERGY_COST } from "../../Constants.sol";
import { updateMachineEnergy, decreaseMachineEnergy, addEnergyToLocalPool } from "../../utils/EnergyUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";
import { PlayerUtils } from "../../utils/PlayerUtils.sol";
import { TransferCommonContext } from "../../Types.sol";

import { EntityId } from "../../EntityId.sol";
import { Vec3 } from "../../Vec3.sol";

library TransferLib {
  function transferCommon(
    address msgSender,
    EntityId chestEntityId,
    bool isDeposit
  ) public returns (TransferCommonContext memory) {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(msgSender);

    Vec3 chestCoord = Position._get(chestEntityId);
    require(playerCoord.inSurroundingCube(chestCoord, MAX_PLAYER_INFLUENCE_HALF_WIDTH), "Destination too far");
    ObjectTypeId chestObjectTypeId = ObjectType._get(chestEntityId);
    ObjectTypeId dstObjectTypeId = isDeposit ? chestObjectTypeId : ObjectTypes.Player;

    // TODO: what if it is not a smart chest?
    (EntityId forceFieldEntityId, ) = getForceField(chestCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
      machineEnergyLevel = machineData.energy;
      decreaseMachineEnergy(forceFieldEntityId, SMART_CHEST_ENERGY_COST);
      addEnergyToLocalPool(chestCoord, SMART_CHEST_ENERGY_COST);
    }

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
