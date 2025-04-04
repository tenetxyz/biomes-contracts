// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { Action } from "../codegen/common.sol";
import { Notification, NotificationData } from "../codegen/tables/Notification.sol";

import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";
import { Vec3 } from "../Vec3.sol";

struct BuildNotification {
  EntityId buildEntityId;
  Vec3 buildCoord;
  ObjectTypeId buildObjectTypeId;
}

struct MineNotification {
  EntityId mineEntityId;
  Vec3 mineCoord;
  ObjectTypeId mineObjectTypeId;
}

struct MoveNotification {
  Vec3[] moveCoords;
}

struct CraftNotification {
  bytes32 recipeId;
  EntityId station;
}

struct DropNotification {
  Vec3 dropCoord;
  ObjectTypeId dropObjectTypeId;
  uint16 dropAmount;
}

struct PickupNotification {
  Vec3 pickupCoord;
  ObjectTypeId pickupObjectTypeId;
  uint16 pickupAmount;
}

struct TransferNotification {
  EntityId transferEntityId;
  EntityId[] tools;
  ObjectAmount[] objectAmounts;
}

struct EquipNotification {
  EntityId inventoryEntityId;
}

struct UnequipNotification {
  EntityId inventoryEntityId;
}

struct SpawnNotification {
  Vec3 spawnCoord;
}

struct FuelMachineNotification {
  EntityId machine;
  Vec3 machineCoord;
  uint16 fuelAmount;
}

struct HitMachineNotification {
  EntityId machine;
  Vec3 machineCoord;
}

struct AttachProgramNotification {
  EntityId attachedTo;
  ResourceId programSystemId;
}

struct DetachProgramNotification {
  EntityId detachedFrom;
  ResourceId programSystemId;
}

struct SleepNotification {
  EntityId bed;
  Vec3 bedCoord;
}

struct WakeupNotification {
  EntityId bed;
  Vec3 bedCoord;
}

struct AddFragmentNotification {
  EntityId forceField;
}

struct RemoveFragmentNotification {
  EntityId forceField;
}

struct DeathNotification {
  Vec3 deathCoord;
}

function notify(EntityId player, BuildNotification memory buildNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Build, data: abi.encode(buildNotification) })
  );
}

function notify(EntityId player, MineNotification memory mineNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Mine, data: abi.encode(mineNotification) })
  );
}

function notify(EntityId player, MoveNotification memory moveNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Move, data: abi.encode(moveNotification) })
  );
}

function notify(EntityId player, CraftNotification memory craftNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Craft, data: abi.encode(craftNotification) })
  );
}

function notify(EntityId player, DropNotification memory dropNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Drop, data: abi.encode(dropNotification) })
  );
}

function notify(EntityId player, PickupNotification memory pickupNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Pickup, data: abi.encode(pickupNotification) })
  );
}

function notify(EntityId player, TransferNotification memory transferNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.Transfer,
      data: abi.encode(transferNotification)
    })
  );
}

function notify(EntityId player, SpawnNotification memory spawnNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Spawn, data: abi.encode(spawnNotification) })
  );
}

function notify(EntityId player, FuelMachineNotification memory powerMachineNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.FuelMachine,
      data: abi.encode(powerMachineNotification)
    })
  );
}

function notify(EntityId player, HitMachineNotification memory hitMachineNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.HitMachine,
      data: abi.encode(hitMachineNotification)
    })
  );
}

function notify(EntityId player, AttachProgramNotification memory attachProgramNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.AttachProgram,
      data: abi.encode(attachProgramNotification)
    })
  );
}

function notify(EntityId player, DetachProgramNotification memory detachProgramNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.DetachProgram,
      data: abi.encode(detachProgramNotification)
    })
  );
}

function notify(EntityId player, SleepNotification memory sleepNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Sleep, data: abi.encode(sleepNotification) })
  );
}

function notify(EntityId player, WakeupNotification memory wakeupNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Wakeup, data: abi.encode(wakeupNotification) })
  );
}

function notify(EntityId player, AddFragmentNotification memory addFragmentNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.AddFragment,
      data: abi.encode(addFragmentNotification)
    })
  );
}

function notify(EntityId player, RemoveFragmentNotification memory removeFragmentNotification) {
  Notification._set(
    player,
    NotificationData({
      timestamp: uint128(block.timestamp),
      action: Action.RemoveFragment,
      data: abi.encode(removeFragmentNotification)
    })
  );
}

function notify(EntityId player, DeathNotification memory deathNotification) {
  Notification._set(
    player,
    NotificationData({ timestamp: uint128(block.timestamp), action: Action.Death, data: abi.encode(deathNotification) })
  );
}
