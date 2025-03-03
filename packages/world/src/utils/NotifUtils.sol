// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { Vec3 } from "../Vec3.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeId } from "../ObjectTypeIds.sol";

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
  Vec3 transferCoord;
  ObjectTypeId transferObjectTypeId;
  uint16 transferAmount;
}

struct EquipNotifData {
  EntityId inventoryEntityId;
}

struct UnequipNotifData {
  EntityId inventoryEntityId;
}

struct SpawnNotifData {
  address playerAddress;
  Vec3 spawnCoord;
}

struct PowerMachineNotifData {
  EntityId machineEntityId;
  Vec3 machineCoord;
  uint16 numBattery;
}

struct HitMachineNotifData {
  EntityId machineEntityId;
  Vec3 machineCoord;
}

struct AttachChipNotifData {
  EntityId attachEntityId;
  Vec3 attachCoord;
  address chipAddress;
}

struct DetachChipNotifData {
  EntityId detachEntityId;
  Vec3 detachCoord;
  address chipAddress;
}

struct InitiateOreRevealNotifData {
  Vec3 oreCoord;
}

struct RevealOreNotifData {
  Vec3 oreCoord;
  ObjectTypeId oreObjectTypeId;
}

struct SleepNotifData {
  EntityId bedEntityId;
  Vec3 bedCoord;
}

struct WakeupNotifData {
  EntityId bedEntityId;
  Vec3 bedCoord;
}

function notify(EntityId playerEntityId, BuildNotifData memory buildNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Build, actionData: abi.encode(buildNotifData) })
  );
}

function notify(EntityId playerEntityId, MineNotifData memory mineNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Mine, actionData: abi.encode(mineNotifData) })
  );
}

function notify(EntityId playerEntityId, MoveNotifData memory moveNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Move, actionData: abi.encode(moveNotifData) })
  );
}

function notify(EntityId playerEntityId, CraftNotifData memory craftNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Craft, actionData: abi.encode(craftNotifData) })
  );
}

function notify(EntityId playerEntityId, DropNotifData memory dropNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Drop, actionData: abi.encode(dropNotifData) })
  );
}

function notify(EntityId playerEntityId, PickupNotifData memory pickupNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Pickup, actionData: abi.encode(pickupNotifData) })
  );
}

function notify(EntityId playerEntityId, TransferNotifData memory transferNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Transfer, actionData: abi.encode(transferNotifData) })
  );
}

function notify(EntityId playerEntityId, EquipNotifData memory equipNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Equip, actionData: abi.encode(equipNotifData) })
  );
}

function notify(EntityId playerEntityId, UnequipNotifData memory unequipNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Unequip, actionData: abi.encode(unequipNotifData) })
  );
}

function notify(EntityId playerEntityId, SpawnNotifData memory spawnNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Spawn, actionData: abi.encode(spawnNotifData) })
  );
}

function notify(EntityId playerEntityId, PowerMachineNotifData memory powerMachineNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.PowerMachine, actionData: abi.encode(powerMachineNotifData) })
  );
}

function notify(EntityId playerEntityId, HitMachineNotifData memory hitMachineNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.HitMachine, actionData: abi.encode(hitMachineNotifData) })
  );
}

function notify(EntityId playerEntityId, AttachChipNotifData memory attachChipNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.AttachChip, actionData: abi.encode(attachChipNotifData) })
  );
}

function notify(EntityId playerEntityId, DetachChipNotifData memory detachChipNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.DetachChip, actionData: abi.encode(detachChipNotifData) })
  );
}

function notify(EntityId playerEntityId, InitiateOreRevealNotifData memory initiateOreRevealNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({
      actionType: ActionType.InitiateOreReveal,
      actionData: abi.encode(initiateOreRevealNotifData)
    })
  );
}

function notify(EntityId playerEntityId, RevealOreNotifData memory revealOreNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.RevealOre, actionData: abi.encode(revealOreNotifData) })
  );
}

function notify(EntityId playerEntityId, SleepNotifData memory sleepNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Sleep, actionData: abi.encode(sleepNotifData) })
  );
}

function notify(EntityId playerEntityId, WakeupNotifData memory wakeupNotifData) {
  PlayerActionNotif._set(
    playerEntityId,
    PlayerActionNotifData({ actionType: ActionType.Wakeup, actionData: abi.encode(wakeupNotifData) })
  );
}
