// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata, PlayerMetadataData } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId, callGravity, inWorldBorder } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "MoveSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "MoveSystem: player isn't logged in");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId);

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    VoxelCoord memory oldCoord = playerCoord;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      bool gravityRan = move(playerEntityId, oldCoord, newCoord);
      if (gravityRan) {
        // then, the player is now at a new coord we don't know about, so we just break
        break;
      }
      oldCoord = newCoord;
    }
  }

  function move(
    bytes32 playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal returns (bool) {
    require(inWorldBorder(newCoord), "MoveSystem: cannot move outside world border");
    require(inSurroundingCube(oldCoord, 1, newCoord), "MoveSystem: new coord is not in surrounding cube of old coord");

    bytes32 newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    if (newEntityId == bytes32(0)) {
      // Check terrain block type
      require(getTerrainObjectTypeId(_world(), newCoord) == AirObjectID, "MoveSystem: cannot move to non-air block");

      // Create new entity
      newEntityId = getUniqueEntity();
      ObjectType._set(newEntityId, AirObjectID);
    } else {
      require(ObjectType._get(newEntityId) == AirObjectID, "MoveSystem: cannot move to non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(oldCoord.x, oldCoord.y, oldCoord.z, newEntityId);
    Position._set(newEntityId, oldCoord.x, oldCoord.y, oldCoord.z);

    Position._set(playerEntityId, newCoord.x, newCoord.y, newCoord.z);
    ReversePosition._set(newCoord.x, newCoord.y, newCoord.z, playerEntityId);

    uint32 numMovesInBlock = PlayerMetadata._getNumMovesInBlock(playerEntityId);
    if (PlayerMetadata._getLastMoveBlock(playerEntityId) != block.number) {
      numMovesInBlock = 1;
      PlayerMetadata._setLastMoveBlock(playerEntityId, block.number);
    } else {
      numMovesInBlock += 1;
    }
    PlayerMetadata._setNumMovesInBlock(playerEntityId, numMovesInBlock);

    // Inventory mass
    uint32 inventoryTotalMass = 0;
    bytes32[] memory inventoryEntityIds = ReverseInventory._get(playerEntityId);
    for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
      bytes32 inventoryObjectTypeId = ObjectType._get(inventoryEntityIds[i]);
      inventoryTotalMass += ObjectTypeMetadata._getMass(inventoryObjectTypeId);
    }

    uint32 staminaRequired = ObjectTypeMetadata._getMass(PlayerObjectID);
    staminaRequired += inventoryTotalMass / 50;
    staminaRequired = staminaRequired * (numMovesInBlock ** 2);

    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    require(currentStamina >= staminaRequired, "MoveSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    VoxelCoord memory aboveCoord = VoxelCoord(oldCoord.x, oldCoord.y + 1, oldCoord.z);
    bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      callGravity(aboveEntityId, aboveCoord);
    }

    VoxelCoord memory belowCoord = VoxelCoord(newCoord.x, newCoord.y - 1, newCoord.z);
    bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType._get(belowEntityId) == AirObjectID) {
      return callGravity(playerEntityId, newCoord);
    }
    return false;
  }
}
