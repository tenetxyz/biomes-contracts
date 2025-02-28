// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ActionType } from "../codegen/common.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { notify, UnequipNotifData } from "../utils/NotifUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";

contract UnequipSystem is System {
  function unequip() public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    EntityId equippedEntityId = Equipped._get(playerEntityId);
    if (!equippedEntityId.exists()) {
      return;
    }
    ObjectTypeId equippedObjectId = ObjectType._get(equippedEntityId);
    Equipped._deleteRecord(playerEntityId);

    notify(playerEntityId, UnequipNotifData({ inventoryEntityId: equippedEntityId }));
  }
}
