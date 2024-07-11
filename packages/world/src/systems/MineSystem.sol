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
import { Chip, ChipData } from "../codegen/tables/Chip.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, PLAYER_HAND_DAMAGE } from "../Constants.sol";
import { positionDataToVoxelCoord, callGravity, inWorldBorder, inSpawnArea, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { addToInventoryCount, useEquipped, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { regenHealth, regenStamina } from "../utils/PlayerUtils.sol";
import { inSurroundingCube } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { callInternalSystem } from "@biomesaw/utils/src/CallUtils.sol";
import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { updateChipBatteryLevel } from "../utils/ChipUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { IChip } from "../prototypes/IChip.sol";

contract MineSystem is System {
  function mine(VoxelCoord memory coord, bytes memory extraData) public payable {
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

      require(Chip._getChipAddress(entityId) == address(0), "MineSystem: chip must be detached first");
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
    uint32 newStamina;
    {
      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      uint256 staminaRequired = (uint256(ObjectTypeMetadata._getMiningDifficulty(mineObjectTypeId)) * 1000) /
        equippedToolDamage;
      require(staminaRequired <= MAX_PLAYER_STAMINA, "MineSystem: mining difficulty too high. Try a stronger tool.");
      uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
      require(currentStamina >= useStamina, "MineSystem: not enough stamina");
      newStamina = currentStamina - useStamina;
      Stamina._setStamina(playerEntityId, newStamina);
    }

    useEquipped(playerEntityId, equippedEntityId);

    ObjectType._set(entityId, AirObjectID);
    addToInventoryCount(playerEntityId, PlayerObjectID, mineObjectTypeId, 1);

    PlayerActivity._set(playerEntityId, block.timestamp);

    // Apply gravity
    {
      VoxelCoord memory aboveCoord = VoxelCoord(coord.x, coord.y + 1, coord.z);
      bytes32 aboveEntityId = ReversePosition._get(aboveCoord.x, aboveCoord.y, aboveCoord.z);
      if (aboveEntityId != bytes32(0) && ObjectType._get(aboveEntityId) == PlayerObjectID) {
        callGravity(aboveEntityId, aboveCoord);
      }
    }

    // Note: we call this after the mine state has been updated, to prevent re-entrancy attacks
    requireAllowed(playerEntityId, newStamina, equippedToolDamage, mineObjectTypeId, coord, extraData);
  }

  function requireAllowed(
    bytes32 playerEntityId,
    uint32 currentStamina,
    uint32 equippedToolDamage,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) internal {
    bytes32 forceFieldEntityId = getForceField(coord);
    if (forceFieldEntityId != bytes32(0)) {
      uint256 staminaRequired = 0;
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // Don't safe call here as we want to revert if the chip doesn't allow the mine
        bool mineAllowed = IChip(chipAddress).onMine{ value: msg.value }(
          playerEntityId,
          objectTypeId,
          coord,
          extraData
        );
        if (!mineAllowed) {
          // Scale the stamina required by the chip's battery level
          staminaRequired = 1000 * Chip._getBatteryLevel(forceFieldEntityId);
        }
      } else {
        staminaRequired = 1000;
      }

      // Apply an additional stamina cost for mining inside of a force field
      if (staminaRequired > 0) {
        staminaRequired = (staminaRequired * 1000) / equippedToolDamage;
        require(
          staminaRequired <= MAX_PLAYER_STAMINA,
          "MineSystem: mining difficulty too high due to force field. Try a stronger tool."
        );
        uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
        require(currentStamina >= useStamina, "MineSystem: not enough stamina due to force field");
        Stamina._setStamina(playerEntityId, currentStamina - useStamina);
      }
    }
  }
}
