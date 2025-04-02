// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ActionType } from "../codegen/common.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { UnequipNotifData, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { Vec3 } from "../Vec3.sol";

contract UnequipSystem is System {
  function unequip(EntityId callerEntityId) public {
    callerEntityId.activate();
    EntityId equippedEntityId = Equipped._get(callerEntityId);
    if (!equippedEntityId.exists()) {
      return;
    }
    Equipped._deleteRecord(callerEntityId);

    notify(callerEntityId, UnequipNotifData({ inventoryEntityId: equippedEntityId }));
  }
}
