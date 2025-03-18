// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";

import { Position } from "../utils/Vec3Storage.sol";

import { requireValidPlayer, requireInPlayerInfluence, addPlayerToGrid, removePlayerFromGrid, removePlayerFromBed } from "../utils/PlayerUtils.sol";
import { PLAYER_ENERGY_DRAIN_RATE, MAX_PLAYER_RESPAWN_HALF_WIDTH } from "../Constants.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { notify, SleepNotifData, WakeupNotifData } from "../utils/NotifUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { callProgramOrRevert } from "../utils/callProgram.sol";
import { massToEnergy, updateEnergyLevel, updateSleepingPlayerEnergy } from "../utils/EnergyUtils.sol";
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
    machineData = updateEnergyLevel(forceFieldEntityId);
    playerData = updateSleepingPlayerEnergy(playerEntityId, bedEntityId, machineData, bedCoord);
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
    require(objectTypeId == ObjectTypes.Air, "Cannot drop items on a non-air block");

    (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
    (, EnergyData memory playerData) = BedLib.updateEntities(forceFieldEntityId, playerEntityId, bedEntityId, bedCoord);

    require(playerData.energy == 0, "Player is not dead");

    removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    BedLib.transferInventory(bedEntityId, dropEntityId, ObjectTypes.Air);
    // TODO: Should we safecall the program?
  }

  function sleep(EntityId bedEntityId, bytes calldata extraData) public {
    (EntityId playerEntityId, Vec3 playerCoord, ) = requireValidPlayer(_msgSender());

    require(ObjectType._get(bedEntityId) == ObjectTypes.Bed, "Not a bed");

    Vec3 bedCoord = Position._get(bedEntityId);
    requireInPlayerInfluence(playerCoord, bedCoord);

    bedEntityId = bedEntityId.baseEntityId();
    require(!BedPlayer._getPlayerEntityId(bedEntityId).exists(), "Bed full");

    (EntityId forceFieldEntityId, ) = getForceField(Position._get(bedEntityId));
    require(forceFieldEntityId.exists(), "Bed is not inside a forcefield");
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);
    require(machineData.energy > 0, "Forcefield has no energy");

    PlayerStatus._setBedEntityId(playerEntityId, bedEntityId);
    BedPlayer._set(bedEntityId, playerEntityId, machineData.accDepletedTime);

    // Increase forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + PLAYER_ENERGY_DRAIN_RATE);

    BedLib.transferInventory(playerEntityId, bedEntityId, ObjectTypes.Bed);

    removePlayerFromGrid(playerEntityId, playerCoord);

    notify(playerEntityId, SleepNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));

    bytes memory onSleepCall = abi.encodeCall(IBedProgram.onSleep, (playerEntityId, bedEntityId, extraData));
    callProgramOrRevert(bedEntityId.getProgram(), onSleepCall);
  }

  function wakeup(Vec3 spawnCoord, bytes calldata extraData) public {
    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    EntityId playerEntityId = Player._get(_msgSender());
    require(playerEntityId.exists(), "Player does not exist");
    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not sleeping");

    Vec3 bedCoord = Position._get(bedEntityId);
    require(bedCoord.inSurroundingCube(spawnCoord, MAX_PLAYER_RESPAWN_HALF_WIDTH), "Bed is too far away");

    (EntityId forceFieldEntityId, ) = getForceField(bedCoord);
    (EnergyData memory machineData, EnergyData memory playerData) = BedLib.updateEntities(
      forceFieldEntityId,
      playerEntityId,
      bedEntityId,
      bedCoord
    );

    require(playerData.energy > 0, "Player died while sleeping");

    removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    addPlayerToGrid(playerEntityId, spawnCoord);

    BedLib.transferInventory(bedEntityId, playerEntityId, ObjectTypes.Player);

    notify(playerEntityId, WakeupNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));

    if (machineData.energy > 0) {
      bytes memory onWakeupCall = abi.encodeCall(IBedProgram.onWakeup, (playerEntityId, bedEntityId, extraData));
      callProgramOrRevert(bedEntityId.getProgram(), onWakeupCall);
    }
  }
}
