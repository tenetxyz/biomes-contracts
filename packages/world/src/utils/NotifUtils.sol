// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { ActionNotif, ActionNotifData } from "../codegen/tables/ActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { Vec3 } from "../Vec3.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectAmount } from "../ObjectTypeLib.sol";

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
  EntityId stationEntityId;
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
  EntityId[] toolEntityIds;
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
  EntityId machineEntityId;
  Vec3 machineCoord;
  uint16 fuelAmount;
}

struct HitMachineNotifData {
  EntityId machineEntityId;
  Vec3 machineCoord;
}

struct AttachProgramNotifData {
  EntityId attachEntityId;
  ResourceId programSystemId;
}

struct DetachProgramNotifData {
  EntityId detachEntityId;
  ResourceId programSystemId;
}

struct SleepNotifData {
  EntityId bedEntityId;
  Vec3 bedCoord;
}

struct WakeupNotifData {
  EntityId bedEntityId;
  Vec3 bedCoord;
}

struct ExpandForceFieldNotifData {
  EntityId forceFieldEntityId;
}

struct ContractForceFieldNotifData {
  EntityId forceFieldEntityId;
}

struct DeathNotifData {
  Vec3 deathCoord;
}

function notify(EntityId playerEntityId, BuildNotifData memory buildNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Build,
      actionData: abi.encode(buildNotifData)
    })
  );
}

function notify(EntityId playerEntityId, MineNotifData memory mineNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Mine,
      actionData: abi.encode(mineNotifData)
    })
  );
}

function notify(EntityId playerEntityId, MoveNotifData memory moveNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Move,
      actionData: abi.encode(moveNotifData)
    })
  );
}

function notify(EntityId playerEntityId, CraftNotifData memory craftNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Craft,
      actionData: abi.encode(craftNotifData)
    })
  );
}

function notify(EntityId playerEntityId, DropNotifData memory dropNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Drop,
      actionData: abi.encode(dropNotifData)
    })
  );
}

function notify(EntityId playerEntityId, PickupNotifData memory pickupNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Pickup,
      actionData: abi.encode(pickupNotifData)
    })
  );
}

function notify(EntityId playerEntityId, TransferNotifData memory transferNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Transfer,
      actionData: abi.encode(transferNotifData)
    })
  );
}

function notify(EntityId playerEntityId, EquipNotifData memory equipNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Equip,
      actionData: abi.encode(equipNotifData)
    })
  );
}

function notify(EntityId playerEntityId, UnequipNotifData memory unequipNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Unequip,
      actionData: abi.encode(unequipNotifData)
    })
  );
}

function notify(EntityId playerEntityId, SpawnNotifData memory spawnNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Spawn,
      actionData: abi.encode(spawnNotifData)
    })
  );
}

function notify(EntityId playerEntityId, PowerMachineNotifData memory powerMachineNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.PowerMachine,
      actionData: abi.encode(powerMachineNotifData)
    })
  );
}

function notify(EntityId playerEntityId, HitMachineNotifData memory hitMachineNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.HitMachine,
      actionData: abi.encode(hitMachineNotifData)
    })
  );
}

function notify(EntityId playerEntityId, AttachProgramNotifData memory attachProgramNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.AttachProgram,
      actionData: abi.encode(attachProgramNotifData)
    })
  );
}

function notify(EntityId playerEntityId, DetachProgramNotifData memory detachProgramNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.DetachProgram,
      actionData: abi.encode(detachProgramNotifData)
    })
  );
}

function notify(EntityId playerEntityId, SleepNotifData memory sleepNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Sleep,
      actionData: abi.encode(sleepNotifData)
    })
  );
}

function notify(EntityId playerEntityId, WakeupNotifData memory wakeupNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Wakeup,
      actionData: abi.encode(wakeupNotifData)
    })
  );
}

function notify(EntityId playerEntityId, ExpandForceFieldNotifData memory expandForceFieldNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.ExpandForceField,
      actionData: abi.encode(expandForceFieldNotifData)
    })
  );
}

function notify(EntityId playerEntityId, ContractForceFieldNotifData memory contractForceFieldNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.ContractForceField,
      actionData: abi.encode(contractForceFieldNotifData)
    })
  );
}

function notify(EntityId playerEntityId, DeathNotifData memory deathNotifData) {
  ActionNotif._set(
    playerEntityId,
    ActionNotifData({
      timestamp: uint128(block.timestamp),
      actionType: ActionType.Death,
      actionData: abi.encode(deathNotifData)
    })
  );
}
