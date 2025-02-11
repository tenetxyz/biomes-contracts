// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { InventoryTool } from "../codegen/tables/InventoryTool.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";
import { EntityId } from "../EntityId.sol";

contract EquipSystem is System {
  function equip(EntityId inventoryEntityId) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    require(InventoryTool._get(inventoryEntityId) == playerEntityId, "Player does not own inventory item");
    Equipped._set(playerEntityId, inventoryEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Equip,
        entityId: inventoryEntityId,
        objectTypeId: ObjectType._get(inventoryEntityId),
        coordX: playerCoord.x,
        coordY: playerCoord.y,
        coordZ: playerCoord.z,
        amount: 1
      })
    );
  }
}
