// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { getKeysWithValue } from "@latticexyz/world-modules/src/modules/keyswithvalue/getKeysWithValue.sol";
import { PackedCounter } from "@latticexyz/store/src/PackedCounter.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata, PlayerMetadataData } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId, applyGravity } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "MoveSystem: player does not exist");
    require(!PlayerMetadata.getIsLoggedOff(playerEntityId), "MoveSystem: player isn't logged in");

    regenHealth(playerEntityId);
    regenStamina(playerEntityId);

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position.get(playerEntityId));
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
    require(inSurroundingCube(oldCoord, 1, newCoord), "MoveSystem: new coord is not in surrounding cube of old coord");

    bytes32 newEntityId = ReversePosition.get(newCoord.x, newCoord.y, newCoord.z);
    if (newEntityId == bytes32(0)) {
      // Check terrain block type
      require(getTerrainObjectTypeId(AirObjectID, newCoord) == AirObjectID, "MoveSystem: cannot move to non-air block");

      // Create new entity
      newEntityId = getUniqueEntity();
      ObjectType.set(newEntityId, AirObjectID);
    } else {
      require(ObjectType.get(newEntityId) == AirObjectID, "MoveSystem: cannot move to non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition.set(oldCoord.x, oldCoord.y, oldCoord.z, newEntityId);
    Position.set(newEntityId, oldCoord.x, oldCoord.y, oldCoord.z);

    Position.set(playerEntityId, newCoord.x, newCoord.y, newCoord.z);
    ReversePosition.set(newCoord.x, newCoord.y, newCoord.z, playerEntityId);

    uint16 numMovesInBlock = PlayerMetadata.getNumMovesInBlock(playerEntityId);
    if (PlayerMetadata.getLastMoveBlock(playerEntityId) != block.number) {
      numMovesInBlock = 1;
      PlayerMetadata.setLastMoveBlock(playerEntityId, block.number);
    } else {
      numMovesInBlock += 1;
    }
    PlayerMetadata.setNumMovesInBlock(playerEntityId, numMovesInBlock);

    // Inventory mass
    uint32 inventoryTotalMass = 0;
    {
      (bytes memory staticData, PackedCounter encodedLengths, bytes memory dynamicData) = Inventory.encode(
        playerEntityId
      );
      bytes32[] memory inventoryEntityIds = getKeysWithValue(
        Inventory._tableId,
        staticData,
        encodedLengths,
        dynamicData
      );
      for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
        bytes32 inventoryObjectTypeId = ObjectType.get(inventoryEntityIds[i]);
        inventoryTotalMass += ObjectTypeMetadata.getMass(inventoryObjectTypeId);
      }
    }

    uint32 staminaRequired = ObjectTypeMetadata.getMass(PlayerObjectID);
    staminaRequired += inventoryTotalMass / 50;
    staminaRequired = staminaRequired * (numMovesInBlock ** 2);

    uint32 currentStamina = Stamina.getStamina(playerEntityId);
    require(currentStamina >= staminaRequired, "MoveSystem: not enough stamina");
    Stamina.setStamina(playerEntityId, currentStamina - staminaRequired);

    VoxelCoord memory belowCoord = VoxelCoord(newCoord.x, newCoord.y - 1, newCoord.z);
    bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType.get(belowEntityId) == AirObjectID) {
      return applyGravity(address(this), playerEntityId, newCoord);
    }
    return false;
  }
}
