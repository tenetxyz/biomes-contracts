// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { NamespaceOwner } from "@latticexyz/world/src/codegen/tables/NamespaceOwner.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { EnergyData } from "../codegen/tables/Energy.sol";
import { Program } from "../codegen/tables/Program.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField, isForceFieldFragmentActive } from "../utils/ForceFieldUtils.sol";
import { notify, AttachProgramNotifData, DetachProgramNotifData } from "../utils/NotifUtils.sol";

import { IProgram } from "../prototypes/IProgram.sol";
import { IChestProgram } from "../prototypes/IChestProgram.sol";
import { IForceFieldProgram } from "../prototypes/IForceFieldProgram.sol";
import { IForceFieldFragmentProgram } from "../prototypes/IForceFieldFragmentProgram.sol";
import { IDisplayProgram } from "../prototypes/IDisplayProgram.sol";
import { ISpawnTileProgram } from "../prototypes/ISpawnTileProgram.sol";
import { IBedProgram } from "../prototypes/IBedProgram.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { safeCallProgram, callProgramOrRevert } from "../utils/callProgram.sol";

contract ProgramSystem is System {
  using WorldResourceIdInstance for ResourceId;

  function _requireInterface(address programAddress, bytes4 interfaceId) internal view {
    require(
      ERC165Checker.supportsInterface(programAddress, interfaceId),
      "Program does not implement the required interface"
    );
  }

  function _callForceFieldProgram(EntityId forceFieldEntityId, EntityId fragmentEntityId, bytes memory data) internal {
    // We know fragment is active because its forcefield exists, so we can use its program
    ResourceId fragmentProgram = fragmentEntityId.getProgram();
    if (fragmentProgram.unwrap() != 0) {
      callProgramOrRevert(fragmentProgram, data);
    } else {
      callProgramOrRevert(forceFieldEntityId.getProgram(), data);
    }
  }

  function attachProgram(EntityId entityId, ResourceId programSystemId, bytes calldata extraData) public payable {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());

    EntityId baseEntityId = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);

    require(baseEntityId.getProgram().unwrap() == 0, "Program already attached");

    Vec3 entityCoord;
    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    if (objectTypeId == ObjectTypes.ForceFieldFragment) {
      // TODO: figure out proximity checks for fragments
      entityCoord = PlayerUtils.requireFragmentInPlayerInfluence(playerCoord, baseEntityId);
    } else {
      entityCoord = PlayerUtils.requireInPlayerInfluence(playerCoord, entityId);
    }

    (address programAddress, bool publicAccess) = Systems._get(programSystemId);
    require(!publicAccess, "Program system must be private");

    if (objectTypeId == ObjectTypes.ForceField) {
      _requireInterface(programAddress, type(IForceFieldProgram).interfaceId);
    } else if (objectTypeId == ObjectTypes.ForceFieldFragment) {
      _requireInterface(programAddress, type(IForceFieldFragmentProgram).interfaceId);
    } else if (objectTypeId == ObjectTypes.SmartChest) {
      _requireInterface(programAddress, type(IChestProgram).interfaceId);
    } else if (objectTypeId == ObjectTypes.SmartTextSign) {
      _requireInterface(programAddress, type(IDisplayProgram).interfaceId);
    } else if (objectTypeId == ObjectTypes.SpawnTile) {
      _requireInterface(programAddress, type(ISpawnTileProgram).interfaceId);
    } else if (objectTypeId == ObjectTypes.Bed) {
      _requireInterface(programAddress, type(IBedProgram).interfaceId);
    } else {
      revert("Cannot attach a program to this object");
    }

    notify(
      playerEntityId,
      AttachProgramNotifData({ attachEntityId: baseEntityId, attachCoord: entityCoord, programAddress: programAddress })
    );

    // If forcefield is active, call its hook
    if (objectTypeId != ObjectTypes.ForceField) {
      (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(entityCoord);
      if (forceFieldEntityId.exists()) {
        (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onProgramAttachedCall = abi.encodeCall(
            IForceFieldFragmentProgram.onProgramAttached,
            (playerEntityId, forceFieldEntityId, baseEntityId, extraData)
          );

          _callForceFieldProgram(forceFieldEntityId, fragmentEntityId, onProgramAttachedCall);
        }
      }
    }

    // Program needs to be set after calling the forcefield's hook,
    // otherwise if it is a fragment it would call itself
    Program._setProgramSystemId(baseEntityId, programSystemId);

    bytes memory onAttachedCall = abi.encodeCall(IProgram.onAttached, (playerEntityId, baseEntityId, extraData));
    callProgramOrRevert(programSystemId, onAttachedCall);
  }

  function detachProgram(EntityId entityId, bytes calldata extraData) public payable {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());
    EntityId baseEntityId = entityId.baseEntityId();

    Vec3 entityCoord;
    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    if (ObjectType._get(baseEntityId) == ObjectTypes.ForceFieldFragment) {
      // TODO: figure out proximity checks for fragments
      entityCoord = PlayerUtils.requireFragmentInPlayerInfluence(playerCoord, baseEntityId);
    } else {
      entityCoord = PlayerUtils.requireInPlayerInfluence(playerCoord, entityId);
    }

    ResourceId programSystemId = baseEntityId.getProgram();

    require(programSystemId.unwrap() != 0, "No program attached");

    Program._deleteRecord(baseEntityId);

    (address programAddress, ) = Systems._get(programSystemId);

    notify(
      playerEntityId,
      DetachProgramNotifData({ detachEntityId: baseEntityId, detachCoord: entityCoord, programAddress: programAddress })
    );

    (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(entityCoord);

    (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);

    // If forcefield is active, call its hook
    bytes memory onDetachedCall = abi.encodeCall(IProgram.onDetached, (playerEntityId, baseEntityId, extraData));
    if (machineData.energy > 0) {
      if (forceFieldEntityId.exists() && ObjectType._get(baseEntityId) != ObjectTypes.ForceField) {
        bytes memory onProgramDetachedCall = abi.encodeCall(
          IForceFieldFragmentProgram.onProgramDetached,
          (playerEntityId, forceFieldEntityId, baseEntityId, extraData)
        );
        _callForceFieldProgram(forceFieldEntityId, fragmentEntityId, onProgramDetachedCall);
      }

      // Don't safe call here because we want to revert if the program doesn't allow the detachment
      callProgramOrRevert(programSystemId, onDetachedCall);
    } else {
      safeCallProgram(programSystemId, onDetachedCall);
    }
  }
}
