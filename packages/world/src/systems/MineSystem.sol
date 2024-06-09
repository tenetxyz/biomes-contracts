// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerMetadata } from "../codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { Stamina } from "../codegen/tables/Stamina.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { ChestMetadata, ChestMetadataData } from "../codegen/tables/ChestMetadata.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { positionDataToVoxelCoord, callGravity, inWorldBorder, inSpawnArea, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID, ReinforcedChestObjectID, BedrockChestObjectID } from "../ObjectTypeIds.sol";
import { IChestTransferHook } from "../prototypes/IChestTransferHook.sol";

contract MineSystem is System {
  function mine(VoxelCoord memory coord) public {
    require(inWorldBorder(coord), "MineSystem: cannot mine outside world border");
    require(!inSpawnArea(coord), "MineSystem: cannot mine at spawn area");

    bytes32 playerEntityId = Player._get(_msgSender());
    require(playerEntityId != bytes32(0), "MineSystem: player does not exist");
    require(!PlayerMetadata._getIsLoggedOff(playerEntityId), "MineSystem: player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position._get(playerEntityId));
    require(
      inSurroundingCube(playerCoord, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, coord),
      "MineSystem: player is too far from the block"
    );

    regenHealth(playerEntityId);
    regenStamina(playerEntityId, playerCoord);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    uint8 mineObjectTypeId;
    if (entityId == bytes32(0)) {
      // Check terrain block type
      mineObjectTypeId = getTerrainObjectTypeId(coord);

      // Create new entity
      entityId = getUniqueEntity();
      Position._set(entityId, coord.x, coord.y, coord.z);
      ReversePosition._set(coord.x, coord.y, coord.z, entityId);
    } else {
      mineObjectTypeId = ObjectType._get(entityId);
    }
    require(ObjectTypeMetadata._getIsBlock(mineObjectTypeId), "MineSystem: object type is not a block");
    require(mineObjectTypeId != AirObjectID, "MineSystem: cannot mine air");
    require(mineObjectTypeId != WaterObjectID, "MineSystem: cannot mine water");

    bytes32 equippedEntityId = Equipped._get(playerEntityId);
    uint32 equippedToolDamage = PLAYER_HAND_DAMAGE;
    if (equippedEntityId != bytes32(0)) {
      equippedToolDamage = ObjectTypeMetadata._getDamage(ObjectType._get(equippedEntityId));
    }

    // Spend stamina for mining
    uint32 currentStamina = Stamina._getStamina(playerEntityId);
    if (mineObjectTypeId == ReinforcedChestObjectID || mineObjectTypeId == BedrockChestObjectID) {
      ChestMetadataData memory chestMetadata = ChestMetadata._get(entityId);

      // Strength needs to first become 0 before the chest can be minedt
      uint256 strengthStaminaRequired = (uint256(chestMetadata.strength) * 1000) / equippedToolDamage;
      if (strengthStaminaRequired == 0) {
        for (uint256 i = 0; i < chestMetadata.strengthenObjectTypeIds.length; i++) {
          addToInventoryCount(
            entityId,
            AirObjectID,
            chestMetadata.strengthenObjectTypeIds[i],
            chestMetadata.strengthenObjectTypeAmounts[i]
          );
        }

        if (chestMetadata.onTransferHook != address(0)) {
          IChestTransferHook(chestMetadata.onTransferHook).onHookRemoved(entityId);
        }

        ChestMetadata._deleteRecord(entityId);
      } else {
        if (currentStamina >= strengthStaminaRequired) {
          chestMetadata.strength = 0;
          ChestMetadata._set(entityId, chestMetadata);

          Stamina._setStamina(playerEntityId, currentStamina - uint32(strengthStaminaRequired));
        } else {
          // Use all the current stamina
          uint256 reduceStrength = (currentStamina * equippedToolDamage) / 1000;
          chestMetadata.strength -= reduceStrength;
          ChestMetadata._set(entityId, chestMetadata);

          Stamina._setStamina(playerEntityId, 0);
        }

        // Need to complete the mine in a separate transaction
        return;
      }
    }

    uint256 staminaRequired = (uint256(ObjectTypeMetadata._getMiningDifficulty(mineObjectTypeId)) * 1000) /
      equippedToolDamage;
    require(staminaRequired <= MAX_PLAYER_STAMINA, "MineSystem: mining difficulty too high. Try a stronger tool.");
    uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
    require(currentStamina >= useStamina, "MineSystem: not enough stamina");
    Stamina._setStamina(playerEntityId, currentStamina - useStamina);

    useEquipped(playerEntityId, equippedEntityId);

    ObjectType._set(entityId, AirObjectID);
    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    PlayerActivity._set(playerEntityId, block.timestamp);

    // Apply gravity
    VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
    bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
    if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
      callGravity(aboveEntityId, aboveCoord);
    }
  }
}
