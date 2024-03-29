// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IMoveSystem } from "../codegen/world/IMoveSystem.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata, ObjectTypeMetadataData } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { Inventory } from "../codegen/tables/Inventory.sol";
import { ReverseInventory } from "../codegen/tables/ReverseInventory.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId, callGravity } from "../Utils.sol";
import { addToInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z } from "../Constants.sol";
import { isPick, isAxe, isWoodLog, isStone } from "../utils/ObjectTypeUtils.sol";

// We extract some logic out of the MineSystem due to contract size limitations
contract MineHelperSystem is System {
  function spendStaminaForMining(bytes32 playerEntityId, bytes32 mineObjectTypeId, bytes32 equippedEntityId) public {
    uint32 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      bytes32 equippedObjectTypeId = ObjectType.get(equippedEntityId);
      equippedToolDamage = ObjectTypeMetadata.getDamage(equippedObjectTypeId);
      if (isPick(equippedObjectTypeId) && isStone(mineObjectTypeId)) {
        equippedToolDamage *= 2;
      }
      if (isAxe(equippedObjectTypeId) && isWoodLog(mineObjectTypeId)) {
        equippedToolDamage *= 2;
      }
    }
    // Spend stamina for mining
    uint32 currentStamina = Stamina.getStamina(playerEntityId);
    uint32 staminaRequired = (ObjectTypeMetadata.getMass(mineObjectTypeId) *
      ObjectTypeMetadata.getHardness(mineObjectTypeId) *
      1000) / equippedToolDamage;
    require(currentStamina >= staminaRequired, "MineSystem: not enough stamina");
    Stamina.setStamina(playerEntityId, currentStamina - staminaRequired);
  }
}
