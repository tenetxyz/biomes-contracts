// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Position, PositionData } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../../codegen/tables/BaseEntity.sol";
import { Health, HealthData } from "../../codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../../codegen/tables/Stamina.sol";
import { PlayerActivity } from "../../codegen/tables/PlayerActivity.sol";
import { ObjectTypeSchema, ObjectTypeSchemaData } from "../../codegen/tables/ObjectTypeSchema.sol";

import { GRAVITY_DAMAGE, GRAVITY_STAMINA_COST } from "../../Constants.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../../ObjectTypeIds.sol";
import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../../Utils.sol";
import { transferAllInventoryEntities } from "../../utils/InventoryUtils.sol";
import { regenHealth, despawnPlayer } from "../../utils/PlayerUtils.sol";

contract GravitySystem is System {
  function runGravity(bytes32 playerEntityId, VoxelCoord memory playerCoord) public returns (bool) {
    if (BaseEntity._get(playerEntityId) != bytes32(0)) {
      return false;
    }

    VoxelCoord memory belowCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    if (!inWorldBorder(belowCoord)) {
      return false;
    }

    bytes32 belowEntityId = ReversePosition._get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = getTerrainObjectTypeId(belowCoord);
      if (terrainObjectTypeId != AirObjectID) {
        return false;
      }

      // Create new entity
      belowEntityId = getUniqueEntity();
      ObjectType._set(belowEntityId, AirObjectID);
    } else {
      if (ObjectType._get(belowEntityId) != AirObjectID || getTerrainObjectTypeId(belowCoord) == WaterObjectID) {
        return false;
      }

      // Transfer any dropped items
      transferAllInventoryEntities(belowEntityId, playerEntityId, PlayerObjectID);
    }

    // Swap entity ids
    ReversePosition._set(playerCoord.x, playerCoord.y, playerCoord.z, belowEntityId);
    Position._set(belowEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    Position._set(playerEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
    ReversePosition._set(belowCoord.x, belowCoord.y, belowCoord.z, playerEntityId);

    ObjectTypeSchemaData memory schemaData = ObjectTypeSchema._get(PlayerObjectID);
    for (uint256 i = 0; i < schemaData.relativePositionsX.length; i++) {
      VoxelCoord memory relativeCoord = VoxelCoord(
        playerCoord.x + schemaData.relativePositionsX[i],
        playerCoord.y + schemaData.relativePositionsY[i],
        playerCoord.z + schemaData.relativePositionsZ[i]
      );
      bytes32 relativeEntityId = ReversePosition._get(relativeCoord.x, relativeCoord.y, relativeCoord.z);
      require(BaseEntity._get(relativeEntityId) == playerEntityId, "GravitySystem: relative entity id mismatch");
      VoxelCoord memory newRelativeCoord = VoxelCoord(relativeCoord.x, relativeCoord.y - 1, relativeCoord.z);
      // swap with belowEntityId
      ReversePosition._set(relativeCoord.x, relativeCoord.y, relativeCoord.z, belowEntityId);
      Position._set(belowEntityId, relativeCoord.x, relativeCoord.y, relativeCoord.z);

      ReversePosition._set(newRelativeCoord.x, newRelativeCoord.y, newRelativeCoord.z, relativeEntityId);
      Position._set(relativeEntityId, newRelativeCoord.x, newRelativeCoord.y, newRelativeCoord.z);
    }

    if (PlayerActivity._get(playerEntityId) != block.timestamp) {
      PlayerActivity._set(playerEntityId, block.timestamp);
    }

    // TODO: Update to be health
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    if (currentStamina > 0) {
      uint16 staminaRequired = GRAVITY_STAMINA_COST;
      uint32 newStamina = currentStamina > staminaRequired ? currentStamina - staminaRequired : 0;
      Stamina._setStamina(playerEntityId, newStamina);
    }

    // uint16 currentHealth = regenHealth(playerEntityId);
    // uint16 newHealth = currentHealth > GRAVITY_DAMAGE ? currentHealth - GRAVITY_DAMAGE : 0;
    // Health._setHealth(playerEntityId, newHealth);
    // if (newHealth == 0) {
    //   despawnPlayer(playerEntityId);
    // }

    // Check if entity above player is another player, if so we need to apply gravity to that player
    bytes32 aboveEntityId = ReversePosition._get(playerCoord.x, playerCoord.y + 2, playerCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      runGravity(aboveEntityId, VoxelCoord(playerCoord.x, playerCoord.y + 2, playerCoord.z));
    }

    // if (newHealth > 0) {
    // Recursively apply gravity until the player is on the ground or dead
    runGravity(playerEntityId, belowCoord);
    // }

    return true;
  }
}
