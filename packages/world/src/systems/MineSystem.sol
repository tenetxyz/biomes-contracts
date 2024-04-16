// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
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
import { positionDataToVoxelCoord, callGravity, inWorldBorder, inSpawnArea } from "../Utils.sol";
import { addToInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { getObjectTypeIsBlock, getTerrainObjectTypeId } from "../utils/TerrainUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_BUILD_MINE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord, callGravity } from "../Utils.sol";
import { addToInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { isPick, isAxe, isLog, isStone } from "@biomesaw/terrain/src/utils/ObjectTypeUtils.sol";
import { getObjectTypeMiningDifficulty, getObjectTypeDamage } from "../utils/TerrainUtils.sol";

contract MineSystem is System {
  function mine(VoxelCoord memory coord) public returns (bytes32) {
    require(inWorldBorder(coord), "MineSystem: cannot mine outside world border");
    require(!inSpawnArea(coord), "MineSystem: cannot mine at spawn area");

    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "MineSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "MineSystem: player isn't logged in");
    require(
      inSurroundingCube(
        positionDataToVoxelCoord(Position._get(playerEntityId)),
        MAX_PLAYER_BUILD_MINE_HALF_WIDTH,
        coord
      ),
      "MineSystem: player is too far from the block"
    );
    regenHealth(playerEntityId);
    regenStamina(playerEntityId);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    uint8 mineObjectTypeId;
    if (entityId == bytes32(0)) {
      // Check terrain block type
      mineObjectTypeId = getTerrainObjectTypeId(coord);

      // Create new entity
      entityId = getUniqueEntity();
      ObjectType._set(entityId, mineObjectTypeId);
    } else {
      mineObjectTypeId = ObjectType._get(entityId);

      Position._deleteRecord(entityId);
      ReversePosition._deleteRecord(coord.x, coord.y, coord.z);
    }
    require(getObjectTypeIsBlock(mineObjectTypeId), "MineSystem: object type is not a block");
    require(mineObjectTypeId != AirObjectID, "MineSystem: cannot mine air");

    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    uint32 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      uint8 equippedObjectTypeId = ObjectType._get(equippedEntityId);
      equippedToolDamage = getObjectTypeDamage(equippedObjectTypeId);
    }

    // Spend stamina for mining
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    uint32 staminaRequired = (getObjectTypeMiningDifficulty(mineObjectTypeId) * 1000) / equippedToolDamage;
    require(currentStamina >= staminaRequired, "MineSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - staminaRequired);

    useEquipped(playerEntityId, equippedEntityId);

    // Make the new position air
    bytes32 airEntityId = getUniqueEntity();
    ObjectType._set(airEntityId, AirObjectID);
    Position._set(airEntityId, coord.x, coord.y, coord.z);
    ReversePosition._set(coord.x, coord.y, coord.z, airEntityId);

    // transfer existing inventory to the air entity, if any
    transferAllInventoryEntities(entityId, airEntityId, AirObjectID);

    Inventory._set(entityId, playerEntityId);
    ReverseInventory._push(playerEntityId, entityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    // Apply gravity
    VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
    bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      callGravity(aboveEntityId, aboveCoord);
    }

    return entityId;
  }
}
