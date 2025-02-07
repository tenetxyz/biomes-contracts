// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Health } from "../src/codegen/tables/Health.sol";
import { Stamina } from "../src/codegen/tables/Stamina.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { GrassObjectID, OakLogObjectID, AirObjectID, OakLumberObjectID, PlayerObjectID, WoodenPickObjectID, ChestObjectID } from "../src/ObjectTypeIds.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { testAddToInventoryCount } from "../test/utils/TestUtils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA } from "../src/Constants.sol";
import { positionDataToVoxelCoord, callGravity, getUniqueEntity } from "../src/Utils.sol";

int32 constant SPAWN_LOW_X = 363;
int32 constant SPAWN_LOW_Z = -225;

int32 constant SPAWN_HIGH_X = 387;
int32 constant SPAWN_HIGH_Z = -205;

int32 constant SPAWN_GROUND_Y = 17;

contract StressTest is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    address[] memory players = new address[](100);
    // Fill up players with pseudo-random addresses
    for (uint i = 0; i < players.length; i++) {
      // Generate a pseudo-random hash by combining the current timestamp, sender address, and a nonce
      // bytes32 hash = keccak256(abi.encodePacked(block.timestamp, msg.sender, i));
      bytes32 hash = keccak256(abi.encodePacked("seed", i));
      // Convert the hash to an address
      players[i] = address(uint160(uint256(hash)));
    }

    int32 spawnZLength = SPAWN_HIGH_Z - SPAWN_LOW_Z;
    int32 spawnXLength = SPAWN_HIGH_X - SPAWN_LOW_X;

    // call spawn player
    for (uint i = 0; i < players.length; i++) {
      bytes32 entityId = getUniqueEntity();
      VoxelCoord memory playerCoord = VoxelCoord(
        SPAWN_LOW_X + int32(int(i)) / spawnZLength,
        SPAWN_GROUND_Y + 1,
        SPAWN_LOW_Z + (int32(int(i)) - (spawnZLength * (int32(int(i)) / spawnZLength)))
      );
      Position.set(entityId, playerCoord.x, playerCoord.y, playerCoord.z);
      ReversePosition.set(playerCoord.x, playerCoord.y, playerCoord.z, entityId);
      ObjectType.set(entityId, PlayerObjectID);
      Player.set(players[i], entityId);
      ReversePlayer.set(entityId, players[i]);
      Health.set(entityId, block.timestamp, MAX_PLAYER_HEALTH);
      Stamina.set(entityId, block.timestamp, MAX_PLAYER_STAMINA);
    }

    // teleport players
    // for (uint i = 0; i < players.length; i++) {
    //   address player = players[i];
    //   bytes32 playerEntityId = Player.get(player);
    //   VoxelCoord memory oldCoord = positionDataToVoxelCoord(Position.get(playerEntityId));
    //   VoxelCoord memory newCoord = VoxelCoord(oldCoord.x, oldCoord.y, oldCoord.z - 20);

    //   bytes32 newEntityId = getUniqueEntity();
    //   ObjectType.set(newEntityId, AirObjectID);

    //   ReversePosition.set(oldCoord.x, oldCoord.y, oldCoord.z, newEntityId);
    //   Position.set(newEntityId, oldCoord.x, oldCoord.y, oldCoord.z);

    //   Position.set(playerEntityId, newCoord.x, newCoord.y, newCoord.z);
    //   ReversePosition.set(newCoord.x, newCoord.y, newCoord.z, playerEntityId);

    //   uint32 currentStamina = Stamina.getStamina(playerEntityId);
    //   Stamina.setStamina(playerEntityId, currentStamina - 150);

    // VoxelCoord memory belowCoord = VoxelCoord(newCoord.x, newCoord.y - 1, newCoord.z);
    // bytes32 belowEntityId = ReversePosition.get(belowCoord.x, belowCoord.y, belowCoord.z);
    // if (belowEntityId == bytes32(0) || ObjectType.get(belowEntityId) == AirObjectID) {
    //   callGravity(playerEntityId, newCoord);
    // }
    // }

    vm.stopBroadcast();
  }
}
