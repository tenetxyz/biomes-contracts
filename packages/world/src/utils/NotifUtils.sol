// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { ActionType } from "../codegen/common.sol";

import { VoxelCoord } from "../Types.sol";
import { EntityId } from "../EntityId.sol";

struct BuildNotifData {
  EntityId buildEntityId;
  VoxelCoord buildCoord;
  uint16 buildObjectTypeId;
}

struct MineNotifData {
  EntityId mineEntityId;
  VoxelCoord mineCoord;
  uint16 mineObjectTypeId;
}

struct MoveNotifData {
  VoxelCoord[] moveCoords;
}

struct CraftNotifData {
  bytes32 recipeId;
  EntityId stationEntityId;
}

struct DropNotifData {
  VoxelCoord dropCoord;
  uint16 dropObjectTypeId;
  uint16 dropAmount;
}

struct PickupNotifData {
  VoxelCoord pickupCoord;
  uint16 pickupObjectTypeId;
  uint16 pickupAmount;
}

struct TransferNotifData {
  EntityId transferEntityId;
  VoxelCoord transferCoord;
  uint16 transferObjectTypeId;
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
  VoxelCoord spawnCoord;
}

struct LoginNotifData {
  VoxelCoord loginCoord;
}

struct LogoffNotifData {
  VoxelCoord logoffCoord;
}

struct PowerMachineNotifData {
  EntityId machineEntityId;
  VoxelCoord machineCoord;
  uint16 numBattery;
}

struct HitMachineNotifData {
  EntityId machineEntityId;
  VoxelCoord machineCoord;
}

struct AttachChipNotifData {
  EntityId attachEntityId;
  VoxelCoord attachCoord;
  address chipAddress;
}

struct DetachChipNotifData {
  EntityId detachEntityId;
  VoxelCoord detachCoord;
  address chipAddress;
}

struct InitiateOreRevealNotifData {
  VoxelCoord oreCoord;
}

struct RevealOreNotifData {
  VoxelCoord oreCoord;
  uint16 oreObjectTypeId;
}

function notify(EntityId playerEntityId, BuildNotifData memory buildNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Build, actionData: abi.encode(buildNotifData) })
  );
}

function notify(EntityId playerEntityId, MineNotifData memory mineNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Mine, actionData: abi.encode(mineNotifData) })
  );
}

function notify(EntityId playerEntityId, MoveNotifData memory moveNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Move, actionData: abi.encode(moveNotifData) })
  );
}

function notify(EntityId playerEntityId, CraftNotifData memory craftNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Craft, actionData: abi.encode(craftNotifData) })
  );
}

function notify(EntityId playerEntityId, DropNotifData memory dropNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Drop, actionData: abi.encode(dropNotifData) })
  );
}

function notify(EntityId playerEntityId, PickupNotifData memory pickupNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Pickup, actionData: abi.encode(pickupNotifData) })
  );
}

function notify(EntityId playerEntityId, TransferNotifData memory transferNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Transfer, actionData: abi.encode(transferNotifData) })
  );
}

function notify(EntityId playerEntityId, EquipNotifData memory equipNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Equip, actionData: abi.encode(equipNotifData) })
  );
}

function notify(EntityId playerEntityId, UnequipNotifData memory unequipNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Unequip, actionData: abi.encode(unequipNotifData) })
  );
}

function notify(EntityId playerEntityId, SpawnNotifData memory spawnNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Spawn, actionData: abi.encode(spawnNotifData) })
  );
}

function notify(EntityId playerEntityId, LoginNotifData memory loginNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Login, actionData: abi.encode(loginNotifData) })
  );
}

function notify(EntityId playerEntityId, LogoffNotifData memory logoffNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.Logoff, actionData: abi.encode(logoffNotifData) })
  );
}

function notify(EntityId playerEntityId, PowerMachineNotifData memory powerMachineNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.PowerMachine, actionData: abi.encode(powerMachineNotifData) })
  );
}

function notify(EntityId playerEntityId, HitMachineNotifData memory hitMachineNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.HitMachine, actionData: abi.encode(hitMachineNotifData) })
  );
}

function notify(EntityId playerEntityId, AttachChipNotifData memory attachChipNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.AttachChip, actionData: abi.encode(attachChipNotifData) })
  );
}

function notify(EntityId playerEntityId, DetachChipNotifData memory detachChipNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.DetachChip, actionData: abi.encode(detachChipNotifData) })
  );
}

function notify(EntityId playerEntityId, InitiateOreRevealNotifData memory initiateOreRevealNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({
      actionType: ActionType.InitiateOreReveal,
      actionData: abi.encode(initiateOreRevealNotifData)
    })
  );
}

function notify(EntityId playerEntityId, RevealOreNotifData memory revealOreNotifData) {
  PlayerActionNotif._set(
    playerEntityId.baseEntityId(),
    PlayerActionNotifData({ actionType: ActionType.RevealOre, actionData: abi.encode(revealOreNotifData) })
  );
}
