// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { ActionType } from "../codegen/common.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { ObjectType, AirObjectID, PlayerObjectID } from "../ObjectType.sol";
import { inWorldBorder } from "../Utils.sol";
import { transferInventoryNonEntity, transferInventoryEntity, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { notify, PickupNotifData } from "../utils/NotifUtils.sol";
import { PickupData } from "../Types.sol";
import { EntityId } from "../EntityId.sol";
import { PLAYER_PICKUP_ENERGY_COST } from "../Constants.sol";
import { transferEnergyToPool } from "../utils/EnergyUtils.sol";

contract PickupSystem is System {
  function pickupCommon(VoxelCoord memory coord) internal returns (EntityId, EntityId) {
    require(inWorldBorder(coord), "Cannot pickup outside the world border");

    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    EntityId entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId.exists(), "No entity at pickup location");

    ObjectType objectType = ObjectType._get(entityId);
    require(objectType == AirObjectID, "Cannot pickup from a non-air block");

    transferEnergyToPool(playerEntityId, playerCoord, PLAYER_PICKUP_ENERGY_COST);

    return (playerEntityId, entityId);
  }

  function pickupAll(VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    uint256 numTransferred = transferAllInventoryEntities(entityId, playerEntityId, PlayerObjectID);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectType: AirObjectID, pickupAmount: uint16(numTransferred) })
    );
  }

  function pickup(ObjectType pickupObjectType, uint16 numToPickup, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    transferInventoryNonEntity(entityId, playerEntityId, PlayerObjectID, pickupObjectType, numToPickup);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectType: pickupObjectType, pickupAmount: numToPickup })
    );
  }

  function pickupTool(EntityId toolEntityId, VoxelCoord memory coord) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);
    ObjectType toolObjectType = transferInventoryEntity(entityId, playerEntityId, PlayerObjectID, toolEntityId);

    notify(
      playerEntityId,
      PickupNotifData({ pickupCoord: coord, pickupObjectType: toolObjectType, pickupAmount: 1 })
    );
  }

  function pickupMultiple(
    PickupData[] memory pickupObjects,
    EntityId[] memory pickupTools,
    VoxelCoord memory coord
  ) public {
    (EntityId playerEntityId, EntityId entityId) = pickupCommon(coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      PickupData memory pickupObject = pickupObjects[i];
      transferInventoryNonEntity(
        entityId,
        playerEntityId,
        PlayerObjectID,
        pickupObject.objectType,
        pickupObject.numToPickup
      );

      notify(
        playerEntityId,
        PickupNotifData({
          pickupCoord: coord,
          pickupObjectType: pickupObject.objectType,
          pickupAmount: pickupObject.numToPickup
        })
      );
    }

    for (uint256 i = 0; i < pickupTools.length; i++) {
      ObjectType toolObjectType = transferInventoryEntity(entityId, playerEntityId, PlayerObjectID, pickupTools[i]);

      notify(
        playerEntityId,
        PickupNotifData({ pickupCoord: coord, pickupObjectType: toolObjectType, pickupAmount: 1 })
      );
    }
  }
}
