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
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../Utils.sol";
import { removeFromInventoryCount, removeEntityIdFromReverseInventory } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "../Constants.sol";

contract BuildSystem is System {
  function build(bytes32 inventoryEntityId, VoxelCoord memory coord) public {
    require(
      (coord.x < SPAWN_LOW_X || coord.x > SPAWN_HIGH_X) || (coord.z < SPAWN_LOW_Z || coord.z > SPAWN_HIGH_Z),
      "BuildSystem: cannot build at spawn area"
    );
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "BuildSystem: player does not exist");
    require(
      Inventory.get(inventoryEntityId) == playerEntityId,
      "BuildSystem: inventory entity does not belong to the player"
    );
    require(!PlayerMetadata.getIsLoggedOff(playerEntityId), "BuildSystem: player isn't logged in");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId);

    bytes32 objectTypeId = ObjectType.get(inventoryEntityId);
    require(ObjectTypeMetadata.getIsBlock(objectTypeId), "BuildSystem: object type is not a block");
    require(
      inSurroundingCube(
        positionDataToVoxelCoord(Position.get(playerEntityId)),
        MAX_PLAYER_BUILD_MINE_HALF_WIDTH,
        coord
      ),
      "BuildSystem: player is too far from the block"
    );

    bytes32 entityId = ReversePosition.get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      require(
        getTerrainObjectTypeId(AirObjectID, coord) == AirObjectID,
        "BuildSystem: cannot build on terrain non-air block"
      );
    } else {
      require(ObjectType.get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");

      bytes32[] memory droppedEntityIds = ReverseInventory.get(entityId);
      require(droppedEntityIds.length == 0, "BuildSystem: Cannot build where there are dropped objects");

      ObjectType.deleteRecord(entityId);
      Position.deleteRecord(entityId);
    }

    Inventory.deleteRecord(inventoryEntityId);
    removeEntityIdFromReverseInventory(playerEntityId, inventoryEntityId);
    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    Position.set(inventoryEntityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, inventoryEntityId);
  }
}
