// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../codegen/tables/InventoryObjects.sol";
import { ReverseInventoryTool } from "../codegen/tables/ReverseInventoryTool.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, inSpawnArea, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract BuildSystem is System {
  function build(uint8 objectTypeId, VoxelCoord memory coord) public returns (bytes32) {
    require(inWorldBorder(coord), "BuildSystem: cannot build outside world border");
    require(!inSpawnArea(coord), "BuildSystem: cannot build at spawn area");

    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "BuildSystem: player does not exist");
    require(ObjectTypeMetadata._getIsBlock(objectTypeId), "BuildSystem: object type is not a block");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "BuildSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    require(
      inSurroundingCube(playerCoord, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, coord),
      "BuildSystem: player is too far from the block"
    );

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(coord);
      require(terrainObjectTypeId != WaterObjectID, "BuildSystem: cannot build on water block");
      require(terrainObjectTypeId == AirObjectID, "BuildSystem: cannot build on terrain non-air block");

      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType._get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");
      require(getTerrainObjectTypeId(coord) != WaterObjectID, "BuildSystem: cannot build on water block");
      require(
        InventoryObjects._lengthObjectTypeIds(entityId) == 0,
        "BuildSystem: Cannot build where there are dropped objects"
      );
    }

    ObjectType._set(entityId, objectTypeId);
    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    PlayerActivity._set(playerEntityId, block.timestamp);

    return entityId;
  }
}
