// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { ItemShopNotif, ItemShopNotifData } from "../../codegen/tables/ItemShopNotif.sol";
import { requireChipOwner, requireChipOwnerOrNoOwner } from "../../Utils.sol";

contract ItemShopNotifSystem is System {
  function emitShopNotif(bytes32 chestEntityId, ItemShopNotifData memory notifData) public {
    requireChipOwner(chestEntityId);
    ItemShopNotif.set(chestEntityId, notifData);
  }

  function deleteShopNotif(bytes32 chestEntityId) public {
    requireChipOwnerOrNoOwner(chestEntityId);
    ItemShopNotif.deleteRecord(chestEntityId);
  }
}
