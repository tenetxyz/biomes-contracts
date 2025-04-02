// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { Machine } from "../codegen/tables/Machine.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { Position } from "../utils/Vec3Storage.sol";

import { PlayerUtils } from "../utils/PlayerUtils.sol";
import { PLAYER_ENERGY_DRAIN_RATE, MAX_RESPAWN_HALF_WIDTH } from "../Constants.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { notify, SleepNotifData, WakeupNotifData } from "../utils/NotifUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { updateMachineEnergy, updateSleepingPlayerEnergy } from "../utils/EnergyUtils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";

import { Vec3 } from "../Vec3.sol";
import { EntityId } from "../EntityId.sol";
import { ProgramId } from "../ProgramId.sol";
import { IWakeupHook, ISleepHook } from "../ProgramInterfaces.sol";

// To avoid reaching bytecode size limit
library BedLib {
  function transferInventory(EntityId playerEntityId, EntityId bedEntityId, ObjectTypeId objectTypeId) public {
    transferAllInventoryEntities(playerEntityId, bedEntityId, objectTypeId);
  }

  function updateSleepingPlayer(
    EntityId forceFieldEntityId,
    EntityId playerEntityId,
    EntityId bedEntityId,
    Vec3 bedCoord
  ) public returns (EnergyData memory) {
    uint128 depletedTime;
    (, depletedTime) = updateMachineEnergy(forceFieldEntityId);
    return updateSleepingPlayerEnergy(playerEntityId, bedEntityId, depletedTime, bedCoord);
  }
}

contract BedSystem is System {
  function removeDeadPlayerFromBed(EntityId playerEntityId, Vec3 dropCoord) public {
    checkWorldStatus();

    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not in a bed");

    Vec3 bedCoord = Position._get(bedEntityId);

    // TODO: use a different constant?
    require(bedCoord.inSurroundingCube(dropCoord, MAX_RESPAWN_HALF_WIDTH), "Drop location is too far from bed");

    (EntityId dropEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(dropCoord);
    require(ObjectTypeMetadata.getCanPassThrough(objectTypeId), "Cannot drop items on a non-passable block");

    (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
    EnergyData memory playerData = BedLib.updateSleepingPlayer(
      forceFieldEntityId,
      playerEntityId,
      bedEntityId,
      bedCoord
    );

    require(playerData.energy == 0, "Player is not dead");

    PlayerUtils.removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    BedLib.transferInventory(bedEntityId, dropEntityId, objectTypeId);
    // TODO: Should we safecall the program?
  }

  function sleep(EntityId callerEntityId, EntityId bedEntityId, bytes calldata extraData) public {
    callerEntityId.activate();

    (Vec3 callerCoord, Vec3 bedCoord) = callerEntityId.requireConnected(bedEntityId);

    require(ObjectType._get(bedEntityId) == ObjectTypes.Bed, "Not a bed");

    bedEntityId = bedEntityId.baseEntityId();
    require(!BedPlayer._getPlayerEntityId(bedEntityId).exists(), "Bed full");

    (EntityId forceFieldEntityId, ) = getForceField(Position._get(bedEntityId));
    require(forceFieldEntityId.exists(), "Bed is not inside a forcefield");
    (EnergyData memory machineData, uint128 depletedTime) = updateMachineEnergy(forceFieldEntityId);

    PlayerStatus._setBedEntityId(callerEntityId, bedEntityId);
    BedPlayer._set(bedEntityId, callerEntityId, depletedTime);

    // Increase forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + PLAYER_ENERGY_DRAIN_RATE);

    BedLib.transferInventory(callerEntityId, bedEntityId, ObjectTypes.Bed);

    PlayerUtils.removePlayerFromGrid(callerEntityId, callerCoord);

    bytes memory onSleep = abi.encodeCall(ISleepHook.onSleep, (callerEntityId, bedEntityId, extraData));
    bedEntityId.getProgram().callOrRevert(onSleep);

    notify(callerEntityId, SleepNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));
  }

  // TODO: for now this only supports players, as players are the only entities that can sleep
  function wakeup(EntityId callerEntityId, Vec3 spawnCoord, bytes calldata extraData) public {
    checkWorldStatus();

    callerEntityId.requireCallerAllowed(_msgSender());

    EntityId bedEntityId = PlayerStatus._getBedEntityId(callerEntityId);
    require(bedEntityId.exists(), "Player is not sleeping");

    Vec3 bedCoord = Position._get(bedEntityId);
    require(bedCoord.inSurroundingCube(spawnCoord, MAX_RESPAWN_HALF_WIDTH), "Bed is too far away");

    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
    EnergyData memory playerData = BedLib.updateSleepingPlayer(
      forceFieldEntityId,
      callerEntityId,
      bedEntityId,
      bedCoord
    );

    require(playerData.energy > 0, "Player died while sleeping");

    PlayerUtils.removePlayerFromBed(callerEntityId, bedEntityId, forceFieldEntityId);
    PlayerUtils.addPlayerToGrid(callerEntityId, spawnCoord);

    BedLib.transferInventory(bedEntityId, callerEntityId, ObjectTypes.Player);

    bytes memory onWakeup = abi.encodeCall(IWakeupHook.onWakeup, (callerEntityId, bedEntityId, extraData));
    bedEntityId.getProgram().callOrRevert(onWakeup);

    notify(callerEntityId, WakeupNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));
  }
}
