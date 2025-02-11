// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { ERC165Checker } from "@latticexyz/world/src/ERC165Checker.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Chip } from "../codegen/tables/Chip.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { PlayerObjectID, ChipObjectID, SmartChestObjectID, ForceFieldObjectID, SmartTextSignObjectID } from "../ObjectTypeIds.sol";
import { addToInventoryCount, removeFromInventoryCount } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { updateMachineEnergyLevel } from "../utils/MachineUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { safeCallChip } from "../Utils.sol";

import { IChip } from "../prototypes/IChip.sol";
import { IChestChip } from "../prototypes/IChestChip.sol";
import { IForceFieldChip } from "../prototypes/IForceFieldChip.sol";
import { IDisplayChip } from "../prototypes/IDisplayChip.sol";
import { EntityId } from "../EntityId.sol";

contract ChipSystem is System {
  function attachChipWithExtraData(EntityId entityId, address chipAddress, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    EntityId baseEntityId = entityId.baseEntityId();

    uint16 objectTypeId = ObjectType._get(baseEntityId);
    require(Chip._getChipAddress(baseEntityId) == address(0), "Chip already attached");
    require(chipAddress != address(0), "Invalid chip address");

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

    Chip._setChipAddress(baseEntityId, chipAddress);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.AttachChip,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: entityCoord.x,
        coordY: entityCoord.y,
        coordZ: entityCoord.z,
        amount: 1
      })
    );

    // Don't safe call here because we want to revert if the chip doesn't allow the attachment
    bool isAllowed = IChip(chipAddress).onAttached{ value: _msgValue() }(playerEntityId, baseEntityId, extraData);
    require(isAllowed, "Chip does not allow attachment");
  }

  function detachChipWithExtraData(EntityId entityId, bytes memory extraData) public payable {
    (EntityId playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    VoxelCoord memory entityCoord = requireInPlayerInfluence(playerCoord, entityId);
    EntityId baseEntityId = entityId.baseEntityId();

    address chipAddress = Chip._getChipAddress(baseEntityId);
    require(chipAddress != address(0), "No chip attached");

    uint16 objectTypeId = ObjectType._get(baseEntityId);
    EntityId forceFieldEntityId = getForceField(entityCoord);
    uint256 machineEnergyLevel = 0;
    if (forceFieldEntityId.exists()) {
      machineEnergyLevel = updateMachineEnergyLevel(forceFieldEntityId).energy;
    }

    addToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);

    Chip._setChipAddress(baseEntityId, address(0));

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.DetachChip,
        entityId: baseEntityId,
        objectTypeId: objectTypeId,
        coordX: entityCoord.x,
        coordY: entityCoord.y,
        coordZ: entityCoord.z,
        amount: 1
      })
    );

    if (machineEnergyLevel > 0) {
      // Don't safe call here because we want to revert if the chip doesn't allow the detachment
      bool isAllowed = IChip(chipAddress).onDetached{ value: _msgValue() }(playerEntityId, baseEntityId, extraData);
      require(isAllowed, "Detachment not allowed by chip");
    } else {
      safeCallChip(chipAddress, abi.encodeCall(IChip.onDetached, (playerEntityId, baseEntityId, extraData)));
    }
  }

  function attachChip(EntityId entityId, address chipAddress) public {
    attachChipWithExtraData(entityId, chipAddress, new bytes(0));
  }

  function detachChip(EntityId entityId) public {
    detachChipWithExtraData(entityId, new bytes(0));
  }
}
