// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ExperiencePoints } from "../codegen/tables/ExperiencePoints.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { transferInventoryNonTool, transferInventoryTool } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { mintXP } from "../utils/XPUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract DropSystem is System {
  function dropCommon(bytes32 playerEntityId, VoxelCoord memory coord) internal returns (bytes32) {
    require(inWorldBorder(coord), "DropSystem: cannot drop outside world border");
    require(playerEntityId != bytes32(0), "DropSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "DropSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    require(inSurroundingCube(playerCoord, 1, coord), "DropSystem: player is too far from the drop coord");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

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

    PlayerActivity._set(playerEntityId, block.timestamp);
    mintXP(playerEntityId, 1);

    return entityId;
  }

  function drop(uint8 dropObjectTypeId, uint16 numToDrop, VoxelCoord memory coord) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    bytes32 entityId = dropCommon(playerEntityId, coord);
    transferInventoryNonTool(playerEntityId, entityId, AirObjectID, dropObjectTypeId, numToDrop);
  }

  function dropTool(bytes32 toolEntityId, VoxelCoord memory coord) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    bytes32 entityId = dropCommon(playerEntityId, coord);
    transferInventoryTool(playerEntityId, entityId, AirObjectID, toolEntityId);
  }
}
