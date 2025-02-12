// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { InventoryEntity } from "../codegen/tables/InventoryEntity.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ActionType } from "../codegen/common.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { notify, EquipNotifData } from "../utils/NotifUtils.sol";
import { EntityId } from "../EntityId.sol";

contract EquipSystem is System {
  function equip(EntityId inventoryEntityId) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    require(InventoryEntity._get(inventoryEntityId) == playerEntityId, "Player does not own inventory item");
    Equipped._set(playerEntityId, inventoryEntityId);

    notify(playerEntityId, EquipNotifData({ inventoryEntityId: inventoryEntityId }));
  }
}
