// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { SystemCall } from "@latticexyz/world/src/SystemCall.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IWorld } from "../../codegen/world/IWorld.sol";
import { Vec3 } from "../../Vec3.sol";

import { Chip } from "../../codegen/tables/Chip.sol";
import { Energy, EnergyData } from "../../codegen/tables/Energy.sol";

import { ObjectTypeId } from "../../ObjectTypeId.sol";
import { ObjectTypes } from "../../ObjectTypes.sol";
import { updateEnergyLevel } from "../../utils/EnergyUtils.sol";
import { getForceField, setupForceField, destroyForceField } from "../../utils/ForceFieldUtils.sol";

import { IForceFieldChip } from "../../prototypes/IForceFieldChip.sol";

import { callChipOrRevert } from "../../utils/callChip.sol";
import { EntityId } from "../../EntityId.sol";

library ForceFieldLib {
  function requireBuildsAllowed(
    EntityId playerEntityId,
    EntityId baseEntityId,
    ObjectTypeId objectTypeId,
    Vec3[] memory coords,
    bytes memory extraData
  ) public {
    for (uint256 i = 0; i < coords.length; i++) {
      Vec3 coord = coords[i];
      EntityId forceFieldEntityId = getForceField(coord);
      if (objectTypeId == ObjectTypes.ForceField) {
        require(!forceFieldEntityId.exists(), "Force field overlaps with another force field");
        setupForceField(baseEntityId, coord);
      }

      if (forceFieldEntityId.exists()) {
        EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onBuildCall = abi.encodeCall(
            IForceFieldChip.onBuild,
            (forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData)
          );

          callChipOrRevert(forceFieldEntityId.getChipAddress(), onBuildCall);
        }
      }
    }
  }

  function requireMinesAllowed(
    EntityId playerEntityId,
    EntityId baseEntityId,
    ObjectTypeId objectTypeId,
    Vec3[] memory coords,
    bytes memory extraData
  ) public {
    for (uint256 i = 0; i < coords.length; i++) {
      Vec3 coord = coords[i];
      EntityId forceFieldEntityId = getForceField(coord);
      if (forceFieldEntityId.exists()) {
        EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onMineCall = abi.encodeCall(
            IForceFieldChip.onMine,
            (forceFieldEntityId, playerEntityId, objectTypeId, coord, extraData)
          );

          callChipOrRevert(forceFieldEntityId.getChipAddress(), onMineCall);
        }
      }

      if (objectTypeId == ObjectTypes.ForceField) {
        destroyForceField(baseEntityId, coord);
      }
    }
  }
}
