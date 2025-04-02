// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ActionType } from "../codegen/common.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { EquipNotifData, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

contract EquipSystem is System {
  function equip(EntityId callerEntityId, EntityId inventoryEntityId) public {
    callerEntityId.activate();
    require(InventoryEntity._get(inventoryEntityId) == callerEntityId, "Player does not own inventory item");
    Equipped._set(callerEntityId, inventoryEntityId);

    notify(callerEntityId, EquipNotifData({ inventoryEntityId: inventoryEntityId }));
  }
}
