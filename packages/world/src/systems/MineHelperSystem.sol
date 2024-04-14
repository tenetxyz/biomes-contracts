// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IMoveSystem } from "../codegen/world/IMoveSystem.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, callGravity } from "../Utils.sol";
import { addToInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { isPick, isAxe, isLog, isStone } from "@biomesaw/terrain/src/utils/ObjectTypeUtils.sol";
import { getObjectTypeMass, getObjectTypeDamage, getObjectTypeHardness } from "../utils/TerrainUtils.sol";

// We extract some logic out of the MineSystem due to contract size limitations
contract MineHelperSystem is System {
  function spendStaminaForMining(bytes32 playerEntityId, uint8 mineObjectTypeId, bytes32 equippedEntityId) public {
    uint32 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      uint8 equippedObjectTypeId = ObjectType._get(equippedEntityId);
      equippedToolDamage = getObjectTypeDamage(equippedObjectTypeId);
      if (isPick(equippedObjectTypeId) && isStone(mineObjectTypeId)) {
        equippedToolDamage *= 2;
      }
      if (isAxe(equippedObjectTypeId) && isLog(mineObjectTypeId)) {
        equippedToolDamage *= 2;
      }
    }
    // Spend stamina for mining
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint32 staminaRequired = (getObjectTypeMass(mineObjectTypeId) * getObjectTypeHardness(mineObjectTypeId) * 1000) /
      equippedToolDamage;
    require(currentStamina >= staminaRequired, "MineSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);
  }
}
