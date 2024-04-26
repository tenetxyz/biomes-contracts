// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata, PlayerMetadataData } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, callGravity, gravityApplies, inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, removeFromInventoryCount, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { absInt16 } from "@biomesaw/utils/src/MathUtils.sol";
import { PLAYER_MASS } from "../Constants.sol";

contract TeleportSystem is System {
  function teleport(VoxelCoord memory newCoord) public {
    revert("Teleport disabled");
    return;

    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "TeleportSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "TeleportSystem: player isn't logged in");
    require(inWorldBorder(newCoord), "TeleportSystem: cannot teleport outside world border");
    require(
      PlayerMetadata._getLastMoveBlock(playerEntityId) < block.number,
      "MoveSystem: player already moved this block"
    );
    PlayerMetadata._setLastMoveBlock(playerEntityId, block.number);

    VoxelCoord memory oldCoord = positionDataToVoxelCoord(Position._get(playerEntityId));

    regenHealth(playerEntityId);
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
    uint32 numDeltaPositions = uint32(int32(absInt16(xDelta) + absInt16(yDelta) + absInt16(zDelta)));

    uint32 staminaRequired = (PLAYER_MASS * (numDeltaPositions ** 2)) / 100;
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

    gravityApplies(playerEntityId, newCoord);
  }
}
