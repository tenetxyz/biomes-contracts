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
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { getTerrainObjectTypeId, positionDataToVoxelCoord, addToInventoryCount, removeFromInventoryCount } from "../Utils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";

contract InventorySystem is System {
  function equip(bytes32 inventoryEntityId) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "InventorySystem: player does not exist");

    require(Inventory.get(inventoryEntityId) == playerEntityId, "InventorySystem: entity does not own inventory item");

    Equipped.set(playerEntityId, inventoryEntityId);
  }

  function unequip() public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "InventorySystem: player does not exist");

    Equipped.deleteRecord(playerEntityId);
  }

  function drop(bytes32[] memory inventoryEntityIds, VoxelCoord memory coord) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "InventorySystem: player does not exist");
    require(
      inSurroundingCube(positionDataToVoxelCoord(Position.get(playerEntityId)), 1, coord),
      "Inventory: player is too far from the drop coord"
    );

    bytes32 entityId = ReversePosition.get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      // Check terrain block type
      require(getTerrainObjectTypeId(coord) == AirObjectID, "BuildSystem: cannot build on non-air block");

      // Create new entity
      entityId = getUniqueEntity();
      ObjectType.set(entityId, AirObjectID);
      Position.set(entityId, coord.x, coord.y, coord.z);
      ReversePosition.set(coord.x, coord.y, coord.z, entityId);
    } else {
      require(ObjectType.get(entityId) == AirObjectID, "BuildSystem: cannot build on non-air block");
    }

    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      transferInventoryItem(playerEntityId, entityId, AirObjectID, inventoryEntityIds[i]);
    }
  }

  function transfer(bytes32 srcEntityId, bytes32 dstEntityId, bytes32[] memory inventoryEntityIds) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "InventorySystem: player does not exist");

    require(dstEntityId != srcEntityId, "InventorySystem: cannot transfer to self");
    require(
      inSurroundingCube(
        positionDataToVoxelCoord(Position.get(srcEntityId)),
        1,
        positionDataToVoxelCoord(Position.get(dstEntityId))
      ),
      "InventorySystem: destination out of range"
    );

    bytes32 srcObjectTypeId = ObjectType.get(srcEntityId);
    bytes32 dstObjectTypeId = ObjectType.get(dstEntityId);
    require(holdsInventory(srcObjectTypeId), "InventorySystem: invalid source");
    require(holdsInventory(dstObjectTypeId), "InventorySystem: invalid destination");
    if (srcObjectTypeId == PlayerObjectID) {
      require(playerEntityId == srcEntityId, "InventorySystem: player does not own inventory item");
    } else if (dstObjectTypeId == PlayerObjectID) {
      require(playerEntityId == dstEntityId, "InventorySystem: player does not own destination inventory");
    }

    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      transferInventoryItem(srcEntityId, dstEntityId, dstObjectTypeId, inventoryEntityIds[i]);
    }
  }

  function holdsInventory(bytes32 objectTypeId) internal pure returns (bool) {
    return objectTypeId == PlayerObjectID || objectTypeId == ChestObjectID;
  }

  function transferInventoryItem(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    bytes32 dstObjectTypeId,
    bytes32 inventoryEntityId
  ) internal {
    require(Inventory.get(inventoryEntityId) == srcEntityId, "InventorySystem: entity does not own inventory item");
    require(Equipped.get(srcEntityId) != inventoryEntityId, "InventorySystem: cannot transfer equipped item");
    Inventory.set(inventoryEntityId, dstEntityId);

    bytes32 inventoryObjectTypeId = ObjectType.get(inventoryEntityId);
    removeFromInventoryCount(srcEntityId, inventoryObjectTypeId, 1);
    addToInventoryCount(dstEntityId, dstObjectTypeId, inventoryObjectTypeId, 1);
  }
}
