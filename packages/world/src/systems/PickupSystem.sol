// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { AirObjectID, WaterObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { inWorldBorder, getTerrainObjectTypeId, getUniqueEntity } from "../Utils.sol";
import { transferInventoryNonTool, transferInventoryTool, transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { requireValidPlayer, requireInPlayerInfluence } from "../utils/PlayerUtils.sol";
import { mintXP } from "../utils/XPUtils.sol";

import { PickupData } from "../Types.sol";

contract PickupSystem is System {
  function pickupCommon(VoxelCoord memory coord) internal returns (bytes32, bytes32) {
    require(inWorldBorder(coord), "PickupSystem: cannot pickup outside world border");

    (bytes32 playerEntityId, VoxelCoord memory playerCoord) = requireValidPlayer(_msgSender());
    requireInPlayerInfluence(playerCoord, coord);

    bytes32 entityId = ReversePosition._get(coord.x, coord.y, coord.z);
    require(entityId != bytes32(0), "PickupSystem: no entity to pickup");

    uint8 objectTypeId = ObjectType._get(entityId);
    require(objectTypeId == AirObjectID, "PickupSystem: cannot pickup from non-air block");

    return (playerEntityId, entityId);
  }

  function pickupAll(VoxelCoord memory coord) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);
    uint256 numTransferred = transferAllInventoryEntities(entityId, playerEntityId, PlayerObjectID);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Pickup,
        entityId: entityId,
        objectTypeId: AirObjectID,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: numTransferred
      })
    );

    mintXP(playerEntityId, initialGas, 1);
  }

  function pickup(uint8 pickupObjectTypeId, uint16 numToPickup, VoxelCoord memory coord) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);
    transferInventoryNonTool(entityId, playerEntityId, PlayerObjectID, pickupObjectTypeId, numToPickup);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Pickup,
        entityId: entityId,
        objectTypeId: pickupObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: numToPickup
      })
    );

    mintXP(playerEntityId, initialGas, 1);
  }

  function pickupTool(bytes32 toolEntityId, VoxelCoord memory coord) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);
    uint8 toolObjectTypeId = transferInventoryTool(entityId, playerEntityId, PlayerObjectID, toolEntityId);

    PlayerActionNotif._set(
      playerEntityId,
      PlayerActionNotifData({
        actionType: ActionType.Pickup,
        entityId: entityId,
        objectTypeId: toolObjectTypeId,
        coordX: coord.x,
        coordY: coord.y,
        coordZ: coord.z,
        amount: 1
      })
    );

    mintXP(playerEntityId, initialGas, 1);
  }

  function pickupMultiple(
    PickupData[] memory pickupObjects,
    bytes32[] memory pickupTools,
    VoxelCoord memory coord
  ) public {
    uint256 initialGas = gasleft();

    (bytes32 playerEntityId, bytes32 entityId) = pickupCommon(coord);

    for (uint256 i = 0; i < pickupObjects.length; i++) {
      PickupData memory pickupObject = pickupObjects[i];
      transferInventoryNonTool(
        entityId,
        playerEntityId,
        PlayerObjectID,
        pickupObject.objectTypeId,
        pickupObject.numToPickup
      );

      PlayerActionNotif._set(
        playerEntityId,
        PlayerActionNotifData({
          actionType: ActionType.Pickup,
          entityId: entityId,
          objectTypeId: pickupObject.objectTypeId,
          coordX: coord.x,
          coordY: coord.y,
          coordZ: coord.z,
          amount: pickupObject.numToPickup
        })
      );
    }

    for (uint256 i = 0; i < pickupTools.length; i++) {
      uint8 toolObjectTypeId = transferInventoryTool(entityId, playerEntityId, PlayerObjectID, pickupTools[i]);

      PlayerActionNotif._set(
        playerEntityId,
        PlayerActionNotifData({
          actionType: ActionType.Pickup,
          entityId: entityId,
          objectTypeId: toolObjectTypeId,
          coordX: coord.x,
          coordY: coord.y,
          coordZ: coord.z,
          amount: 1
        })
      );
    }

    mintXP(playerEntityId, initialGas, 1);
  }
}
