// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoordIgnoreY } from "@biomesaw/utils/src/VoxelCoordUtils.sol";

import { Stamina } from "../../codegen/tables/Stamina.sol";
import { Chip, ChipData } from "../../codegen/tables/Chip.sol";

import { MAX_PLAYER_STAMINA } from "../../Constants.sol";
import { ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateChipBatteryLevel } from "../../utils/ChipUtils.sol";
import { getForceField, setupForceField, destroyForceField } from "../../utils/ForceFieldUtils.sol";

import { IChip } from "../../prototypes/IChip.sol";

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
        bool buildAllowed = IChip(chipAddress).onBuild{ value: _msgValue() }(
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
    if (forceFieldEntityId != bytes32(0)) {
      address chipAddress = Chip._getChipAddress(forceFieldEntityId);
      if (chipAddress != address(0)) {
        updateChipBatteryLevel(forceFieldEntityId);

        // Forward any ether sent with the transaction to the hook
        // TODO: Figure out a way to accurately estimate gas in the client to then change this to be a safe call instead
        // since mines should not be blockable by the chip
        bool mineAllowed = IChip(chipAddress).onMine{ value: _msgValue() }(
          forceFieldEntityId,
          playerEntityId,
          objectTypeId,
          coord,
          extraData
        );
        if (!mineAllowed) {
          // Apply an additional stamina cost for mining inside of a force field
          // Scale the stamina required by the chip's battery level
          uint256 staminaRequired = (Chip._getBatteryLevel(forceFieldEntityId) * 1000) / equippedToolDamage;
          uint32 currentStamina = Stamina._getStamina(playerEntityId);
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

    if (objectTypeId == ForceFieldObjectID) {
      destroyForceField(entityId, coord);
    }
  }
}
