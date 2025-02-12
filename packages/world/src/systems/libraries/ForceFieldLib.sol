// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { VoxelCoord } from "../../Types.sol";

import { Chip } from "../../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
import { getForceField, setupForceField, destroyForceField } from "../../utils/ForceFieldUtils.sol";

import { IForceFieldChip } from "../../prototypes/IForceFieldChip.sol";

import { EntityId } from "../../EntityId.sol";

library ForceFieldLib {
  function requireBuildsAllowed(
    EntityId playerEntityId,
    EntityId baseEntityId,
    uint16 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) public payable {
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      EntityId forceFieldEntityId = getForceField(coord);
      if (objectTypeId == ForceFieldObjectID) {
        require(!forceFieldEntityId.exists(), "Force field overlaps with another force field");
        setupForceField(baseEntityId, coord);
      }

      if (forceFieldEntityId.exists()) {
        address chipAddress = Chip._get(forceFieldEntityId);
        EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
        if (chipAddress != address(0) && machineData.energy > 0) {
          bool buildAllowed = IForceFieldChip(chipAddress).onBuild{ value: WorldContextConsumerLib._msgValue() }(
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
    EntityId playerEntityId,
    EntityId baseEntityId,
    uint16 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) public payable {
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      EntityId forceFieldEntityId = getForceField(coord);
      if (forceFieldEntityId.exists()) {
        address chipAddress = Chip._get(forceFieldEntityId);
        EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
        if (chipAddress != address(0) && machineData.energy > 0) {
          bool mineAllowed = IForceFieldChip(chipAddress).onMine{ value: WorldContextConsumerLib._msgValue() }(
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
