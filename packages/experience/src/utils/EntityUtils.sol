// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

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
import { PlayerMetadata } from "@biomesaw/world/src/codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "@biomesaw/world/src/codegen/tables/ObjectType.sol";
import { Position } from "@biomesaw/world/src/codegen/tables/Position.sol";
import { ReversePosition } from "@biomesaw/world/src/codegen/tables/ReversePosition.sol";
import { Equipped } from "@biomesaw/world/src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "@biomesaw/world/src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "@biomesaw/world/src/codegen/tables/Stamina.sol";
import { InventoryObjects } from "@biomesaw/world/src/codegen/tables/InventoryObjects.sol";
import { InventoryTool } from "@biomesaw/world/src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "@biomesaw/world/src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "@biomesaw/world/src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "@biomesaw/world/src/codegen/tables/InventoryCount.sol";
import { Equipped } from "@biomesaw/world/src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "@biomesaw/world/src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "@biomesaw/world/src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
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

function getObjectTypeAtCoord(address biomeWorldAddress, VoxelCoord memory coord) view returns (uint8) {
  bytes32 entityId = getEntityAtCoord(coord);

  uint8 objectTypeId;
  if (entityId == bytes32(0)) {
    objectTypeId = IWorld(biomeWorldAddress).getTerrainBlock(coord);
  } else {
    objectTypeId = getObjectType(entityId);
  }

  return objectTypeId;
}

function getPosition(bytes32 entityId) view returns (VoxelCoord memory) {
  return positionDataToVoxelCoord(Position.get(entityId));
}

function getObjectType(bytes32 entityId) view returns (uint8) {
  return ObjectType.get(entityId);
}

function getMiningDifficulty(uint8 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getMiningDifficulty(objectTypeId);
}

function getStackable(uint8 objectTypeId) view returns (uint8) {
  return ObjectTypeMetadata.getStackable(objectTypeId);
}

function getDamage(uint8 objectTypeId) view returns (uint16) {
  return ObjectTypeMetadata.getDamage(objectTypeId);
}

function getDurability(uint8 objectTypeId) view returns (uint24) {
  return ObjectTypeMetadata.getDurability(objectTypeId);
}

function isTool(uint8 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getIsTool(objectTypeId);
}

function isBlock(uint8 objectTypeId) view returns (bool) {
  return ObjectTypeMetadata.getIsBlock(objectTypeId);
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

function getHealth(bytes32 playerEntityId) view returns (uint16) {
  return Health.getHealth(playerEntityId);
}

function getStamina(bytes32 playerEntityId) view returns (uint32) {
  return Stamina.getStamina(playerEntityId);
}

function getIsLoggedOff(bytes32 playerEntityId) view returns (bool) {
  return PlayerMetadata.getIsLoggedOff(playerEntityId);
}

function getLastHitTime(bytes32 playerEntityId) view returns (uint256) {
  return PlayerMetadata.getLastHitTime(playerEntityId);
}

function getInventoryTool(bytes32 playerEntityId) view returns (bytes32[] memory) {
  return ReverseInventoryTool.getToolEntityIds(playerEntityId);
}

function getInventoryObjects(bytes32 playerEntityId) view returns (uint8[] memory) {
  return InventoryObjects.getObjectTypeIds(playerEntityId);
}

function getCount(bytes32 playerEntityId, uint8 objectTypeId) view returns (uint16) {
  return InventoryCount.getCount(playerEntityId, objectTypeId);
}

function getNumSlotsUsed(bytes32 playerEntityId) view returns (uint16) {
  return InventorySlots.getNumSlotsUsed(playerEntityId);
}

function getNumUsesLeft(bytes32 toolEntityId) view returns (uint24) {
  return ItemMetadata.getNumUsesLeft(toolEntityId);
}

function getEntityAtCoord(VoxelCoord memory coord) view returns (bytes32) {
  return ReversePosition.getEntityId(coord.x, coord.y, coord.z);
}
