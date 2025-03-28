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
  function attachProgram(EntityId caller, EntityId target, ProgramId program, bytes calldata extraData) public payable {
    caller.activate();
    (, Vec3 targetCoord) = caller.requireConnected(target);

    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    // if (objectTypeId == ObjectTypes.ForceFieldFragment) {
    //   // TODO: figure out proximity checks for fragments
    // }

    (, bool publicAccess) = Systems._get(program.toResourceId());
    require(!publicAccess, "Program system must be private");

    target = target.baseEntityId();
    EntityId programmed = target;

    ObjectTypeId objectTypeId = ObjectType._get(target);

    ProgramId currentProgram = target.getProgram();

    // If there is an existing program, either the program or the forcefield program must allow the change
    if (currentProgram.exists()) {
      bool allowed = currentProgram.onAttachProgram(caller, target, programmed, program, extraData);

      if (!allowed && objectTypeId != ObjectTypes.ForceField) {
        (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(targetCoord);
        if (forceFieldEntityId.exists()) {
          (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
          if (machineData.energy > 0) {
            // TODO: call forcefield program
          }
        }
      }

      require(allowed, "Not allowed");
    }

    // Program needs to be set after calling the forcefield's hook,
    // otherwise if it is a fragment it would call itself
    EntityProgram._set(programmed, program);

    program.onAttachProgram(caller, target, programmed, program, extraData);

    notify(caller, AttachProgramNotifData({ attachEntityId: programmed, programSystemId: program.toResourceId() }));
  }

  function detachProgram(EntityId caller, EntityId target, bytes calldata extraData) public payable {
    caller.activate();
    (, Vec3 targetCoord) = caller.requireConnected(target);
    target = target.baseEntityId();

    EntityId programmed = target;
    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    // if (ObjectType._get(baseEntityId) == ObjectTypes.ForceFieldFragment) {
    //   // TODO: figure out proximity checks for fragments
    // }

    ProgramId program = target.getProgram();
    require(program.exists(), "No program attached");

    EntityProgram._deleteRecord(programmed);

    ObjectTypeId objectTypeId = ObjectType._get(target);

    bool allowed = program.onDetachProgram(caller, target, programmed, program, extraData);

    if (!allowed && objectTypeId != ObjectTypes.ForceField) {
      (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(targetCoord);
      if (forceFieldEntityId.exists()) {
        (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);

        // If forcefield is active, call its hook
        if (machineData.energy > 0) {
          // Don't safe call here because we want to revert if the program doesn't allow the detachment
        }
      }
    }

    notify(caller, DetachProgramNotifData({ detachEntityId: programmed, programSystemId: program.toResourceId() }));
  }

  function _requireInterface(address programAddress, bytes4 interfaceId) internal view {
    require(
      ERC165Checker.supportsInterface(programAddress, interfaceId),
      "Program does not implement the required interface"
    );
  }
}
