// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { notify, UnequipNotifData } from "../utils/NotifUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { Vec3 } from "../Vec3.sol";

contract UnequipSystem is System {
  function unequip() public {
    (EntityId playerEntityId, , ) = PlayerUtils.requireValidPlayer(_msgSender());
    EntityId equippedEntityId = Equipped._get(playerEntityId);
    if (!equippedEntityId.exists()) {
      return;
    }
    Equipped._deleteRecord(playerEntityId);

    notify(playerEntityId, UnequipNotifData({ inventoryEntityId: equippedEntityId }));
  }
}
