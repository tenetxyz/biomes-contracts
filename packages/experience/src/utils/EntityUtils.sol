// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
import { OptionalSystemHooks } from "@latticexyz/world/src/codegen/tables/OptionalSystemHooks.sol";
import { UserDelegationControl } from "@latticexyz/world/src/codegen/tables/UserDelegationControl.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";
import { BEFORE_CALL_SYSTEM, AFTER_CALL_SYSTEM, ALL } from "@latticexyz/world/src/systemHookTypes.sol";
import { Hook } from "@latticexyz/store/src/Hook.sol";
import { Delegation } from "@latticexyz/world/src/Delegation.sol";

import { IWorld } from "@biomesaw/world/src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "@biomesaw/world/src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "@biomesaw/world/src/codegen/tables/Player.sol";
import { ReversePlayer } from "@biomesaw/world/src/codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "@biomesaw/world/src/codegen/tables/PlayerStatus.sol";
import { ObjectType } from "@biomesaw/world/src/codegen/tables/ObjectType.sol";
import { Position } from "@biomesaw/world/src/codegen/tables/Position.sol";
import { ReversePosition } from "@biomesaw/world/src/codegen/tables/ReversePosition.sol";
import { Equipped } from "@biomesaw/world/src/codegen/tables/Equipped.sol";
import { InventoryObjects } from "@biomesaw/world/src/codegen/tables/InventoryObjects.sol";
import { InventoryTool } from "@biomesaw/world/src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "@biomesaw/world/src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "@biomesaw/world/src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "@biomesaw/world/src/codegen/tables/InventoryCount.sol";
import { ObjectCategory } from "@biomesaw/world/src/codegen/tables/ObjectTypeMetadata.sol";

import { ChestObjectID } from "@biomesaw/world/src/ObjectTypeIds.sol";
import { VoxelCoord } from "@biomesaw/world/src/Types.sol";
import { positionDataToVoxelCoord } from "@biomesaw/world/src/Utils.sol";

function hasBeforeAndAfterSystemHook(address hookAddress, address player, ResourceId systemId) view returns (bool) {
  bytes21[] memory playerSystemHooks = OptionalSystemHooks.getHooks(player, systemId, bytes32(0));
  for (uint i = 0; i < playerSystemHooks.length; i++) {
    Hook hook = Hook.wrap(playerSystemHooks[i]);
    if (hook.getAddress() == hookAddress && hook.getBitmap() == ALL) {
      return true;
    }
  }
  return false;
}

function hasDelegated(address delegator, address delegatee) view returns (bool) {
  return Delegation.isUnlimited(UserDelegationControl.getDelegationControlId(delegator, delegatee));
}

function getObjectTypeAtCoord(VoxelCoord memory coord) view returns (uint16) {
  bytes32 entityId = getEntityAtCoord(coord);

  uint16 objectTypeId = getObjectType(entityId);

  return objectTypeId;
}

function getPosition(bytes32 entityId) view returns (VoxelCoord memory) {
  return positionDataToVoxelCoord(Position.get(entityId));
}

function getObjectType(bytes32 entityId) view returns (uint16) {
  return ObjectType.get(entityId);
}

function getStackable(uint16 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getStackable(objectTypeId);
}

function isTool(uint16 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getObjectCategory(objectTypeId) == ObjectCategory.Tool;
}

function isBlock(uint16 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getObjectCategory(objectTypeId) == ObjectCategory.Block;
}

function getEntityFromPlayer(address playerAddress) view returns (bytes32) {
  return Player.getEntityId(playerAddress);
}

function getPlayerFromEntity(bytes32 entityId) view returns (address) {
  return ReversePlayer.getPlayer(entityId);
}

function getEquipped(bytes32 playerEntityId) view returns (bytes32) {
  return Equipped.get(playerEntityId);
}

function getIsLoggedOff(bytes32 playerEntityId) view returns (bool) {
  return PlayerStatus.getIsLoggedOff(playerEntityId);
}

function getInventoryTool(bytes32 playerEntityId) view returns (bytes32[] memory) {
  return ReverseInventoryTool.getToolEntityIds(playerEntityId);
}

function getInventoryObjects(bytes32 entityId) view returns (uint16[] memory) {
  return InventoryObjects.getObjectTypeIds(entityId);
}

function getNumInventoryObjects(bytes32 entityId) view returns (uint256) {
  return InventoryObjects.lengthObjectTypeIds(entityId);
}

function getCount(bytes32 entityId, uint16 objectTypeId) view returns (uint16) {
  return InventoryCount.getCount(entityId, objectTypeId);
}

function getNumSlotsUsed(bytes32 entityId) view returns (uint16) {
  return InventorySlots.getNumSlotsUsed(entityId);
}

function getEntityAtCoord(VoxelCoord memory coord) view returns (bytes32) {
  return ReversePosition.getEntityId(coord.x, coord.y, coord.z);
}

function numMaxInChest(uint16 objectTypeId) view returns (uint16) {
  return getStackable(objectTypeId) * ObjectTypeMetadata.getMaxInventorySlots(ChestObjectID);
}
