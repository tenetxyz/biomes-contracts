// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract EquipSystem is System {
  function equip(bytes32 inventoryEntityId) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "EquipSystem: player does not exist");
    require(!PlayerMetadata.getIsLoggedOff(playerEntityId), "EquipSystem: player isn't logged in");

    require(Inventory.get(inventoryEntityId) == playerEntityId, "EquipSystem: Entity does not own inventory item");

    Equipped.set(playerEntityId, inventoryEntityId);
  }
}
