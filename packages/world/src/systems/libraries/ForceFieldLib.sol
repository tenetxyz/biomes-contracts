// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../../codegen/world/IWorld.sol";
import { VoxelCoord } from "../../Types.sol";

import { Chip } from "../../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { ForceFieldObjectID } from "../../ObjectTypeIds.sol";
import { updateMachineEnergyLevel } from "../../utils/MachineUtils.sol";
import { getForceField, setupForceField, destroyForceField } from "../../utils/ForceFieldUtils.sol";

import { IForceFieldChip } from "../../prototypes/IForceFieldChip.sol";

import { callChip, callChipOrRevert } from "../../utils/callChip.sol";
import { EntityId } from "../../EntityId.sol";

library ForceFieldLib {
  function requireBuildsAllowed(
    EntityId playerEntityId,
    EntityId baseEntityId,
    uint16 objectTypeId,
    VoxelCoord[] memory coords,
    bytes memory extraData
  ) public {
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      EntityId forceFieldEntityId = getForceField(coord);
      if (objectTypeId == ForceFieldObjectID) {
        require(!forceFieldEntityId.exists(), "Force field overlaps with another force field");
        setupForceField(baseEntityId, coord);
      }

      if (forceFieldEntityId.exists()) {
        EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onBuildCall = abi.encodeCall(
            IForceFieldChip.onBuild,
            (forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData)
          );

          bytes memory result = callChipOrRevert(forceFieldEntityId.getChipAddress(), onBuildCall);

          bool buildAllowed = abi.decode(result, (bool));
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
  ) public {
    for (uint256 i = 0; i < coords.length; i++) {
      VoxelCoord memory coord = coords[i];
      EntityId forceFieldEntityId = getForceField(coord);
      if (forceFieldEntityId.exists()) {
        EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onMineCall = abi.encodeCall(
            IForceFieldChip.onMine,
            (forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData)
          );

          bytes memory result = callChipOrRevert(forceFieldEntityId.getChipAddress(), onMineCall);

          bool mineAllowed = abi.decode(result, (bool));
          require(mineAllowed, "Mine not allowed by force field's chip");
        }
      }

      if (objectTypeId == ForceFieldObjectID) {
        destroyForceField(baseEntityId, coord);
      }
    }
  }
}
