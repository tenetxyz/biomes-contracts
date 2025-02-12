// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { VoxelCoord } from "../Types.sol";

import { Player } from "../codegen/tables/Player.sol";
import { ReversePlayer } from "../codegen/tables/ReversePlayer.sol";
import { ObjectType } from "../codegen/tables/ObjectType.sol";
import { Position } from "../codegen/tables/Position.sol";
import { ReversePosition } from "../codegen/tables/ReversePosition.sol";
import { PlayerActivity } from "../codegen/tables/PlayerActivity.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ActionType } from "../codegen/common.sol";

import { IN_MAINTENANCE } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { getUniqueEntity, gravityApplies, inWorldBorder, inSpawnArea } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { notify, SpawnNotifData } from "../utils/NotifUtils.sol";

import { EntityId } from "../EntityId.sol";

contract SpawnSystem is System {
  function spawnPlayer(VoxelCoord memory spawnCoord) public returns (EntityId) {
    require(!IN_MAINTENANCE, "Biomes is in maintenance mode. Try again later");
    require(inWorldBorder(spawnCoord), "Cannot spawn outside the world border");
    require(inSpawnArea(spawnCoord), "Cannot spawn outside the spawn area");

    address newPlayer = _msgSender();
    require(!Player._get(newPlayer).exists(), "Player already spawned");

    EntityId playerEntityId = getUniqueEntity();
    EntityId existingEntityId = ReversePosition._get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    require(existingEntityId.exists(), "Cannot spawn on an unrevealed block");
    require(ObjectType._get(existingEntityId) == AirObjectID, "Cannot spawn on a non-air block");

    // Transfer any dropped items
    transferAllInventoryEntities(existingEntityId, playerEntityId, PlayerObjectID);

    Position._deleteRecord(existingEntityId);

    // Create new entity
    Position._set(playerEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);
    ReversePosition._set(spawnCoord.x, spawnCoord.y, spawnCoord.z, playerEntityId);

    // Set object type to player
    ObjectType._set(playerEntityId, PlayerObjectID);
    Player._set(newPlayer, playerEntityId);
    ReversePlayer._set(playerEntityId, newPlayer);

    // TODO: set initial mass and energy
    Energy._set(playerEntityId, EnergyData({ energy: 100, lastUpdatedTime: uint128(block.timestamp) }));
    Mass._set(playerEntityId, 10);

    PlayerActivity._set(playerEntityId, uint128(block.timestamp));
    require(!gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    notify(playerEntityId, SpawnNotifData({ playerAddress: newPlayer, spawnCoord: spawnCoord }));

    return playerEntityId;
  }
}
