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
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";

import { requireValidPlayer, requireInPlayerInfluence, createPlayer, deletePlayer } from "../utils/PlayerUtils.sol";
import { MAX_PLAYER_ENERGY, PLAYER_ENERGY_DRAIN_RATE, SPAWN_BLOCK_RANGE, MAX_PLAYER_RESPAWN_HALF_WIDTH } from "../Constants.sol";
import { ObjectTypeId, AirObjectID, PlayerObjectID, BedObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, getUniqueEntity, gravityApplies, inWorldBorder } from "../Utils.sol";
import { notify, SpawnNotifData } from "../utils/NotifUtils.sol";
import { mod } from "../utils/MathUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";
import { TerrainLib } from "./libraries/TerrainLib.sol";
import { callChipOrRevert } from "../utils/callChip.sol";
import { updateMachineEnergyLevel, massToEnergy, updatePlayerEnergyLevel } from "../utils/EnergyUtils.sol";
import { IBedChip } from "../prototypes/IBedChip.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";

import { VoxelCoord, VoxelCoordLib } from "../VoxelCoord.sol";

import { EntityId } from "../EntityId.sol";

// To avoid reaching bytecode size limit
library BedLib {
  function handleEnergyDepletion(EntityId playerEntityId, EntityId bedEntityId, EnergyData memory machineData) public {
    uint128 timeWithoutEnergy = machineData.accDepletedTime - BedPlayer._getLastAccDepletedTime(bedEntityId);
    if (timeWithoutEnergy > 0) {
      uint128 totalEnergyDepleted = timeWithoutEnergy * PLAYER_ENERGY_DRAIN_RATE;
      // No need to call updatePlayerEnergyLevel as drain rate is 0 if sleeping
      // TODO: should we revert or should we kill the player?
      uint128 currentEnergy = Energy._getEnergy(playerEntityId);
      require(totalEnergyDepleted < currentEnergy, "Player energy was depleted while sleeping");
      Energy._setEnergy(playerEntityId, currentEnergy - totalEnergyDepleted);
    }

    // Set last updated so next time updatePlayerEnergyLevel is called it will drain from here
    Energy._setLastUpdatedTime(playerEntityId, uint128(block.timestamp));
  }

  function transferInventory(EntityId playerEntityId, EntityId bedEntityId, ObjectTypeId objectTypeId) public {
    transferAllInventoryEntities(playerEntityId, bedEntityId, objectTypeId);
  }
}

contract BedSystem is System {
  using VoxelCoordLib for *;

  function sleep(EntityId bedEntityId, bytes memory extraData) external {
    checkWorldStatus();

    (EntityId playerEntityId, VoxelCoord memory playerCoord, ) = requireValidPlayer(_msgSender());

    require(ObjectType._get(bedEntityId) == BedObjectID, "Not a bed");

    requireInPlayerInfluence(playerCoord, bedEntityId);

    // TODO: should we use the forcefield from the base entity? or both?
    bedEntityId = bedEntityId.baseEntityId();
    require(!BedPlayer._getPlayerEntityId(bedEntityId).exists(), "Bed full");

    EntityId forceFieldEntityId = getForceField(Position._get(bedEntityId).toVoxelCoord());
    require(forceFieldEntityId.exists(), "Bed is not inside a forcefield");
    EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);
    require(machineData.energy > 0, "Forcefield has no energy");

    PlayerStatus._setBedEntityId(playerEntityId, bedEntityId);
    BedPlayer._set(bedEntityId, playerEntityId, machineData.accDepletedTime);

    // Increase forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate + PLAYER_ENERGY_DRAIN_RATE);

    BedLib.transferInventory(playerEntityId, bedEntityId, BedObjectID);

    deletePlayer(playerEntityId, playerCoord);

    address chipAddress = bedEntityId.getChipAddress();
    require(chipAddress != address(0), "Spawn tile has no chip");

    bytes memory onSleepCall = abi.encodeCall(IBedChip.onSleep, (playerEntityId, bedEntityId, extraData));
    callChipOrRevert(chipAddress, onSleepCall);
  }

  function wakeup(VoxelCoord memory spawnCoord, bytes memory extraData) external {
    checkWorldStatus();
    require(inWorldBorder(spawnCoord), "Cannot spawn outside the world border");

    require(!gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    EntityId playerEntityId = Player._get(_msgSender());
    require(playerEntityId.exists(), "Player does not exist");
    EntityId bedEntityId = PlayerStatus._getBedEntityId(playerEntityId);
    require(bedEntityId.exists(), "Player is not sleeping");

    VoxelCoord memory bedCoord = Position._get(bedEntityId).toVoxelCoord();
    require(bedCoord.inSurroundingCube(MAX_PLAYER_RESPAWN_HALF_WIDTH, spawnCoord), "Bed is too far away");

    EntityId forceFieldEntityId = getForceField(bedCoord);
    EnergyData memory machineData = updateMachineEnergyLevel(forceFieldEntityId);

    // Deplete's player energy if necessary
    BedLib.handleEnergyDepletion(playerEntityId, bedEntityId, machineData);

    // Decrease forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, machineData.drainRate - PLAYER_ENERGY_DRAIN_RATE);

    PlayerStatus._deleteRecord(playerEntityId);
    BedPlayer._deleteRecord(bedEntityId);

    createPlayer(playerEntityId, spawnCoord);

    BedLib.transferInventory(bedEntityId, playerEntityId, PlayerObjectID);

    if (machineData.energy > 0) {
      address chipAddress = bedEntityId.getChipAddress();
      require(chipAddress != address(0), "Bed has no chip");

      bytes memory onWakeupCall = abi.encodeCall(IBedChip.onWakeup, (playerEntityId, bedEntityId, extraData));
      callChipOrRevert(chipAddress, onWakeupCall);
    }
  }
}
