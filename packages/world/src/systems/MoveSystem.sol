// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";

import { PLAYER_MASS } from "../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer } from "../utils/PlayerUtils.sol";

contract MoveSystem is System {
  function move(VoxelCoord[] memory newCoords) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());

    VoxelCoord memory oldCoord = playerCoord;
    bytes32 finalEntityId;
    for (uint256 i = 0; i < newCoords.length; i++) {
      VoxelCoord memory newCoord = newCoords[i];
      finalEntityId = move(playerEntityId, oldCoord, newCoord);
      oldCoord = newCoord;
    }

    // Create new entity
    if (finalEntityId == bytes32(0)) {
      finalEntityId = getUniqueEntity();
      ObjectType._set(finalEntityId, AirObjectID);
    } else {
      transferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, finalEntityId);
    Position._set(finalEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    VoxelCoord memory finalCoord = newCoords[newCoords.length - 1];
    Position._set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition._set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    uint32 staminaRequired = (PLAYER_MASS * (uint32(newCoords.length) ** 2)) / 100;
    if (staminaRequired == 0) {
      staminaRequired = 1;
    }

    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    require(currentStamina >= staminaRequired, "MoveSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    VoxelCoord memory aboveCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      callGravity(aboveEntityId, aboveCoord);
    }
  }

  function move(
    bytes32 playerEntityId,
    VoxelCoord memory oldCoord,
    VoxelCoord memory newCoord
  ) internal returns (bytes32) {
    require(inWorldBorder(newCoord), "MoveSystem: cannot move outside world border");
    require(inSurroundingCube(oldCoord, 1, newCoord), "MoveSystem: new coord is not in surrounding cube of old coord");

    bytes32 newEntityId = ReversePosition._get(newCoord.x, newCoord.y, newCoord.z);
    if (newEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(newCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "MoveSystem: cannot move to non-air block"
      );
    } else {
      require(ObjectType._get(newEntityId) == AirObjectID, "MoveSystem: cannot move to non-air block");

      // Note: Turn this on if you want to transfer any drops along the path
      // to the player. This is disabled for now for gas efficiency.
      // transferAllInventoryEntities(newEntityId, playerEntityId, PlayerObjectID);
    }

    require(!gravityApplies(newCoord), "MoveSystem: cannot move player with gravity");

    return newEntityId;
  }
}
