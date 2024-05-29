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
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, MAX_PLAYER_RESPAWN_HALF_WIDTH, MIN_TIME_BEFORE_AUTO_LOGOFF, INITIAL_PLAYER_XP } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, BlueDyeObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { burnTestXP, mintTestXP, testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";
import { Bling } from "../external/Bling.sol";

contract BlingTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;
  Bling bling;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);

    vm.startPrank(worldDeployer, worldDeployer);
    bling = new Bling(worldAddress);
    WorldMetadata.setToken(address(bling));
    vm.stopPrank();
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

  function testXPToBling() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    startGasReport("convertXPToBling");
    world.convertXPToBling(ExperiencePoints.get(playerEntityId));
    endGasReport();

    assertTrue(bling.balanceOf(alice) > 0, "Bling balance not set");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "XP not reset");

    vm.stopPrank();
  }

  function testBlingToXP() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    startGasReport("convertXPToBling");
    world.convertXPToBling(ExperiencePoints.get(playerEntityId));
    endGasReport();

    assertTrue(bling.balanceOf(alice) > 0, "Bling balance not set");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "XP not reset");

    world.convertBlingToXP(bling.balanceOf(alice));

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    vm.stopPrank();
  }

  function testConvertXPToBlingLoggedOff() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) == 1, "XP not set");

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    uint256 currentXP = ExperiencePoints.get(playerEntityId);
    vm.expectRevert("BlingSystem: player has no XP to convert");
    world.convertXPToBling(currentXP);

    vm.stopPrank();
  }

  function testConvertXPToBlingNotEnoughXP() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    uint256 currentXP = ExperiencePoints.get(playerEntityId);

    vm.expectRevert("player does not have enough xp");
    world.convertXPToBling(currentXP + 1);

    vm.stopPrank();
  }

  function testConvertXPToBlingWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();

    vm.expectRevert("BlingSystem: player does not exist");
    world.convertXPToBling(10);
  }

  function testConvertXPToBlingWithoutToken() public {
    vm.startPrank(alice, alice);
    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();

    vm.startPrank(worldDeployer, worldDeployer);
    WorldMetadata.setToken(address(0));
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("BlingSystem: bling contract not deployed");
    world.convertXPToBling(10);

    vm.stopPrank();
  }

  function testConvertBlingToXPNotEnoughBling() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    vm.expectRevert();
    world.convertBlingToXP(1);

    vm.stopPrank();
  }

  function testConvertBlingToXPWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();

    vm.expectRevert("BlingSystem: player does not exist");
    world.convertBlingToXP(10);
  }

  function testConvertBlingToXPLoggedOff() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    world.convertXPToBling(ExperiencePoints.get(playerEntityId));

    assertTrue(bling.balanceOf(alice) > 0, "Bling balance not set");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "XP not reset");

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    uint256 currntBling = bling.balanceOf(alice);
    vm.expectRevert("BlingSystem: player has no XP to convert");
    world.convertBlingToXP(currntBling);

    vm.stopPrank();
  }

  function testConvertBlingToXPWithoutToken() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    world.convertXPToBling(ExperiencePoints.get(playerEntityId));

    assertTrue(bling.balanceOf(alice) > 0, "Bling balance not set");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "XP not reset");

    vm.startPrank(worldDeployer, worldDeployer);
    WorldMetadata.setToken(address(0));
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("BlingSystem: bling contract not deployed");
    world.convertBlingToXP(10);

    vm.stopPrank();
  }

  function testInvalidCallerMint() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.expectRevert();
    bling.mint(alice, 10);

    vm.stopPrank();
  }

  function testInvalidCallerBurn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(bling.balanceOf(alice) == 0, "Bling balance not 0");
    assertTrue(ExperiencePoints.get(playerEntityId) > 0, "XP not set");

    world.convertXPToBling(ExperiencePoints.get(playerEntityId));

    assertTrue(bling.balanceOf(alice) > 0, "Bling balance not set");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "XP not reset");

    vm.expectRevert();
    bling.burn(alice, 1);

    vm.stopPrank();
  }
}
