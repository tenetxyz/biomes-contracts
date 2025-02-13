// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID, ChipObjectID, SmartChestObjectID, ForceFieldObjectID, SmartTextSignObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { notify, AttachChipNotifData, DetachChipNotifData } from "../utils/NotifUtils.sol";

import { IChip } from "../prototypes/IChip.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { IDisplayChip } from "../prototypes/IDisplayChip.sol";
import { EntityId } from "../EntityId.sol";
import { safeCallChip, callChipOrRevert } from "../utils/callChip.sol";

contract ChipSystem is System {
  function attachChipWithExtraData(EntityId entityId, ResourceId chipSystemId, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    EntityId baseEntityId = entityId.baseEntityId();
    require(baseEntityId.getChipAddress() == address(0), "Chip already attached");

    uint16 objectTypeId = ObjectType._get(baseEntityId);
    require(chipSystemId.unwrap() != 0, "Invalid chip system id");

    // TODO: check that system exists
    address chipAddress = baseEntityId.getChipAddress();

    if (objectTypeId == ForceFieldObjectID) {
      require(
        ERC165Checker.supportsInterface(chipAddress, type(IForceFieldChip).interfaceId),
        "Chip does not implement the required interface"
      );
    } else if (objectTypeId == SmartChestObjectID) {
      require(
        ERC165Checker.supportsInterface(chipAddress, type(IChestChip).interfaceId),
        "Chip does not implement the required interface"
      );
    } else if (objectTypeId == SmartTextSignObjectID) {
      require(
        ERC165Checker.supportsInterface(chipAddress, type(IDisplayChip).interfaceId),
        "Chip does not implement the required interface"
      );
    } else {
      revert("Cannot attach a chip to this object");
    }

    removeFromInventoryCount(playerEntityId, ChipObjectID, 1);

    Chip._setChipSystemId(baseEntityId, chipSystemId);

    notify(
      playerEntityId,
      AttachChipNotifData({ attachEntityId: baseEntityId, attachCoord: entityCoord, chipAddress: chipAddress })
    );

    bytes memory onAttachedCall = abi.encodeCall(IChip.onAttached, (playerEntityId, baseEntityId, extraData));
    callChipOrRevert(baseEntityId.getChipAddress(), onAttachedCall);
  }

  function detachChipWithExtraData(EntityId entityId, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    EntityId baseEntityId = entityId.baseEntityId();

    EntityId forceFieldEntityId = getForceField(entityCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      machineEnergyLevel = updateMachineEnergyLevel(forceFieldEntityId).energy;
    }

    addToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);

    address chipAddress = baseEntityId.getChipAddress();

    Chip._deleteRecord(baseEntityId);

    notify(
      playerEntityId,
      DetachChipNotifData({ detachEntityId: baseEntityId, detachCoord: entityCoord, chipAddress: chipAddress })
    );

    bytes memory onDetachedCall = abi.encodeCall(IChip.onDetached, (playerEntityId, baseEntityId, extraData));
    if (machineEnergyLevel > 0) {
      // Don't safe call here because we want to revert if the chip doesn't allow the detachment
      callChipOrRevert(chipAddress, onDetachedCall);
    } else {
      safeCallChip(chipAddress, onDetachedCall);
    }
  }

  function attachChip(EntityId entityId, ResourceId chipSystemId) public {
    attachChipWithExtraData(entityId, chipSystemId, new bytes(0));
  }

  function detachChip(EntityId entityId) public {
    detachChipWithExtraData(entityId, new bytes(0));
  }
}
