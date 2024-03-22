// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";

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
import { transferInventoryItem } from "../utils/InventoryUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract DropSystem is System {
  function drop(bytes32[] memory inventoryEntityIds, VoxelCoord memory coord) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "DropSystem: player does not exist");
    require(!PlayerMetadata.getIsLoggedOff(playerEntityId), "DropSystem: player isn't logged in");
    require(
      inSurroundingCube(positionDataToVoxelCoord(Position.get(playerEntityId)), 1, coord),
      "DropSystem: player is too far from the drop coord"
    );

    bytes32 entityId = ReversePosition.get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      require(getTerrainObjectTypeId(AirObjectID, coord) == AirObjectID, "DropSystem: cannot drop on non-air block");

      // Create new entity
      entityId = getUniqueEntity();
      ObjectType.set(entityId, AirObjectID);
      Position.set(entityId, coord.x, coord.y, coord.z);
      ReversePosition.set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType.get(entityId) == AirObjectID, "DropSystem: cannot drop on non-air block");
    }

    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      transferInventoryItem(playerEntityId, entityId, AirObjectID, inventoryEntityIds[i]);
    }
  }
}
