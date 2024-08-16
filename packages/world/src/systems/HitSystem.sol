// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Health } from "../codegen/tables/Health.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PLAYER_HAND_DAMAGE, HIT_PLAYER_STAMINA_COST } from "../Constants.sol";
import { PlayerObjectID } from "../ObjectTypeIds.sol";
import { callGravity, inSpawnArea } from "../Utils.sol";
import { useEquipped } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireBesidePlayer, despawnPlayer } from "../utils/PlayerUtils.sol";

contract HitSystem is System {
  function hit(address hitPlayer) public {
    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    (bytes32 hitEntityId, VoxelCoord memory hitCoord) = requireValidPlayer(hitPlayer);
    require(playerEntityId != hitEntityId, "HitSystem: cannot hit yourself");
    require(!inSpawnArea(hitCoord), "HitSystem: cannot hit players in spawn area");
    requireBesidePlayer(playerCoord, hitCoord);

    // Update stamina and health
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint16 staminaRequired = HIT_PLAYER_STAMINA_COST;
    require(currentStamina >= staminaRequired, "HitSystem: player does not have enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    uint16 receiverDamage = PLAYER_HAND_DAMAGE;
    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    if (equippedEntityId != bytes32(0)) {
      receiverDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }

    uint16 currentHealth = Health._getHealth(hitEntityId);
    uint16 newHealth = currentHealth > receiverDamage ? currentHealth - receiverDamage : 0;
    Health._setHealth(hitEntityId, newHealth);

    useEquipped(playerEntityId, equippedEntityId);

    if (newHealth == 0) {
      despawnPlayer(hitEntityId);

      VoxelCoord memory aboveCoord = VoxelCoord(hitCoord.x, hitCoord.y + 1, hitCoord.z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    } else {
      PlayerMetadata._setLastHitTime(hitEntityId, block.timestamp);
    }

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Hit,
        entityId: hitEntityId,
        objectTypeId: PlayerObjectID,
        coordX: hitCoord.x,
        coordY: hitCoord.y,
        coordZ: hitCoord.z,
        amount: newHealth
      })
    );
  }
}
