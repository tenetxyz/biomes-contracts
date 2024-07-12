// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { InventoryTool } from "../codegen/tables/InventoryTool.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { requireValidPlayer } from "../utils/PlayerUtils.sol";

contract EquipSystem is System {
  function equip(bytes32 inventoryEntityId) public {
    (bytes32 playerEntityId, ) = requireValidPlayer(_msgSender());
    require(InventoryTool._get(inventoryEntityId) == playerEntityId, "EquipSystem: Player does not own inventory item");
    Equipped._set(playerEntityId, inventoryEntityId);
    PlayerActivity._set(playerEntityId, block.timestamp);
  }
}
