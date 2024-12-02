// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { inSurroundingCube, voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { ObjectType } from "../../codegen/tables/ObjectType.sol";
import { Equipped } from "../../codegen/tables/Equipped.sol";
import { Position } from "../../codegen/tables/Position.sol";
import { ReversePosition } from "../../codegen/tables/ReversePosition.sol";
import { Stamina } from "../../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_HAND_DAMAGE, MINE_STAMINA_COST } from "../../Constants.sol";
import { PlayerObjectID } from "../../ObjectTypeIds.sol";
import { callGravity } from "../../Utils.sol";
import { addToInventoryCount, useEquipped } from "../../utils/InventoryUtils.sol";

contract MineHelperSystem is System {
  function onMine(
    bytes32 playerEntityId,
    bytes32 baseEntityId,
    uint8 mineObjectTypeId,
    VoxelCoord[] memory coords
  ) public {
    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    uint16 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      equippedToolDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint32 staminaRequired = MINE_STAMINA_COST;
    require(currentStamina >= staminaRequired, "MineSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    uint16 miningDifficulty = ObjectTypeMetadata._getMiningDifficulty(mineObjectTypeId);
    useEquipped(
      playerEntityId,
      equippedEntityId,
      mineObjectTypeId,
      (uint24(miningDifficulty) * uint24(1000)) / equippedToolDamage
    );

    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    // Apply gravity
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    }
  }
}
