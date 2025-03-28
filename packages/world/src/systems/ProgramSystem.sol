// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";

import { EntityProgram } from "../codegen/tables/EntityProgram.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField, isForceFieldFragmentActive } from "../utils/ForceFieldUtils.sol";
import { notify, AttachProgramNotifData, DetachProgramNotifData } from "../utils/NotifUtils.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { ProgramId } from "../ProgramId.sol";

contract ProgramSystem is System {
  function attachProgram(
    EntityId caller,
    EntityId target,
    ProgramId newProgram,
    bytes calldata extraData
  ) public payable {
    caller.activate();
    (, Vec3 targetCoord) = caller.requireConnected(target);

    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    // if (objectTypeId == ObjectTypes.ForceFieldFragment) {
    //   // TODO: figure out proximity checks for fragments
    // }

    (, bool publicAccess) = Systems._get(newProgram.toResourceId());
    require(!publicAccess, "Program system must be private");

    target = target.baseEntityId();

    ObjectTypeId objectTypeId = ObjectType._get(target);

    ProgramId oldProgram = target.getProgram();

    _requireProgramAllowed(caller, target, oldProgram, newProgram, extraData, objectTypeId, targetCoord);

    EntityProgram._set(target, newProgram);

    // TODO: should we call onDetach for the old one?
    newProgram.onAttachProgram(caller, target, extraData);

    notify(caller, AttachProgramNotifData({ attachEntityId: target, programSystemId: newProgram.toResourceId() }));
  }

  function detachProgram(EntityId caller, EntityId target, bytes calldata extraData) public payable {
    caller.activate();
    (, Vec3 targetCoord) = caller.requireConnected(target);
    target = target.baseEntityId();

    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    // if (ObjectType._get(baseEntityId) == ObjectTypes.ForceFieldFragment) {
    //   // TODO: figure out proximity checks for fragments
    // }

    ProgramId oldProgram = target.getProgram();
    require(oldProgram.exists(), "No program attached");

    ObjectTypeId objectTypeId = ObjectType._get(target);

    _requireProgramAllowed(caller, target, oldProgram, ProgramId.wrap(0), extraData, objectTypeId, targetCoord);

    EntityProgram._deleteRecord(target);

    oldProgram.onDetachProgram(caller, target, extraData);

    notify(caller, DetachProgramNotifData({ detachEntityId: target, programSystemId: oldProgram.toResourceId() }));
  }

  function _requireProgramAllowed(
    EntityId caller,
    EntityId target,
    ProgramId oldProgram,
    ProgramId newProgram,
    bytes memory extraData,
    ObjectTypeId objectTypeId,
    Vec3 targetCoord
  ) internal {
    bool allowed = oldProgram.isProgramAllowed(caller, target, target, oldProgram, newProgram, extraData);
    if (allowed || objectTypeId == ObjectTypes.ForceField) {
      return;
    }

    (EntityId forceField, EntityId fragment) = getForceField(targetCoord);
    if (!forceField.exists()) {
      return;
    }

    (EnergyData memory machineData, ) = updateMachineEnergy(forceField);
    if (machineData.energy == 0) {
      return;
    }

    // Try to get program from fragment first, then from force field if needed
    ProgramId program = fragment.getProgram();
    EntityId programOwner = fragment;

    // If fragment has no program, try the force field
    if (!program.exists()) {
      program = forceField.getProgram();
      programOwner = forceField;

      // If neither has a program, we're done
      if (!program.exists()) {
        return;
      }
    }

    // Check if the program allows the operation
    require(program.isProgramAllowed(caller, programOwner, target, oldProgram, newProgram, extraData), "Not allowed");
  }
}
