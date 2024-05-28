// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "../src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../src/codegen/tables/Stamina.sol";
import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { ExperiencePoints } from "../src/codegen/tables/ExperiencePoints.sol";
import { BlockMetadata } from "../src/codegen/tables/BlockMetadata.sol";
import { WorldMetadata } from "../src/codegen/tables/WorldMetadata.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem } from "./utils/TestUtils.sol";

contract HitTest is MudTest, GasReporter {
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
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](2);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y - 1, spawnCoord.z - 1);
    path[1] = VoxelCoord(path[0].x - 1, path[0].y - 1, path[0].z);
    world.move(path);

    spawnCoord = path[1];

    return playerEntityId;
  }

  function setupPlayer2(int16 zOffset) public returns (bytes32) {
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z + zOffset);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
    world.move(path);

    vm.stopPrank();
    return playerEntityId2;
  }

  function testHit() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    uint16 player1HealthBefore = Health.getHealth(playerEntityId);
    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    uint16 player2HealthBefore = Health.getHealth(playerEntityId2);
    uint32 player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    startGasReport("hit player");
    world.hit(bob);
    endGasReport();

    assertTrue(Health.getHealth(playerEntityId) == player1HealthBefore, "Player 1 health changed");
    assertTrue(Health.getHealth(playerEntityId2) < player2HealthBefore, "Player 2 health did not decrease");

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.stopPrank();
  }

  function testHitNonPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(Player.get(bob) == bytes32(0), "Player already exists");

    vm.expectRevert("HitSystem: hit player does not exist");
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);
    vm.stopPrank();

    vm.expectRevert("HitSystem: player does not exist");
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitSelf() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.expectRevert("HitSystem: cannot hit yourself");
    world.hit(alice);

    vm.stopPrank();
  }

  function testHitTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(2);
    vm.startPrank(alice, alice);

    vm.expectRevert("HitSystem: hit entity is not in surrounding cube of player");
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitInsideSpawn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("HitSystem: cannot hit players in spawn area");
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitNotEnoughStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 0);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    vm.expectRevert("HitSystem: player does not have enough stamina");
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitFatal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    vm.startPrank(worldDeployer, worldDeployer);
    Health.setHealth(playerEntityId2, 1);
    Health.setLastUpdatedTime(playerEntityId2, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("hit player fatal");
    world.hit(bob);
    endGasReport();

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");

    assertTrue(Equipped.get(playerEntityId2) == bytes32(0), "Equipped not removed");
    assertTrue(Player.get(bob) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId2) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId2) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId2) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId2) == 0, "Player stamina not reduced to 0");
    assertTrue(ExperiencePoints.get(playerEntityId2) == 0, "Player xp not reduced to 0");

    vm.stopPrank();
  }

  function testHitRegenHealthAndStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 1);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);

    Health.setHealth(playerEntityId, 1);
    Health.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    uint256 newBlockTime = block.timestamp + ((TIME_BEFORE_INCREASE_STAMINA + TIME_BEFORE_INCREASE_HEALTH + 1) * 1000);
    vm.warp(newBlockTime);

    uint16 player1HealthBefore = Health.getHealth(playerEntityId);
    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    uint16 player2HealthBefore = Health.getHealth(playerEntityId2);
    uint32 player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    startGasReport("hit player w/ health and stamina regen");
    world.hit(bob);
    endGasReport();

    assertTrue(Health.getHealth(playerEntityId) > player1HealthBefore, "Player 1 health not changed");
    assertTrue(Health.getHealth(playerEntityId2) < player2HealthBefore, "Player 2 health did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) >= player2StaminaBefore, "Player 2 stamina not changed");

    vm.stopPrank();
  }

  function testHitWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    world.logoffPlayer();

    vm.expectRevert("HitSystem: player isn't logged in");
    world.hit(bob);

    world.loginPlayer(spawnCoord);

    vm.startPrank(bob, bob);
    world.logoffPlayer();
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("HitSystem: hit player isn't logged in");
    world.hit(bob);

    vm.stopPrank();
  }
}
