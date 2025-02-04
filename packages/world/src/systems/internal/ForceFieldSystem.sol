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
  function requireBuildsAllowed(
    bytes32 playerEntityId,
    bytes32 baseEntityId,
    uint8 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) public payable {
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      bytes32 forceFieldEntityId = getForceField(coord);
      if (objectTypeId == ForceFieldObjectID) {
        require(forceFieldEntityId == bytes32(0), "Force field overlaps with another force field");
        setupForceField(baseEntityId, coord);
      }

      if (forceFieldEntityId != bytes32(0)) {
        ChipData memory chipData = updateChipBatteryLevel(forceFieldEntityId);
        if (chipData.chipAddress != address(0) && chipData.batteryLevel > 0) {
          bool buildAllowed = IForceFieldChip(chipData.chipAddress).onBuild{ value: _msgValue() }(
            forceFieldEntityId,
            playerEntityId,
            objectTypeId,
            coord,
            extraData
          );
          require(buildAllowed, "ForceFieldSystem: build not allowed by force field");
        }
      }
    }
  }

  function requireMinesAllowed(
    bytes32 playerEntityId,
    bytes32 baseEntityId,
    uint8 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) public payable {
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      bytes32 forceFieldEntityId = getForceField(coord);
      if (forceFieldEntityId != bytes32(0)) {
        ChipData memory chipData = updateChipBatteryLevel(forceFieldEntityId);
        if (chipData.chipAddress != address(0) && chipData.batteryLevel > 0) {
          bool mineAllowed = IForceFieldChip(chipData.chipAddress).onMine{ value: _msgValue() }(
            forceFieldEntityId,
            playerEntityId,
            objectTypeId,
            coord,
            extraData
          );
          require(mineAllowed, "ForceFieldSystem: mine not allowed by force field");
        }
      }

      if (objectTypeId == ForceFieldObjectID) {
        destroyForceField(baseEntityId, coord);
      }
    }
  }
}
