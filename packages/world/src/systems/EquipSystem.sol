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
  function equip(EntityId caller, EntityId inventoryEntityId) public {
    caller.activate();
    require(InventoryEntity._get(inventoryEntityId) == caller, "Player does not own inventory item");
    Equipped._set(caller, inventoryEntityId);

    notify(caller, EquipNotifData({ inventoryEntityId: inventoryEntityId }));
  }
}
