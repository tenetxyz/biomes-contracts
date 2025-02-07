// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Chip } from "../../codegen/tables/Chip.sol";

import { ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
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
        address chipAddress = Chip._get(forceFieldEntityId);
        MachineData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
        if (chipAddress != address(0) && machineData.energyLevel > 0) {
          bool buildAllowed = IForceFieldChip(chipAddress).onBuild{ value: _msgValue() }(
            forceFieldEntityId,
            playerEntityId,
            objectTypeId,
            coord,
            extraData
          );
          require(buildAllowed, "Build not allowed by force field's chip");
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
        address chipAddress = Chip._get(forceFieldEntityId);
        MachineData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
        if (chipAddress != address(0) && machineData.energyLevel > 0) {
          bool mineAllowed = IForceFieldChip(chipAddress).onMine{ value: _msgValue() }(
            forceFieldEntityId,
            playerEntityId,
            objectTypeId,
            coord,
            extraData
          );
          require(mineAllowed, "Mine not allowed by force field's chip");
        }
      }

      if (objectTypeId == ForceFieldObjectID) {
        destroyForceField(baseEntityId, coord);
      }
    }
  }
}
