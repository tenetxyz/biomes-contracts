// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { BedPlayer } from "../codegen/tables/BedPlayer.sol";

import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Machine } from "../codegen/tables/Machine.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";

import { Position } from "../utils/Vec3Storage.sol";

import { MAX_RESPAWN_HALF_WIDTH, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";

import { updateMachineEnergy, updateSleepingPlayerEnergy } from "../utils/EnergyUtils.sol";

import { getOrCreateEntityAt } from "../utils/EntityUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { InventoryUtils } from "../utils/InventoryUtils.sol";
import { SleepNotification, WakeupNotification, notify } from "../utils/NotifUtils.sol";
import { PlayerUtils } from "../utils/PlayerUtils.sol";

import { MoveLib } from "./libraries/MoveLib.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";

import { EntityId } from "../EntityId.sol";
import { ProgramId } from "../ProgramId.sol";
import { ISleepHook, IWakeupHook } from "../ProgramInterfaces.sol";
import { Vec3 } from "../Vec3.sol";

// To avoid reaching bytecode size limit
library BedLib {
  function transferInventory(EntityId player, EntityId bed) public {
    InventoryUtils.transferAll(player, bed);
  }

  function updateSleepingPlayer(EntityId forceField, EntityId player, EntityId bed, Vec3 bedCoord)
    public
    returns (EnergyData memory)
  {
    uint128 depletedTime;
    (, depletedTime) = updateMachineEnergy(forceField);
    return updateSleepingPlayerEnergy(player, bed, depletedTime, bedCoord);
  }
}

contract BedSystem is System {
  function removeDeadPlayerFromBed(EntityId player, Vec3 dropCoord) public {
    checkWorldStatus();

    EntityId bed = PlayerStatus._getBedEntityId(player);
    require(bed.exists(), "Player is not in a bed");

    Vec3 bedCoord = Position._get(bed);

    // TODO: use a different constant?
    require(bedCoord.inSurroundingCube(dropCoord, MAX_RESPAWN_HALF_WIDTH), "Drop location is too far from bed");

    (EntityId drop, ObjectTypeId objectTypeId) = getOrCreateEntityAt(dropCoord);
    require(ObjectTypeMetadata._getCanPassThrough(objectTypeId), "Cannot drop items on a non-passable block");

    (EntityId forceField,) = getForceField(bedCoord);
    EnergyData memory playerData = BedLib.updateSleepingPlayer(forceField, player, bed, bedCoord);

    require(playerData.energy == 0, "Player is not dead");

    PlayerUtils.removePlayerFromBed(player, bed, forceField);

    BedLib.transferInventory(bed, drop);
    // TODO: Should we safecall the program?
  }

  function sleep(EntityId caller, EntityId bed, bytes calldata extraData) public {
    caller.activate();

    (Vec3 callerCoord, Vec3 bedCoord) = caller.requireConnected(bed);

    require(ObjectType._get(bed) == ObjectTypes.Bed, "Not a bed");

    bed = bed.baseEntityId();
    require(!BedPlayer._getPlayerEntityId(bed).exists(), "Bed full");

    (EntityId forceField,) = getForceField(Position._get(bed));
    require(forceField.exists(), "Bed is not inside a forcefield");
    (EnergyData memory machineData, uint128 depletedTime) = updateMachineEnergy(forceField);

    PlayerStatus._setBedEntityId(caller, bed);
    BedPlayer._set(bed, caller, depletedTime);

    // Increase forcefield's drain rate
    Energy._setDrainRate(forceField, machineData.drainRate + PLAYER_ENERGY_DRAIN_RATE);

    BedLib.transferInventory(caller, bed);

    PlayerUtils.removePlayerFromGrid(caller, callerCoord);

    bytes memory onSleep = abi.encodeCall(ISleepHook.onSleep, (caller, bed, extraData));
    bed.getProgram().callOrRevert(onSleep);

    notify(caller, SleepNotification({ bed: bed, bedCoord: bedCoord }));
  }

  // TODO: for now this only supports players, as players are the only entities that can sleep
  function wakeup(EntityId caller, Vec3 spawnCoord, bytes calldata extraData) public {
    checkWorldStatus();

    caller.requireCallerAllowed(_msgSender());

    EntityId bed = PlayerStatus._getBedEntityId(caller);
    require(bed.exists(), "Player is not sleeping");

    Vec3 bedCoord = Position._get(bed);
    require(bedCoord.inSurroundingCube(spawnCoord, MAX_RESPAWN_HALF_WIDTH), "Bed is too far away");

    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    (EntityId forceField,) = getForceField(bedCoord);
    EnergyData memory playerData = BedLib.updateSleepingPlayer(forceField, caller, bed, bedCoord);

    require(playerData.energy > 0, "Player died while sleeping");

    PlayerUtils.removePlayerFromBed(caller, bed, forceField);
    PlayerUtils.addPlayerToGrid(caller, spawnCoord);

    BedLib.transferInventory(bed, caller);

    bytes memory onWakeup = abi.encodeCall(IWakeupHook.onWakeup, (caller, bed, extraData));
    bed.getProgram().callOrRevert(onWakeup);

    notify(caller, WakeupNotification({ bed: bed, bedCoord: bedCoord }));
  }
}
