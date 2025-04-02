// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { ActionType } from "../codegen/common.sol";
import { Notification, NotificationData } from "../codegen/tables/Notification.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { Vec3 } from "../Vec3.sol";

struct BuildNotifData {
  EntityId buildEntityId;
  Vec3 buildCoord;
  ObjectTypeId buildObjectTypeId;
}

struct MineNotifData {
  EntityId mineEntityId;
  Vec3 mineCoord;
  ObjectTypeId mineObjectTypeId;
}

struct MoveNotifData {
  Vec3[] moveCoords;
}

struct CraftNotifData {
  bytes32 recipeId;
  EntityId station;
}

struct DropNotifData {
  Vec3 dropCoord;
  ObjectTypeId dropObjectTypeId;
  uint16 dropAmount;
}

struct PickupNotifData {
  Vec3 pickupCoord;
  ObjectTypeId pickupObjectTypeId;
  uint16 pickupAmount;
}

struct TransferNotifData {
  EntityId transferEntityId;
  EntityId[] tools;
  ObjectAmount[] objectAmounts;
}

struct EquipNotifData {
  EntityId inventoryEntityId;
}

struct UnequipNotifData {
  EntityId inventoryEntityId;
}

struct SpawnNotifData {
  Vec3 spawnCoord;
}

struct PowerMachineNotifData {
  EntityId machine;
  Vec3 machineCoord;
  uint16 fuelAmount;
}

struct HitMachineNotifData {
  EntityId machine;
  Vec3 machineCoord;
}

struct AttachProgramNotifData {
  EntityId attachedTo;
  ResourceId programSystemId;
}

struct DetachProgramNotifData {
  EntityId detachedFrom;
  ResourceId programSystemId;
}

struct SleepNotifData {
  EntityId bed;
  Vec3 bedCoord;
}

struct WakeupNotifData {
  EntityId bed;
  Vec3 bedCoord;
}

struct AddFragmentNotifData {
  EntityId forceField;
}

struct RemoveFragmentNotifData {
  EntityId forceField;
}

struct DeathNotifData {
  Vec3 deathCoord;
}

function notify(EntityId player, BuildNotifData memory buildNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Build,
      actionData: abi.encode(buildNotifData)
    })
  );
}

function notify(EntityId player, MineNotifData memory mineNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Mine,
      actionData: abi.encode(mineNotifData)
    })
  );
}

function notify(EntityId player, MoveNotifData memory moveNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Move,
      actionData: abi.encode(moveNotifData)
    })
  );
}

function notify(EntityId player, CraftNotifData memory craftNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Craft,
      actionData: abi.encode(craftNotifData)
    })
  );
}

function notify(EntityId player, DropNotifData memory dropNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Drop,
      actionData: abi.encode(dropNotifData)
    })
  );
}

function notify(EntityId player, PickupNotifData memory pickupNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Pickup,
      actionData: abi.encode(pickupNotifData)
    })
  );
}

function notify(EntityId player, TransferNotifData memory transferNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Transfer,
      actionData: abi.encode(transferNotifData)
    })
  );
}

function notify(EntityId player, EquipNotifData memory equipNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Equip,
      actionData: abi.encode(equipNotifData)
    })
  );
}

function notify(EntityId player, UnequipNotifData memory unequipNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Unequip,
      actionData: abi.encode(unequipNotifData)
    })
  );
}

function notify(EntityId player, SpawnNotifData memory spawnNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Spawn,
      actionData: abi.encode(spawnNotifData)
    })
  );
}

function notify(EntityId player, PowerMachineNotifData memory powerMachineNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.PowerMachine,
      actionData: abi.encode(powerMachineNotifData)
    })
  );
}

function notify(EntityId player, HitMachineNotifData memory hitMachineNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.HitMachine,
      actionData: abi.encode(hitMachineNotifData)
    })
  );
}

function notify(EntityId player, AttachProgramNotifData memory attachProgramNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.AttachProgram,
      actionData: abi.encode(attachProgramNotifData)
    })
  );
}

function notify(EntityId player, DetachProgramNotifData memory detachProgramNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.DetachProgram,
      actionData: abi.encode(detachProgramNotifData)
    })
  );
}

function notify(EntityId player, SleepNotifData memory sleepNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Sleep,
      actionData: abi.encode(sleepNotifData)
    })
  );
}

function notify(EntityId player, WakeupNotifData memory wakeupNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Wakeup,
      actionData: abi.encode(wakeupNotifData)
    })
  );
}

function notify(EntityId player, AddFragmentNotifData memory addFragmentNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.AddFragment,
      actionData: abi.encode(addFragmentNotifData)
    })
  );
}

function notify(EntityId player, RemoveFragmentNotifData memory removeFragmentNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.RemoveFragment,
      actionData: abi.encode(removeFragmentNotifData)
    })
  );
}

function notify(EntityId player, DeathNotifData memory deathNotifData) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Death,
      actionData: abi.encode(deathNotifData)
    })
  );
}
