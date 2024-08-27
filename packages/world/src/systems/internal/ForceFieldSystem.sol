// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Stamina } from "../../codegen/tables/Stamina.sol";
import { Chip, ChipData } from "../../codegen/tables/Chip.sol";
import { ObjectTypeMetadata } from "../../codegen/tables/ObjectTypeMetadata.sol";

import { MAX_PLAYER_STAMINA } from "../../Constants.sol";
import { ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateChipBatteryLevel } from "../../utils/ChipUtils.sol";
import { getForceField, setupForceField, destroyForceField } from "../../utils/ForceFieldUtils.sol";

import { IForceFieldChip } from "../../prototypes/IForceFieldChip.sol";

contract ForceFieldSystem is System {
  function requireBuildAllowed(
    bytes32 playerEntityId,
    bytes32 entityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) public payable {
    bytes32 forceFieldEntityId = getForceField(coord);
    if (objectTypeId == ForceFieldObjectID) {
      require(forceFieldEntityId == bytes32(0), "Force field overlaps with another force field");
      setupForceField(entityId, coord);
    }

    if (forceFieldEntityId != bytes32(0)) {
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // Don't safe call here as we want to revert if the chip doesn't allow the build
        bool buildAllowed = IForceFieldChip(chipAddress).onBuild{ value: _msgValue() }(
          forceFieldEntityId,
          playerEntityId,
          objectTypeId,
          coord,
          extraData
        );
        require(buildAllowed, "Player not authorized by chip to build here");
      }
    }
  }

  function requireMineAllowed(
    bytes32 playerEntityId,
    uint32 equippedToolDamage,
    bytes32 entityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) public payable {
    bytes32 forceFieldEntityId = getForceField(coord);
    uint256 forceFieldStaminaMultiplier = 10;
    uint256 miningDifficulty = uint256(ObjectTypeMetadata._getMiningDifficulty(objectTypeId));
    if (forceFieldEntityId != bytes32(0)) {
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // since mines should not be blockable by the chip
        (bool success, bytes memory onMineReturnValue) = chipAddress.call{ value: _msgValue() }(
          abi.encodeCall(IForceFieldChip.onMine, (forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData))
        );
        bool mineAllowed = success && abi.decode(onMineReturnValue, (bool));
        if (!mineAllowed) {
          // Apply an additional stamina cost for mining inside of a force field
          uint256 currentChargeLevel = Chip._getBatteryLevel(forceFieldEntityId);
          if (currentChargeLevel < 2 days) {
            if (miningDifficulty < 100) {
              forceFieldStaminaMultiplier = 2000;
            } else if (miningDifficulty >= 100 && miningDifficulty < 1000) {
              forceFieldStaminaMultiplier = 680;
            } else if (miningDifficulty >= 1000 && miningDifficulty <= 4000) {
              forceFieldStaminaMultiplier = 140;
            } else {
              forceFieldStaminaMultiplier = 13;
            }
          } else {
            if (miningDifficulty < 100) {
              forceFieldStaminaMultiplier = 9000;
            } else if (miningDifficulty >= 100 && miningDifficulty < 1000) {
              forceFieldStaminaMultiplier = 1060;
            } else if (miningDifficulty >= 1000 && miningDifficulty <= 4000) {
              forceFieldStaminaMultiplier = 230;
            } else {
              forceFieldStaminaMultiplier = 17;
            }
          }
        }
      }
    }

    {
      uint32 currentStamina = Stamina._getStamina(playerEntityId);
      uint256 staminaRequired = (forceFieldStaminaMultiplier * miningDifficulty * 1000) / (equippedToolDamage * 10);
      require(staminaRequired <= MAX_PLAYER_STAMINA, "MineSystem: mining difficulty too high. Try a stronger tool.");
      uint32 useStamina = staminaRequired == 0 ? 1 : uint32(staminaRequired);
      require(currentStamina >= useStamina, "MineSystem: not enough stamina");
      uint32 newStamina = currentStamina - useStamina;
      Stamina._setStamina(playerEntityId, newStamina);
    }

    if (objectTypeId == ForceFieldObjectID) {
      destroyForceField(entityId, coord);
    }
  }
}
