// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, inWorldBorder } from "../Utils.sol";
import { getTerrainObjectTypeId } from "../utils/TerrainUtils.sol";
import { transferInventoryItem } from "../utils/InventoryUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract DropSystem is System {
  function drop(bytes32[] memory inventoryEntityIds, VoxelCoord memory coord) public {
    require(inWorldBorder(coord), "DropSystem: cannot drop outside world border");
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "DropSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "DropSystem: player isn't logged in");
    require(
      inSurroundingCube(positionDataToVoxelCoord(Position._get(playerEntityId)), 1, coord),
      "DropSystem: player is too far from the drop coord"
    );

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "DropSystem: cannot drop on non-air block"
      );

      // Create new entity
      entityId = getUniqueEntity();
      ObjectType._set(entityId, AirObjectID);
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "DropSystem: cannot drop on non-air block");
    }

    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      transferInventoryItem(playerEntityId, entityId, AirObjectID, inventoryEntityIds[i]);
    }
  }
}
