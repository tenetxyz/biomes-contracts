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
import { Inventory } from "../codegen/tables/Inventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { ItemMetadata } from "../codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../Utils.sol";
import { transferInventoryItem } from "../utils/InventoryUtils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";

contract TransferSystem is System {
  function transfer(bytes32 srcEntityId, bytes32 dstEntityId, bytes32[] memory inventoryEntityIds) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "TransferSystem: player does not exist");
    require(!PlayerMetadata.getIsLoggedOff(playerEntityId), "TransferSystem: player isn't logged in");

    require(dstEntityId != srcEntityId, "TransferSystem: cannot transfer to self");
    require(
      inSurroundingCube(
        positionDataToVoxelCoord(Position.get(srcEntityId)),
        1,
        positionDataToVoxelCoord(Position.get(dstEntityId))
      ),
      "TransferSystem: destination out of range"
    );

    bytes32 srcObjectTypeId = ObjectType.get(srcEntityId);
    bytes32 dstObjectTypeId = ObjectType.get(dstEntityId);
    if (srcObjectTypeId == PlayerObjectID) {
      require(playerEntityId == srcEntityId, "TransferSystem: player does not own inventory item");
      require(dstObjectTypeId == ChestObjectID, "TransferSystem: cannot transfer to non-chest");
    } else if (dstObjectTypeId == PlayerObjectID) {
      require(playerEntityId == dstEntityId, "TransferSystem: player does not own destination inventory");
      require(srcObjectTypeId == ChestObjectID, "TransferSystem: cannot transfer from non-chest");
    } else {
      revert("TransferSystem: invalid transfer operation");
    }

    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      transferInventoryItem(srcEntityId, dstEntityId, dstObjectTypeId, inventoryEntityIds[i]);
    }
  }
}
