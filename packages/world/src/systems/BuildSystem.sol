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
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, inSpawnArea, inWorldBorder } from "../Utils.sol";
import { removeFromInventoryCount, removeEntityIdFromReverseInventory } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { getObjectTypeIsBlock, getTerrainObjectTypeId } from "../utils/TerrainUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract BuildSystem is System {
  function build(bytes32 inventoryEntityId, VoxelCoord memory coord) public {
    require(inWorldBorder(coord), "BuildSystem: cannot build outside world border");
    require(!inSpawnArea(coord), "BuildSystem: cannot build at spawn area");
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "BuildSystem: player does not exist");
    require(
      Inventory._get(inventoryEntityId) == playerEntityId,
      "BuildSystem: inventory entity does not belong to the player"
    );
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "BuildSystem: player isn't logged in");

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    uint8 objectTypeId = ObjectType._get(inventoryEntityId);
    require(getObjectTypeIsBlock(objectTypeId), "BuildSystem: object type is not a block");
    require(
      inSurroundingCube(playerCoord, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, coord),
      "BuildSystem: player is too far from the block"
    );

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(terrainObjectTypeId == AirObjectID, "BuildSystem: cannot build on terrain non-air block");
      require(terrainObjectTypeId != WaterObjectID, "BuildSystem: cannot build on water block");
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");
      require(getTerrainObjectTypeId(coord) != WaterObjectID, "BuildSystem: cannot build on water block");

      bytes32[] memory droppedEntityIds = ReverseInventory._get(entityId);
      require(droppedEntityIds.length == 0, "BuildSystem: Cannot build where there are dropped objects");

      ObjectType._deleteRecord(entityId);
      Position._deleteRecord(entityId);
    }

    Inventory._deleteRecord(inventoryEntityId);
    removeEntityIdFromReverseInventory(playerEntityId, inventoryEntityId);
    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    Position._set(inventoryEntityId, coord.x, coord.y, coord.z);
    ReversePosition._set(coord.x, coord.y, coord.z, inventoryEntityId);
  }
}