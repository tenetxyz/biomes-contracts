// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata, PlayerMetadataData } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";
import { InventoryCount } from "../codegen/tables/InventoryCount.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, callGravity, inWorldBorder } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { getObjectTypeMass, getTerrainObjectTypeId } from "../utils/TerrainUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { absInt16 } from "@biomesaw/utils/src/MathUtils.sol";

contract TeleportSystem is System {
  function teleport(VoxelCoord memory newCoord) public {
    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "TeleportSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "TeleportSystem: player isn't logged in");
    require(inWorldBorder(newCoord), "TeleportSystem: cannot teleport outside world border");

    VoxelCoord memory oldCoord = positionDataToVoxelCoord(Position._get(playerEntityId));

    regenHealth(playerEntityId, oldCoord);
    regenStamina(playerEntityId, oldCoord);

    bytes32 newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    if (newEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(newCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "TeleportSystem: cannot teleport to non-air block"
      );

      // Create new entity
      newEntityId = getUniqueEntity();
      ObjectType._set(newEntityId, AirObjectID);
    } else {
      require(ObjectType._get(newEntityId) == AirObjectID, "TeleportSystem: cannot teleport to non-air block");

      // Transfer any dropped items
      transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(oldCoord.x, oldCoord.y, oldCoord.z, newEntityId);
    Position._set(newEntityId, oldCoord.x, oldCoord.y, oldCoord.z);

    Position._set(playerEntityId, newCoord.x, newCoord.y, newCoord.z);
    ReversePosition._set(newCoord.x, newCoord.y, newCoord.z, playerEntityId);

    int16 xDelta = newCoord.x - oldCoord.x;
    int16 yDelta = newCoord.y - oldCoord.y;
    int16 zDelta = newCoord.z - oldCoord.z;
    uint16 numDeltaPositions = uint16(absInt16(xDelta) + absInt16(yDelta) + absInt16(zDelta));

    uint16 numMovesInBlock = PlayerMetadata._getNumMovesInBlock(playerEntityId);
    if (PlayerMetadata._getLastMoveBlock(playerEntityId) != block.number) {
      numMovesInBlock = numDeltaPositions;
      PlayerMetadata._setLastMoveBlock(playerEntityId, block.number);
    } else {
      numMovesInBlock += numDeltaPositions;
    }
    PlayerMetadata._setNumMovesInBlock(playerEntityId, numMovesInBlock);

    // Inventory mass
    uint32 inventoryTotalMass = 0;
    {
      bytes32[] memory inventoryEntityIds = ReverseInventory._get(playerEntityId);
      for (uint256 i = 0; i < inventoryEntityIds.length; i++) {
        uint8 inventoryObjectTypeId = ObjectType._get(inventoryEntityIds[i]);
        inventoryTotalMass += getObjectTypeMass(inventoryObjectTypeId);
      }
    }

    uint32 staminaRequired = getObjectTypeMass(PlayerObjectID);
    staminaRequired += inventoryTotalMass / 50;
    staminaRequired = staminaRequired * (numMovesInBlock ** 2);
    staminaRequired = staminaRequired / 100;
    if (staminaRequired == 0) {
      staminaRequired = 1;
    }

    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    require(currentStamina >= staminaRequired, "TeleportSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    {
      VoxelCoord memory aboveCoord = VoxelCoord(oldCoord.x, oldCoord.y + 1, oldCoord.z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    }

    VoxelCoord memory belowCoord = VoxelCoord(newCoord.x, newCoord.y - 1, newCoord.z);
    bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType._get(belowEntityId) == AirObjectID) {
      callGravity(playerEntityId, newCoord);
    }
  }
}
