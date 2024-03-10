// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, PLAYER_HAND_DAMAGE, HIT_STAMINA_COST } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../Utils.sol";
import { useEquipped } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina, despawnPlayer } from "../utils/PlayerUtils.sol";
import { applyGravity } from "../utils/GravityUtils.sol";
import { inSurroundingCube } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "../Constants.sol";

contract PlayerSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (bytes32) {
    address newPlayer = _msgSender();
    require(Player.get(newPlayer) == bytes32(0), "PlayerSystem: player already exists");

    // Check spawn coord is within spawn area
    require(
      spawnCoord.x >= SPAWN_LOW_X &&
        spawnCoord.x <= SPAWN_HIGH_X &&
        spawnCoord.z >= SPAWN_LOW_Z &&
        spawnCoord.z <= SPAWN_HIGH_Z,
      "PlayerSystem: coord outside of spawn area"
    );

    bytes32 entityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    if (entityId == bytes32(0)) {
      require(
        getTerrainObjectTypeId(AirObjectID, spawnCoord) == AirObjectID,
        "PlayerSystem: cannot spawn on terrain non-air block"
      );

      // Create new entity
      entityId = getUniqueEntity();
      Position.set(entityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
      ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, entityId);
    } else {
      require(ObjectType.get(entityId) == AirObjectID, "PlayerSystem: spawn coord is not air");
    }

    // Set object type to player
    ObjectType.set(entityId, PlayerObjectID);
    Player.set(newPlayer, entityId);
    ReversePlayer.set(entityId, newPlayer);

    Health.set(entityId, block.number, MAX_PLAYER_HEALTH);
    Stamina.set(entityId, block.number, MAX_PLAYER_STAMINA);

    // We let the user pick a y coord, so we need to apply gravity
    VoxelCoord memory belowCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
    if (belowEntityId == bytes32(0) || ObjectType.get(belowEntityId) == AirObjectID) {
      require(!applyGravity(entityId, spawnCoord), "PlayerSystem: cannot spawn player with gravity");
    }

    return entityId;
  }

  function activatePlayer(bytes32 playerEntityId) public {
    regenHealth(playerEntityId);
    regenStamina(playerEntityId);
  }

  function hit(address hitPlayer) public {
    bytes32 playerEntityId = Player.get(_msgSender());
    require(playerEntityId != bytes32(0), "PlayerSystem: player does not exist");
    bytes32 hitEntityId = Player.get(hitPlayer);
    require(hitEntityId != bytes32(0), "PlayerSystem: hit player does not exist");
    require(playerEntityId != hitEntityId, "PlayerSystem: player cannot hit itself");

    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position.get(playerEntityId));
    VoxelCoord memory hitCoord = positionDataToVoxelCoord(Position.get(hitEntityId));
    require(
      (hitCoord.x < SPAWN_LOW_X || hitCoord.x > SPAWN_HIGH_X) ||
        (hitCoord.z < SPAWN_LOW_Z || hitCoord.z > SPAWN_HIGH_Z),
      "PlayerSystem: cannot hit at spawn area"
    );
    require(
      inSurroundingCube(playerCoord, 1, hitCoord),
      "PlayerSystem: hit entity is not in surrounding cube of player"
    );

    regenHealth(playerEntityId);
    regenStamina(playerEntityId);
    useEquipped(playerEntityId);

    // Calculate stamina and health reduction
    uint32 currentStamina = Stamina.getStamina(playerEntityId);
    require(currentStamina > 0, "PlayerSystem: player has no stamina");
    uint32 staminaRequired = HIT_STAMINA_COST;

    // Try spending all the stamina
    uint32 staminaSpend = staminaRequired > currentStamina ? currentStamina : staminaRequired;

    bytes32 equippedEntityId = Equipped.get(playerEntityId);
    uint32 receiverDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      receiverDamage = ObjectTypeMetadata.getDamage(ObjectType.get(equippedEntityId));
    }

    // Update damage to be the actual damage done
    if (staminaSpend < staminaRequired) {
      receiverDamage = (staminaSpend * receiverDamage) / HIT_STAMINA_COST;
    }
    require(receiverDamage > 0, "PlayerSystem: damage is 0");

    // Update stamina and health
    Stamina.setStamina(playerEntityId, currentStamina - staminaSpend);

    uint16 currentHealth = Health.getHealth(hitEntityId);
    uint16 newHealth = currentHealth > uint16(receiverDamage) ? currentHealth - uint16(receiverDamage) : 0;
    Health.setHealth(hitEntityId, newHealth);

    if (newHealth == 0) {
      despawnPlayer(hitEntityId);
    }
  }
}
