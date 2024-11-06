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

import { MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../../Constants.sol";
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
    uint32 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      equippedToolDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }
    uint256 miningDifficulty = uint256(ObjectTypeMetadata._getMiningDifficulty(mineObjectTypeId));
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint256 staminaRequired = (miningDifficulty * 1000) / (equippedToolDamage);
    require(staminaRequired <= MAX_PLAYER_STAMINA, "MineSystem: mining difficulty too high. Try a stronger tool.");
    uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
    require(currentStamina >= useStamina, "MineSystem: not enough stamina");
    uint32 newStamina = currentStamina - useStamina;
    Stamina._setStamina(playerEntityId, newStamina);

    useEquipped(playerEntityId, equippedEntityId);

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