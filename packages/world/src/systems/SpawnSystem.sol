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
import { LocalEnergyPool } from "../codegen/tables/LocalEnergyPool.sol";
import { PlayerActionNotif, PlayerActionNotifData } from "../codegen/tables/PlayerActionNotif.sol";
import { Energy, EnergyData } from "../codegen/tables/Energy.sol";
import { Mass } from "../codegen/tables/Mass.sol";
import { ActionType } from "../codegen/common.sol";

import { WORLD_DIM_X, WORLD_DIM_Z, SPAWN_ENERGY, SPAWN_SHARD_DIM } from "../Constants.sol";
import { AirObjectID, PlayerObjectID } from "../ObjectTypeIds.sol";
import { checkWorldStatus, getUniqueEntity, gravityApplies, inWorldBorder } from "../Utils.sol";
import { transferAllInventoryEntities } from "../utils/InventoryUtils.sol";
import { notify, SpawnNotifData } from "../utils/NotifUtils.sol";
import { coordToShardCoordIgnoreY } from "../utils/VoxelCoordUtils.sol";
import { getForceField } from "../utils/ForceFieldUtils.sol";

import { EntityId } from "../EntityId.sol";

contract SpawnSystem is System {
  function randomSpawn(uint256 blockNumber, int32 y) public returns (EntityId) {
    checkWorldStatus();
    // TODO: use constant
    require(blockNumber < block.number - 10, "Can only choose past 10 blocks");

    VoxelCoord memory spawnCoord;
    spawnCoord.y = y;

    uint256 randX = uint256(keccak256(abi.encodePacked(blockhash(blockNumber), _msgSender())));
    uint256 randZ = uint256(keccak256(abi.encodePacked(randX)));
    spawnCoord.x = int32(int256(randX % uint256(int256(WORLD_DIM_X)))) - WORLD_DIM_X / 2;
    spawnCoord.z = int32(int256(randZ % uint256(int256(WORLD_DIM_X)))) - WORLD_DIM_X / 2;

    EntityId forceFieldEntityId = getForceField(spawnCoord);
    require(!forceFieldEntityId.exists(), "Cannot spawn in force field");

    // TODO: this is not really necessary
    require(inWorldBorder(spawnCoord), "Cannot spawn outside the world border");

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

    VoxelCoord memory shardCoord = coordToShardCoordIgnoreY(spawnCoord, SPAWN_SHARD_DIM);
    uint128 localEnergy = LocalEnergyPool._get(shardCoord.x, 0, shardCoord.z);
    require(localEnergy >= SPAWN_ENERGY, "Not enough energy in local energy pool");
    LocalEnergyPool._set(shardCoord.x, 0, shardCoord.z, localEnergy - SPAWN_ENERGY);
    Energy._set(playerEntityId, EnergyData({ energy: SPAWN_ENERGY, lastUpdatedTime: uint128(block.timestamp) }));
    // TODO: check how mass should work
    Mass._set(playerEntityId, 10);

    PlayerActivity._set(playerEntityId, uint128(block.timestamp));
    require(!gravityApplies(spawnCoord), "Cannot spawn player here as gravity applies");

    notify(playerEntityId, SpawnNotifData({ playerAddress: newPlayer, spawnCoord: spawnCoord }));

    return playerEntityId;
  }
}
