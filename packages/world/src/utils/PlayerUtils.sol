// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";

import { BaseEntity } from "../codegen/tables/BaseEntity.sol";
import { BedPlayer } from "../codegen/tables/BedPlayer.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";

import { ObjectTypeMetadata } from "../codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../codegen/tables/Player.sol";
import { PlayerStatus } from "../codegen/tables/PlayerStatus.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";

import { ForceFieldFragmentPosition, MovablePosition, Position, ReverseMovablePosition } from "../utils/Vec3Storage.sol";

import { ObjectTypeId } from "../ObjectTypeId.sol";
import { ObjectTypes } from "../ObjectTypes.sol";
import { checkWorldStatus, getUniqueEntity } from "../Utils.sol";
import { updatePlayerEnergy } from "./EnergyUtils.sol";

import { getMovableEntityAt, getOrCreateEntityAt, safeGetObjectTypeIdAt, setMovableEntityAt } from "./EntityUtils.sol";
import { getForceField } from "./ForceFieldUtils.sol";
import { InventoryUtils } from "./InventoryUtils.sol";

import { FRAGMENT_SIZE, PLAYER_ENERGY_DRAIN_RATE } from "../Constants.sol";
import { EntityId } from "../EntityId.sol";
import { ObjectTypeLib } from "../ObjectTypeLib.sol";
import { Vec3, vec3 } from "../Vec3.sol";

import { DeathNotification, notify } from "./NotifUtils.sol";

using ObjectTypeLib for ObjectTypeId;

library PlayerUtils {
  function getOrCreatePlayer() internal returns (EntityId) {
    address playerAddress = WorldContextConsumerLib._msgSender();
    EntityId player = Player._get(playerAddress);
    if (!player.exists()) {
      player = getUniqueEntity();

      Player._set(playerAddress, player);
      ReversePlayer._set(player, playerAddress);

      // Set the player object type first
      ObjectType._set(player, ObjectTypes.Player);
    }

    return player;
  }

  function addPlayerToGrid(EntityId player, Vec3 playerCoord) internal {
    // Check if the spawn location is valid
    ObjectTypeId terrainObjectTypeId = safeGetObjectTypeIdAt(playerCoord);
    require(
      ObjectTypeMetadata._getCanPassThrough(terrainObjectTypeId) && !getMovableEntityAt(playerCoord).exists(),
      "Cannot spawn on a non-passable block"
    );

    // Set the player at the base coordinate
    setMovableEntityAt(playerCoord, player);

    // Handle the player's body parts
    Vec3[] memory coords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      Vec3 relativeCoord = coords[i];
      ObjectTypeId relativeTerrainObjectTypeId = safeGetObjectTypeIdAt(relativeCoord);
      require(
        ObjectTypeMetadata._getCanPassThrough(relativeTerrainObjectTypeId)
          && !getMovableEntityAt(relativeCoord).exists(),
        "Cannot spawn on a non-passable block"
      );
      EntityId relativePlayer = getUniqueEntity();
      ObjectType._set(relativePlayer, ObjectTypes.Player);
      setMovableEntityAt(relativeCoord, relativePlayer);
      BaseEntity._set(relativePlayer, player);
    }
  }

  function removePlayerFromGrid(EntityId player, Vec3 playerCoord) internal {
    MovablePosition._deleteRecord(player);
    ReverseMovablePosition._deleteRecord(playerCoord);

    Vec3[] memory coords = ObjectTypes.Player.getRelativeCoords(playerCoord);
    // Only iterate through relative schema coords
    for (uint256 i = 1; i < coords.length; i++) {
      Vec3 relativeCoord = coords[i];
      EntityId relativePlayer = getMovableEntityAt(relativeCoord);
      MovablePosition._deleteRecord(relativePlayer);
      ReverseMovablePosition._deleteRecord(relativeCoord);
      ObjectType._deleteRecord(relativePlayer);
      BaseEntity._deleteRecord(relativePlayer);
    }
  }

  function removePlayerFromBed(EntityId player, EntityId bed, EntityId forceField) internal {
    PlayerStatus._deleteRecord(player);
    BedPlayer._deleteRecord(bed);

    // Decrease forcefield's drain rate
    Energy._setDrainRate(forceField, Energy._getDrainRate(forceField) - PLAYER_ENERGY_DRAIN_RATE);
  }

  /// @dev Kills the player, it assumes the player is not sleeping
  // If the player was already killed, it will return early
  function killPlayer(EntityId player, Vec3 coord) internal {
    if (ReverseMovablePosition._get(coord) != player) {
      return;
    }
    (EntityId to,) = getOrCreateEntityAt(coord);
    InventoryUtils.transferAll(player, to);
    removePlayerFromGrid(player, coord);
    notify(player, DeathNotification({ deathCoord: coord }));
  }
}
