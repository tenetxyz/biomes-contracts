// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { Chip, ChipData } from "../../codegen/tables/Chip.sol";

import { PlayerObjectID, ForceFieldObjectID, ChipBatteryObjectID } from "../../ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../../Utils.sol";
import { MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../../Constants.sol";
import { updateChipBatteryLevel } from "../../utils/ChipUtils.sol";
import { getForceField } from "../../utils/ForceFieldUtils.sol";
import { isStorageContainer } from "../../utils/ObjectTypeUtils.sol";
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
}
