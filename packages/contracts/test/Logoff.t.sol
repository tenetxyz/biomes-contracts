// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { LastKnownPosition } from "../src/codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "../src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../src/codegen/tables/Stamina.sol";
import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { ReverseInventory } from "../src/codegen/tables/ReverseInventory.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord } from "../src/Utils.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { MIN_TIME_TO_LOGOFF_AFTER_HIT, MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";
import { reverseInventoryHasItem } from "./utils/InventoryTestUtils.sol";

contract LogoffTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
  }

  function setupPlayer() public returns (bytes32) {
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y, spawnCoord.z - 1);
    world.move(path);
    spawnCoord = path[0];

    return playerEntityId;
  }

  function setupPlayer2(int32 zOffset) public returns (bytes32) {
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z + zOffset);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y, spawnCoord2.z - 1);
    world.move(path);

    vm.stopPrank();
    return playerEntityId2;
  }

  function testLogoff() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    startGasReport("logoff");
    world.logoffPlayer();
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(lastKnownPositionDataToVoxelCoord(LastKnownPosition.get(playerEntityId)), spawnCoord),
      "Last known position not set"
    );

    bytes32 airEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    assertTrue(airEntityId != playerEntityId, "Player is still in the world");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Air type not set");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(airEntityId)), spawnCoord),
      "Air position not set"
    );

    vm.stopPrank();
  }

  function testLogoffAfterHit() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(bob, bob);
    world.hit(alice);
    assertTrue(PlayerMetadata.getLastHitTime(playerEntityId) == block.timestamp, "Last hit block not set");
    assertTrue(PlayerMetadata.getLastHitTime(playerEntityId2) != block.timestamp, "Last hit block set");
    vm.stopPrank();
    vm.startPrank(alice, alice);
    vm.warp(block.timestamp + MIN_TIME_TO_LOGOFF_AFTER_HIT + 1);
    world.logoffPlayer();

    assertTrue(
      voxelCoordsAreEqual(lastKnownPositionDataToVoxelCoord(LastKnownPosition.get(playerEntityId)), spawnCoord),
      "Last known position not set"
    );

    bytes32 airEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    assertTrue(airEntityId != playerEntityId, "Player is still in the world");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Air type not set");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(airEntityId)), spawnCoord),
      "Air position not set"
    );

    vm.stopPrank();
  }

  function testLogoffAfterHitTooSoon() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(bob, bob);
    world.hit(alice);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("LogoffSystem: player needs to wait before logging off as they were recently hit");
    world.logoffPlayer();

    vm.stopPrank();
  }

  function testLogoffWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();

    vm.expectRevert("LogoffSystem: player does not exist");
    world.logoffPlayer();
  }

  function testLogoffAlreadyLoggedOff() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    vm.expectRevert("LogoffSystem: player isn't logged in");
    world.logoffPlayer();

    vm.stopPrank();
  }
}
