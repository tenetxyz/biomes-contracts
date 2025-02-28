// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerPosition } from "../codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../codegen/tables/ReversePlayerPosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";

import { requireValidPlayer, requireInPlayerInfluence, addPlayerToGrid, removePlayerFromGrid, removePlayerFromBed } from "../utils/PlayerUtils.sol";
import { MAX_PLAYER_ENERGY, PLAYER_ENERGY_DRAIN_RATE, MAX_PLAYER_RESPAWN_HALF_WIDTH } from "../Constants.sol";
import { ObjectTypeId, AirObjectID, PlayerObjectID, BedObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, getUniqueEntity, inWorldBorder } from "../Utils.sol";
import { notify, SleepNotifData, WakeupNotifData } from "../utils/NotifUtils.sol";
import { mod } from "../utils/MathUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { massToEnergy, updateEnergyLevel, updateSleepingPlayerEnergy } from "../utils/EnergyUtils.sol";
import { IBedChip } from "../prototypes/IBedChip.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { MoveLib } from "./libraries/MoveLib.sol";

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

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
    VoxelCoord memory bedCoord
  ) public returns (EnergyData memory machineData, EnergyData memory playerData) {
    machineData = updateEnergyLevel(forceFieldEntityId);
    playerData = updateSleepingPlayerEnergy(playerEntityId, bedEntityId, machineData, bedCoord);
    return (machineData, playerData);
  }
}

contract BedSystem is System {
  using VoxelCoordLib for *;

  function removeDeadPlayerFromBed(EntityId playerEntityId, VoxelCoord memory dropCoord) public {
    checkWorldStatus();

    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not in a bed");

    VoxelCoord memory bedCoord = Position._get(bedEntityId).toVoxelCoord();

    // TODO: use a different constant?
    require(bedCoord.inSurroundingCube(MAX_PLAYER_RESPAWN_HALF_WIDTH, dropCoord), "Drop location is too far from bed");

    (EntityId dropEntityId, ObjectTypeId objectTypeId) = dropCoord.getOrCreateEntity();
    require(objectTypeId == AirObjectID, "Cannot drop items on a non-air block");

    EntityId forceFieldEntityId = getForceField(bedCoord);
    (, EnergyData memory playerData) = BedLib.updateEntities(forceFieldEntityId, playerEntityId, bedEntityId, bedCoord);

    require(playerData.energy == 0, "Player is not dead");

    removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    BedLib.transferInventory(bedEntityId, dropEntityId, AirObjectID);
    // TODO: Should we safecall the chip?
  }

  function sleepWithExtraData(EntityId bedEntityId, bytes memory extraData) public {
    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());

    require(ObjectType._get(bedEntityId) == BedObjectID, "Not a bed");

    VoxelCoord memory bedCoord = Position._get(bedEntityId).toVoxelCoord();
    requireInPlayerInfluence(playerCoord, bedCoord);

    bedEntityId = bedEntityId.baseEntityId();
    require(!BedPlayer._getPlayerEntityId(bedEntityId).exists(), "Bed full");

    EntityId forceFieldEntityId = getForceField(Position._get(bedEntityId).toVoxelCoord());
    require(forceFieldEntityId.exists(), "Bed is not inside a forcefield");
    EnergyData memory machineData = updateEnergyLevel(forceFieldEntityId);
    require(machineData.energy > 0, "Forcefield has no energy");

    PlayerStatus._setBedEntityId(playerEntityId, bedEntityId);
    BedPlayer._set(bedEntityId, playerEntityId, machineData.accDepletedTime);

    // Increase forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + PLAYER_ENERGY_DRAIN_RATE);

    BedLib.transferInventory(playerEntityId, bedEntityId, BedObjectID);

    removePlayerFromGrid(playerEntityId, playerCoord);

    notify(playerEntityId, SleepNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));

    address chipAddress = bedEntityId.getChipAddress();
    require(chipAddress != address(0), "Bed has no chip");

    bytes memory onSleepCall = abi.encodeCall(IBedChip.onSleep, (playerEntityId, bedEntityId, extraData));
    callChipOrRevert(chipAddress, onSleepCall);
  }

  function wakeupWithExtraData(VoxelCoord memory spawnCoord, bytes memory extraData) public {
    require(inWorldBorder(spawnCoord), "Cannot spawn outside the world border");

    require(!MoveLib._gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    EntityId playerEntityId = Player._get(_msgSender());
    require(playerEntityId.exists(), "Player does not exist");
    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not sleeping");

    VoxelCoord memory bedCoord = Position._get(bedEntityId).toVoxelCoord();
    require(bedCoord.inSurroundingCube(MAX_PLAYER_RESPAWN_HALF_WIDTH, spawnCoord), "Bed is too far away");

    EntityId forceFieldEntityId = getForceField(bedCoord);
    (EnergyData memory machineData, EnergyData memory playerData) = BedLib.updateEntities(
      forceFieldEntityId,
      playerEntityId,
      bedEntityId,
      bedCoord
    );

    require(playerData.energy > 0, "Player died while sleeping");

    removePlayerFromBed(playerEntityId, bedEntityId, forceFieldEntityId);

    addPlayerToGrid(playerEntityId, spawnCoord);

    BedLib.transferInventory(bedEntityId, playerEntityId, PlayerObjectID);

    notify(playerEntityId, WakeupNotifData({ bedEntityId: bedEntityId, bedCoord: bedCoord }));

    if (machineData.energy > 0) {
      address chipAddress = bedEntityId.getChipAddress();

      // If someone removed the chip we don't want the player to be stuck
      if (chipAddress == address(0)) return;

      bytes memory onWakeupCall = abi.encodeCall(IBedChip.onWakeup, (playerEntityId, bedEntityId, extraData));
      callChipOrRevert(chipAddress, onWakeupCall);
    }
  }

  function sleep(EntityId bedEntityId) external {
    sleepWithExtraData(bedEntityId, "");
  }

  function wakeup(VoxelCoord memory spawnCoord) external {
    wakeupWithExtraData(spawnCoord, "");
  }
}
