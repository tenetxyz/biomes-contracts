// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";

import { AirObjectID, WaterObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { transferInventoryNonTool, transferInventoryTool } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer } from "../utils/PlayerUtils.sol";

contract DropSystem is System {
  function dropCommon(VoxelCoord memory coord) internal returns (bytes32, bytes32) {
    require(inWorldBorder(coord), "DropSystem: cannot drop outside world border");
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireBesidePlayer(playerCoord, coord);

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

    return (playerEntityId, entityId);
  }

  function drop(uint8 dropObjectTypeId, uint16 numToDrop, VoxelCoord memory coord) public {
    (bytes32 playerEntityId, bytes32 entityId) = dropCommon(coord);
    transferInventoryNonTool(playerEntityId, entityId, AirObjectID, dropObjectTypeId, numToDrop);
  }

  function dropTool(bytes32 toolEntityId, VoxelCoord memory coord) public {
    (bytes32 playerEntityId, bytes32 entityId) = dropCommon(coord);
    transferInventoryTool(playerEntityId, entityId, AirObjectID, toolEntityId);
  }
}
