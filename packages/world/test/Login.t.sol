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
import { LastKnownPosition } from "../src/codegen/tables/LastKnownPosition.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "../src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../src/codegen/tables/Stamina.sol";
import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { ExperiencePoints } from "../src/codegen/tables/ExperiencePoints.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, lastKnownPositionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_RESPAWN_HALF_WIDTH, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem } from "./utils/TestUtils.sol";

contract LoginTest is MudTest, GasReporter {
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

  function testLogin() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    Health.setHealth(playerEntityId, 1);
    Stamina.setStamina(playerEntityId, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint16 healthBefore = Health.getHealth(playerEntityId);
    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    world.logoffPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);

    startGasReport("login terrain");
    world.loginPlayer(respawnCoord);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), respawnCoord),
      "Player position not set"
    );
    assertTrue(
      ReversePosition.get(respawnCoord.x, respawnCoord.y, respawnCoord.z) == playerEntityId,
      "Reverse position not set"
    );
    assertTrue(Health.getHealth(playerEntityId) == healthBefore, "Health not set");
    assertTrue(Stamina.getStamina(playerEntityId) == staminaBefore, "Stamina not set");
    assertTrue(Health.getLastUpdatedTime(playerEntityId) == block.timestamp, "Health last update time not set");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testLoginNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);

    vm.startPrank(worldDeployer, worldDeployer);
    Health.setHealth(playerEntityId, 1);
    Stamina.setStamina(playerEntityId, 1);

    assertTrue(world.getTerrainBlock(respawnCoord) == AirObjectID, "Terrain block is not air");

    bytes32 entityId = testGetUniqueEntity();
    Position.set(entityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition.set(respawnCoord.x, respawnCoord.y, respawnCoord.z, entityId);
    ObjectType.set(entityId, AirObjectID);

    // set block below to non-air
    VoxelCoord memory belowCoord = VoxelCoord(respawnCoord.x, respawnCoord.y - 1, respawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(belowCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 belowEntityId = testGetUniqueEntity();
    Position.set(belowEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
    ReversePosition.set(belowCoord.x, belowCoord.y, belowCoord.z, belowEntityId);
    ObjectType.set(belowEntityId, terrainObjectTypeId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint16 healthBefore = Health.getHealth(playerEntityId);
    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    world.logoffPlayer();

    startGasReport("login non-terrain");
    world.loginPlayer(respawnCoord);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), respawnCoord),
      "Player position not set"
    );
    assertTrue(
      ReversePosition.get(respawnCoord.x, respawnCoord.y, respawnCoord.z) == playerEntityId,
      "Reverse position not set"
    );
    assertTrue(Health.getHealth(playerEntityId) == healthBefore, "Health not set");
    assertTrue(Stamina.getStamina(playerEntityId) == staminaBefore, "Stamina not set");
    assertTrue(Health.getLastUpdatedTime(playerEntityId) == block.timestamp, "Health last update time not set");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testLoginWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }

  function testLoginAlreadyLoggedIn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.expectRevert("LoginSystem: player already logged in");
    world.loginPlayer(spawnCoord);

    world.logoffPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    world.loginPlayer(respawnCoord);

    vm.expectRevert("LoginSystem: player already logged in");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }

  function testLoginInvalidRespawnCoordNotAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    assertTrue(world.getTerrainBlock(respawnCoord) != AirObjectID, "Terrain block is air");

    vm.expectRevert("LoginSystem: cannot respawn on terrain non-air block");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }

  function testLoginInvalidRespawnCoordTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(
      spawnCoord.x,
      spawnCoord.y,
      spawnCoord.z + (MAX_PLAYER_RESPAWN_HALF_WIDTH + 1)
    );
    assertTrue(world.getTerrainBlock(respawnCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("LoginSystem: respawn coord too far from last known position");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }

  function testLoginInvalidRespawnCoordOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    VoxelCoord memory finalCoord = VoxelCoord(WORLD_BORDER_LOW_X + 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);
    Position.set(finalEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, finalEntityId);
    LastKnownPosition.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory respawnCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);

    vm.expectRevert("LoginSystem: cannot respawn outside world border");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }

  function testLoginInvalidRespawnCoordGravity() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    assertTrue(world.getTerrainBlock(respawnCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("LoginSystem: cannot respawn player with gravity");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }
}
