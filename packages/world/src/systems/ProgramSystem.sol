// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { ActionType } from "../codegen/common.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";
import { EntityProgram } from "../codegen/tables/EntityProgram.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField, isForceFieldFragmentActive } from "../utils/ForceFieldUtils.sol";
import { AttachProgramNotifData, DetachProgramNotifData, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { SAFE_PROGRAM_GAS } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";

import { ProgramId } from "../ProgramId.sol";
import { IAttachProgramHook, IDetachProgramHook, IProgramValidator } from "../ProgramInterfaces.sol";
import { Vec3 } from "../Vec3.sol";

contract ProgramSystem is System {
  function attachProgram(EntityId caller, EntityId target, ProgramId program, bytes calldata extraData) public payable {
    caller.activate();
    (, Vec3 targetCoord) = caller.requireConnected(target);
    target = target.baseEntityId();

    require(!target.getProgram().exists(), "Existing program must be detached");

    (, bool publicAccess) = Systems._get(program.toResourceId());
    require(!publicAccess, "Program system must be private");

    (EntityId validator, ProgramId validatorProgram) = _getValidatorProgram(targetCoord);

    bytes memory validateProgram =
      abi.encodeCall(IProgramValidator.validateProgram, (caller, validator, target, program, extraData));

    // The validateProgram view function should revert if the program is not allowed
    validatorProgram.staticcallOrRevert(validateProgram);

    EntityProgram._set(target, program);

    program.callOrRevert(abi.encodeCall(IAttachProgramHook.onAttachProgram, (caller, target, extraData)));

    notify(caller, AttachProgramNotifData({ attachedTo: target, programSystemId: program.toResourceId() }));
  }

  function detachProgram(EntityId caller, EntityId target, bytes calldata extraData) public payable {
    caller.activate();
    (, Vec3 targetCoord) = caller.requireConnected(target);
    target = target.baseEntityId();

    ProgramId program = target.getProgram();
    require(program.exists(), "No program attached");

    bytes memory onDetachProgram = abi.encodeCall(IDetachProgramHook.onDetachProgram, (caller, target, extraData));

    (EntityId forceField,) = getForceField(targetCoord);
    // If forcefield doesn't have energy, allow the program
    (EnergyData memory machineData,) = updateMachineEnergy(forceField);
    if (machineData.energy > 0) {
      program.callOrRevert(onDetachProgram);
    } else {
      program.call({ gas: SAFE_PROGRAM_GAS, hook: onDetachProgram });
    }

    EntityProgram._deleteRecord(target);

    notify(caller, DetachProgramNotifData({ detachedFrom: target, programSystemId: program.toResourceId() }));
  }

  function _getValidatorProgram(Vec3 coord) internal returns (EntityId, ProgramId) {
    // Check if the forcefield (or fragment) allow the new program
    (EntityId forceField, EntityId fragment) = getForceField(coord);
    if (!forceField.exists()) {
      return (EntityId.wrap(0), ProgramId.wrap(0));
    }

    // If forcefield doesn't have energy, allow the program
    (EnergyData memory machineData,) = updateMachineEnergy(forceField);
    if (machineData.energy == 0) {
      return (EntityId.wrap(0), ProgramId.wrap(0));
    }

    // Try to get program from fragment first, then from force field if needed
    ProgramId program = fragment.getProgram();
    EntityId validator = fragment;

    // If fragment has no program, try the force field
    if (!program.exists()) {
      program = forceField.getProgram();
      validator = forceField;

      // If neither has a program, we're done
      if (!program.exists()) {
        return (EntityId.wrap(0), ProgramId.wrap(0));
      }
    }

    return (validator, program);
  }
}
