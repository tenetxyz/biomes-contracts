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
import { Chip } from "../codegen/tables/Chip.sol";
import { ActionType } from "../codegen/common.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { updateMachineEnergy } from "../utils/EnergyUtils.sol";
import { getForceField, isForceFieldFragmentActive } from "../utils/ForceFieldUtils.sol";
import { notify, AttachChipNotifData, DetachChipNotifData } from "../utils/NotifUtils.sol";

import { IChip } from "../prototypes/IChip.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { IForceFieldFragmentChip } from "../prototypes/IForceFieldFragmentChip.sol";
import { IDisplayChip } from "../prototypes/IDisplayChip.sol";
import { ISpawnTileChip } from "../prototypes/ISpawnTileChip.sol";
import { IBedChip } from "../prototypes/IBedChip.sol";
import { EntityId } from "../EntityId.sol";
import { Vec3 } from "../Vec3.sol";
import { safeCallChip, callChipOrRevert } from "../utils/callChip.sol";

contract ChipSystem is System {
  using WorldResourceIdInstance for ResourceId;

  function _requireInterface(address chipAddress, bytes4 interfaceId) internal view {
    require(
      ERC165Checker.supportsInterface(chipAddress, interfaceId),
      "Chip does not implement the required interface"
    );
  }

  function _callForceFieldChip(EntityId forceFieldEntityId, EntityId fragmentEntityId, bytes memory data) internal {
    // We know fragment is active because its forcefield exists, so we can use its chip
    ResourceId fragmentChip = fragmentEntityId.getChip();
    if (fragmentChip.unwrap() != 0) {
      callChipOrRevert(fragmentChip, data);
    } else {
      callChipOrRevert(forceFieldEntityId.getChip(), data);
    }
  }

  function attachChip(EntityId entityId, ResourceId chipSystemId, bytes calldata extraData) public payable {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());

    EntityId baseEntityId = entityId.baseEntityId();
    ObjectTypeId objectTypeId = ObjectType._get(baseEntityId);

    require(baseEntityId.getChip().unwrap() == 0, "Chip already attached");

    Vec3 entityCoord;
    // ForceField fragments don't have a position on the grid, so we need to handle them differently
    if (objectTypeId == ObjectTypes.ForceFieldFragment) {
      // TODO: figure out proximity checks for fragments
      entityCoord = PlayerUtils.requireFragmentInPlayerInfluence(playerCoord, baseEntityId);
    } else {
      entityCoord = PlayerUtils.requireInPlayerInfluence(playerCoord, entityId);
    }

    (address chipAddress, bool publicAccess) = Systems._get(chipSystemId);
    require(!publicAccess, "Chip system must be private");

    if (objectTypeId == ObjectTypes.ForceField) {
      _requireInterface(chipAddress, type(IForceFieldChip).interfaceId);
    } else if (objectTypeId == ObjectTypes.ForceFieldFragment) {
      _requireInterface(chipAddress, type(IForceFieldFragmentChip).interfaceId);
    } else if (objectTypeId == ObjectTypes.SmartChest) {
      _requireInterface(chipAddress, type(IChestChip).interfaceId);
    } else if (objectTypeId == ObjectTypes.SmartTextSign) {
      _requireInterface(chipAddress, type(IDisplayChip).interfaceId);
    } else if (objectTypeId == ObjectTypes.SpawnTile) {
      _requireInterface(chipAddress, type(ISpawnTileChip).interfaceId);
    } else if (objectTypeId == ObjectTypes.Bed) {
      _requireInterface(chipAddress, type(IBedChip).interfaceId);
    } else {
      revert("Cannot attach a chip to this object");
    }

    notify(
      playerEntityId,
      AttachChipNotifData({ attachEntityId: baseEntityId, attachCoord: entityCoord, chipAddress: chipAddress })
    );

    // If forcefield is active, call its hook
    if (objectTypeId != ObjectTypes.ForceField) {
      (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(entityCoord);
      if (forceFieldEntityId.exists()) {
        (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);
        if (machineData.energy > 0) {
          bytes memory onChipAttachedCall = abi.encodeCall(
            IForceFieldFragmentChip.onChipAttached,
            (playerEntityId, forceFieldEntityId, baseEntityId, extraData)
          );

          _callForceFieldChip(forceFieldEntityId, fragmentEntityId, onChipAttachedCall);
        }
      }
    }

    // Chip needs to be set after calling the forcefield's hook,
    // otherwise if it is a fragment it would call itself
    Chip._setChipSystemId(baseEntityId, chipSystemId);

    bytes memory onAttachedCall = abi.encodeCall(IChip.onAttached, (playerEntityId, baseEntityId, extraData));
    callChipOrRevert(chipSystemId, onAttachedCall);
  }

  function detachChip(EntityId entityId, bytes calldata extraData) public payable {
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

    ResourceId chipSystemId = baseEntityId.getChip();

    require(chipSystemId.unwrap() != 0, "No chip attached");

    Chip._deleteRecord(baseEntityId);

    (address chipAddress, ) = Systems._get(chipSystemId);

    notify(
      playerEntityId,
      DetachChipNotifData({ detachEntityId: baseEntityId, detachCoord: entityCoord, chipAddress: chipAddress })
    );

    (EntityId forceFieldEntityId, EntityId fragmentEntityId) = getForceField(entityCoord);

    (EnergyData memory machineData, ) = updateMachineEnergy(forceFieldEntityId);

    // If forcefield is active, call its hook
    bytes memory onDetachedCall = abi.encodeCall(IChip.onDetached, (playerEntityId, baseEntityId, extraData));
    if (machineData.energy > 0) {
      if (forceFieldEntityId.exists() && ObjectType._get(baseEntityId) != ObjectTypes.ForceField) {
        bytes memory onChipDetachedCall = abi.encodeCall(
          IForceFieldFragmentChip.onChipDetached,
          (playerEntityId, forceFieldEntityId, baseEntityId, extraData)
        );
        _callForceFieldChip(forceFieldEntityId, fragmentEntityId, onChipDetachedCall);
      }

      // Don't safe call here because we want to revert if the chip doesn't allow the detachment
      callChipOrRevert(chipSystemId, onDetachedCall);
    } else {
      safeCallChip(chipSystemId, onDetachedCall);
    }
  }
}
