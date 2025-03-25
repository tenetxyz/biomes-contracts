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
import { PLAYER_ENERGY_DRAIN_RATE, MAX_PLAYER_RESPAWN_HALF_WIDTH } from "../Constants.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { notify, SleepNotifData, WakeupNotifData } from "../utils/NotifUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { updateMachineEnergy, updateSleepingPlayerEnergy } from "../utils/EnergyUtils.sol";
import { IBedProgram } from "../prototypes/IBedProgram.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";
import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";

import { Vec3 } from "../Vec3.sol";

import { EntityId } from "../EntityId.sol";

// To avoid reaching bytecode size limit
library BedLib {
  function transferInventory(EntityId playerEntityId, EntityId bedEntityId, ObjectTypeId objectTypeId) public {
    transferAllInventoryEntities(playerEntityId, bedEntityId, objectTypeId);
  }

  function updateEntities(
    EntityId forceFieldEntityId,
    EntityId playerEntityId,
    EntityId bedEntityId,
    Vec3 bedCoord
  ) public returns (EnergyData memory machineData, EnergyData memory playerData) {
    uint128 depletedTime;
    (machineData, depletedTime) = updateMachineEnergy(forceFieldEntityId);
    playerData = updateSleepingPlayerEnergy(playerEntityId, bedEntityId, depletedTime, bedCoord);
    return (machineData, playerData);
  }
}

contract BedSystem is System {
  function removeDeadPlayerFromBed(EntityId playerEntityId, Vec3 dropCoord) public {
    checkWorldStatus();

    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not in a bed");

    Vec3 bedCoord = Position._get(bedEntityId);

    // TODO: use a different constant?
    require(bedCoord.inSurroundingCube(dropCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH), "Drop location is too far from bed");

    (EntityId dropEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(dropCoord);
    require(ObjectTypeMetadata.getCanPassThrough(objectTypeId), "Cannot drop items on a non-passable block");

    (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
    (, EnergyData memory playerData) = BedLib.updateEntities(forceFieldEntityId, playerEntityId, bedEntityId, bedCoord);

    require(playerData.energy == 0, "Player is not dead");

    PlayerUtils.removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    BedLib.transferInventory(bedEntityId, dropEntityId, objectTypeId);
    // TODO: Should we safecall the program?
  }

  function sleep(EntityId bedEntityId, bytes calldata extraData) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = PlayerUtils.requireValidPlayer(_msgSender());

    require(ObjectType._get(bedEntityId) == ObjectTypes.Bed, "Not a bed");

    Vec3 bedCoord = Position._get(bedEntityId);
    PlayerUtils.requireInPlayerInfluence(playerCoord, bedCoord);

    bedEntityId = bedEntityId.baseEntityId();
    require(!BedPlayer._getPlayerEntityId(bedEntityId).exists(), "Bed full");

    (EntityId forceFieldEntityId, ) = getForceField(Position._get(bedEntityId));
    require(forceFieldEntityId.exists(), "Bed is not inside a forcefield");
    (EnergyData memory machineData, uint128 depletedTime) = updateMachineEnergy(forceFieldEntityId);
    require(machineData.energy > 0, "Forcefield has no energy");

    PlayerStatus._setBedEntityId(playerEntityId, bedEntityId);
    BedPlayer._set(bedEntityId, playerEntityId, depletedTime);

    // Increase forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + PLAYER_ENERGY_DRAIN_RATE);

    BedLib.transferInventory(playerEntityId, bedEntityId, ObjectTypes.Bed);

    PlayerUtils.removePlayerFromGrid(playerEntityId, playerCoord);

    notify(playerEntityId, SleepNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));

    bytes memory onSleepCall = abi.encodeCall(IBedProgram.onSleep, (playerEntityId, bedEntityId, extraData));
    callProgramOrRevert(bedEntityId.getProgram(), onSleepCall);
  }

  function wakeup(Vec3 spawnCoord, bytes calldata extraData) public {
    checkWorldStatus();

    EntityId playerEntityId = Player._get(_msgSender());
    require(playerEntityId.exists(), "Caller not allowed");
    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not sleeping");

    Vec3 bedCoord = Position._get(bedEntityId);
    require(bedCoord.inSurroundingCube(spawnCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH), "Bed is too far away");

    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
    (EnergyData memory machineData, EnergyData memory playerData) = BedLib.updateEntities(
      forceFieldEntityId,
      playerEntityId,
      bedEntityId,
      bedCoord
    );

    require(playerData.energy > 0, "Player died while sleeping");

    PlayerUtils.removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    PlayerUtils.addPlayerToGrid(playerEntityId, spawnCoord);

    BedLib.transferInventory(bedEntityId, playerEntityId, ObjectTypes.Player);

    notify(playerEntityId, WakeupNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));

    if (machineData.energy > 0) {
      bytes memory onWakeupCall = abi.encodeCall(IBedProgram.onWakeup, (playerEntityId, bedEntityId, extraData));
      callProgramOrRevert(bedEntityId.getProgram(), onWakeupCall);
    }
  }
}
