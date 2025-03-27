// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Equipped } from "../codegen/tables/Equipped.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";

import { Position, MovablePosition, ReverseMovablePosition, ForceFieldFragmentPosition } from "../utils/Vec3Storage.sol";

import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { updatePlayerEnergy } from "./EnergyUtils.sol";
import { getForceField } from "./ForceFieldUtils.sol";
import { transferAllInventoryEntities } from "./InventoryUtils.sol";
import { safeGetObjectTypeIdAt, getOrCreateEntityAt, getMovableEntityAt, setMovableEntityAt } from "./EntityUtils.sol";

import { EntityId } from "../EntityId.sol";
import { Vec3, vec3 } from "../Vec3.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { PLAYER_ENERGY_DRAIN_RATE, FRAGMENT_SIZE } from "../Constants.sol";
import { notify, DeathNotifData } from "./NotifUtils.sol";

using ObjectTypeLib for ObjectTypeId;

library PlayerUtils {
  function getOrCreatePlayer() internal returns (EntityId) {
    address playerAddress = WorldContextConsumerLib._msgSender();
    EntityId playerEntityId = Player._get(playerAddress);
    if (!playerEntityId.exists()) {
      playerEntityId = getUniqueEntity();

      Player._set(playerAddress, playerEntityId);
      ReversePlayer._set(playerEntityId, playerAddress);

      // Set the player object type first
      ObjectType._set(playerEntityId, ObjectTypes.Player);
    }

    return playerEntityId;
  }

  function addPlayerToGrid(EntityId playerEntityId, Vec3 playerCoord) internal {
    // Check if the spawn location is valid
    ObjectTypeId terrainObjectTypeId = safeGetObjectTypeIdAt(playerCoord);
    require(
      ObjectTypeMetadata._getCanPassThrough(terrainObjectTypeId) && !getMovableEntityAt(playerCoord).exists(),
      "Cannot spawn on a non-passable block"
    );

    // Set the player at the base coordinate
    setMovableEntityAt(playerCoord, playerEntityId);

    // Handle the player's body parts
    Vec3[] memory coords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      Vec3 relativeCoord = coords[i];
      ObjectTypeId relativeTerrainObjectTypeId = safeGetObjectTypeIdAt(relativeCoord);
      require(
        ObjectTypeMetadata._getCanPassThrough(relativeTerrainObjectTypeId) &&
          !getMovableEntityAt(relativeCoord).exists(),
        "Cannot spawn on a non-passable block"
      );
      EntityId relativePlayerEntityId = getUniqueEntity();
      ObjectType._set(relativePlayerEntityId, ObjectTypes.Player);
      setMovableEntityAt(relativeCoord, relativePlayerEntityId);
      BaseEntity._set(relativePlayerEntityId, playerEntityId);
    }
  }

  function removePlayerFromGrid(EntityId playerEntityId, Vec3 playerCoord) internal {
    MovablePosition._deleteRecord(playerEntityId);
    ReverseMovablePosition._deleteRecord(playerCoord);

    Vec3[] memory coords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      Vec3 relativeCoord = coords[i];
      EntityId relativePlayerEntityId = getMovableEntityAt(relativeCoord);
      MovablePosition._deleteRecord(relativePlayerEntityId);
      ReverseMovablePosition._deleteRecord(relativeCoord);
      ObjectType._deleteRecord(relativePlayerEntityId);
      BaseEntity._deleteRecord(relativePlayerEntityId);
    }
  }

  function removePlayerFromBed(EntityId playerEntityId, EntityId bedEntityId, EntityId forceFieldEntityId) internal {
    PlayerStatus._deleteRecord(playerEntityId);
    BedPlayer._deleteRecord(bedEntityId);

    // Decrease forcefield's drain rate
    Energy._setDrainRate(forceFieldEntityId, Energy._getDrainRate(forceFieldEntityId) - PLAYER_ENERGY_DRAIN_RATE);
  }

  /// @dev Kills the player, it assumes the player is not sleeping
  // If the player was already killed, it will return early
  function killPlayer(EntityId playerEntityId, Vec3 coord) internal {
    if (ReverseMovablePosition._get(coord) != playerEntityId) {
      return;
    }
    (EntityId toEntityId, ObjectTypeId objectTypeId) = getOrCreateEntityAt(coord);
    transferAllInventoryEntities(playerEntityId, toEntityId, objectTypeId);
    removePlayerFromGrid(playerEntityId, coord);
    notify(playerEntityId, DeathNotifData({ deathCoord: coord }));
  }
}
