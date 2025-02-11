// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";

contract UnequipSystem is System {
  function unequip() public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    EntityId equippedEntityId = Equipped._get(playerEntityId);
    if (!equippedEntityId.exists()) {
      return;
    }
    uint16 equippedObjectId = ObjectType._get(equippedEntityId);
    Equipped._deleteRecord(playerEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Unequip,
        entityId: equippedEntityId,
        objectTypeId: equippedObjectId,
        coordX: playerCoord.x,
        coordY: playerCoord.y,
        coordZ: playerCoord.z,
        amount: 1
      })
    );
  }
}
