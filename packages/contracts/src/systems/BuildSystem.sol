// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory, InventoryTableId } from "../codegen/tables/Inventory.sol";

import { VoxelCoord } from "../Types.sol";
import { AirObjectID, PlayerObjectID, MAX_PLAYER_BUILD_MINE_HALF_WIDTH } from "../Constants.sol";
import { positionDataToVoxelCoord, inSurroundingCube, removeFromInventoryCount, regenHealth, regenStamina } from "../Utils.sol";

contract BuildSystem is System {
  function build(bytes32 inventoryEntityId, VoxelCoord memory coord) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "BuildSystem: player does not exist");
    require(
      Inventory.get(inventoryEntityId) == playerEntityId,
      "BuildSystem: inventory entity does not belong to the player"
    );

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
      (bool success, bytes memory occurrence) = _world().staticcall(
        bytes.concat(ObjectTypeMetadata.getOccurence(AirObjectID), abi.encode(coord))
      );
      require(
        success && occurrence.length > 0 && abi.decode(occurrence, (bytes32)) == AirObjectID,
        "BuildSystem: cannot build on non-air block"
      );
    } else {
      require(ObjectType.get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");

      (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData) = Inventory.encode(entityId);
      bytes32[] memory inventoryEntityIds = getKeysWithValue(InventoryTableId, staticData, encodedLengths, dynamicData);
      require(inventoryEntityIds.length == 0, "BuildSystem: Cannot build where there are dropped objects");
    }

    Inventory.deleteRecord(entityId);
    removeFromInventoryCount(playerEntityId, objectTypeId, 1);

    Position.set(inventoryEntityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, inventoryEntityId);

    // TODO apply gravity
  }
}
