// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { Chip } from "../../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { PlayerObjectID } from "../../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../../Utils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../../Constants.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";
import { requireValidPlayer } from "../../utils/PlayerUtils.sol";
import { TransferCommonContext } from "../../Types.sol";

contract TransferHelperSystem is System {
  function transferCommon(
    address msgSender,
    bytes32 srcEntityId,
    bytes32 dstEntityId
  ) public payable returns (TransferCommonContext memory) {
    (bytes32 playerEntityId, ) = requireValidPlayer(msgSender);

    bytes32 baseSrcEntityId = BaseEntity._get(srcEntityId);
    baseSrcEntityId = baseSrcEntityId == bytes32(0) ? srcEntityId : baseSrcEntityId;

    bytes32 baseDstEntityId = BaseEntity._get(dstEntityId);
    baseDstEntityId = baseDstEntityId == bytes32(0) ? dstEntityId : baseDstEntityId;

    require(baseDstEntityId != baseSrcEntityId, "Cannot transfer to self");
    VoxelCoord memory srcCoord = positionDataToVoxelCoord(Position._get(baseSrcEntityId));
    VoxelCoord memory dstCoord = positionDataToVoxelCoord(Position._get(baseDstEntityId));
    require(inSurroundingCube(srcCoord, MAX_PLAYER_INFLUENCE_HALF_WIDTH, dstCoord), "Destination too far");

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

    bytes32 chestEntityId = isDeposit ? baseDstEntityId : baseSrcEntityId;
    VoxelCoord memory chestCoord = isDeposit ? dstCoord : srcCoord;

    address chipAddress = Chip._get(chestEntityId);
    bytes32 forceFieldEntityId = getForceField(chestCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId != bytes32(0)) {
      EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
      machineEnergyLevel = machineData.energyLevel;
    }

    return
      TransferCommonContext({
        playerEntityId: playerEntityId,
        chestEntityId: chestEntityId,
        chestCoord: chestCoord,
        dstObjectTypeId: dstObjectTypeId,
        chipAddress: chipAddress,
        machineEnergyLevel: machineEnergyLevel,
        isDeposit: isDeposit,
        chestObjectTypeId: isDeposit ? dstObjectTypeId : srcObjectTypeId
      });
  }
}
