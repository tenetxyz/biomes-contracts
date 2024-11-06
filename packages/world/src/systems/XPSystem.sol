// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID, ChipBatteryObjectID, PowerStoneObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { NUM_XP_FOR_FULL_BATTERY } from "../Constants.sol";

contract XPSystem is System {
  function craftChipBattery(uint16 numBatteries, bytes32 stationEntityId) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    bytes32 baseEntityId = BaseEntity._get(stationEntityId);
    bytes32 useStationEntityId = baseEntityId == bytes32(0) ? stationEntityId : baseEntityId;
    require(ObjectType._get(useStationEntityId) == PowerStoneObjectID, "XPSystem: not a power station");
    requireInPlayerInfluence(playerCoord, stationEntityId);

    uint256 xpRequired = numBatteries * NUM_XP_FOR_FULL_BATTERY;
    uint256 playerXP = ExperiencePoints._get(playerEntityId);
    require(playerXP >= xpRequired, "XPSystem: not enough XP");
    ExperiencePoints._set(playerEntityId, playerXP - xpRequired);

    addToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, numBatteries);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Craft,
        entityId: useStationEntityId,
        objectTypeId: ChipBatteryObjectID,
        coordX: playerCoord.x,
        coordY: playerCoord.y,
        coordZ: playerCoord.z,
        amount: numBatteries
      })
    );
  }
}
