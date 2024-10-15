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
import { ExperiencePoints } from "../src/codegen/tables/ExperiencePoints.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, NUM_XP_FOR_FULL_BATTERY } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, AnyLogObjectID, DyeomaticObjectID, WorkbenchObjectID, PowerStoneObjectID, ChipBatteryObjectID, GrassObjectID, OakLogObjectID, SakuraLogObjectID, OakLumberObjectID, BlueDyeObjectID, BlueOakLumberObjectID, DiamondOreObjectID, DiamondObjectID, WoodenPickObjectID, LilacObjectID, AzaleaObjectID, MagentaDyeObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract XPTest is MudTest, GasReporter {
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

  function testEarnXP() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    uint256 xpBefore = ExperiencePoints.get(playerEntityId);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);
    uint256 xpAfter = ExperiencePoints.get(playerEntityId);
    assertTrue(xpAfter > xpBefore, "XP not earned");

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    world.build(terrainObjectTypeId, buildCoord);

    assertTrue(ExperiencePoints.get(playerEntityId) > xpAfter, "XP not earned");

    vm.stopPrank();
  }

  function testLogoutXPPenalty() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, 1000);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint256 xpBefore = ExperiencePoints.get(playerEntityId);
    world.logoffPlayer();

    vm.warp(block.timestamp + 1 days);

    // Should not penalize
    world.loginPlayer(spawnCoord);
    assertTrue(ExperiencePoints.get(playerEntityId) == xpBefore, "XP not penalized");

    world.logoffPlayer();

    vm.warp(block.timestamp + 10 days);

    // Should penalize
    world.loginPlayer(spawnCoord);
    assertTrue(ExperiencePoints.get(playerEntityId) < xpBefore, "XP not penalized");

    vm.stopPrank();
  }

  function testXPToBattery() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, NUM_XP_FOR_FULL_BATTERY * 2);

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, PowerStoneObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    uint256 xpBefore = ExperiencePoints.get(playerEntityId);
    world.craftChipBattery(2, stationEntityId);
    assertTrue(ExperiencePoints.get(playerEntityId) == (xpBefore - (NUM_XP_FOR_FULL_BATTERY * 2)), "XP not consumed");

    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 2, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testXPToBatteryNotEnoughXP() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, NUM_XP_FOR_FULL_BATTERY - 10);

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, PowerStoneObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    vm.expectRevert("XPSystem: not enough XP");
    world.craftChipBattery(1, stationEntityId);

    vm.stopPrank();
  }

  function testXPToBatteryInvalidStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, NUM_XP_FOR_FULL_BATTERY * 2);

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, DyeomaticObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    vm.expectRevert("XPSystem: not a power station");
    world.craftChipBattery(2, stationEntityId);

    vm.expectRevert("XPSystem: not a power station");
    world.craftChipBattery(2, bytes32(0));

    vm.stopPrank();
  }

  function testXPToBatteryTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, NUM_XP_FOR_FULL_BATTERY * 2);

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, PowerStoneObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord[] memory newCoords = new VoxelCoord[](uint(int(MAX_PLAYER_INFLUENCE_HALF_WIDTH)) + 1);
    for (int16 i = 0; i < MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1; i++) {
      newCoords[uint(int(i))] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + i + 1);
    }
    world.move(newCoords);

    vm.expectRevert("Player is too far");
    world.craftChipBattery(2, stationEntityId);

    vm.stopPrank();
  }

  function testXPToBatteryWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, NUM_XP_FOR_FULL_BATTERY * 2);

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, PowerStoneObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.craftChipBattery(2, stationEntityId);

    vm.stopPrank();
  }

  function testXPToBatteryLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ExperiencePoints.set(playerEntityId, NUM_XP_FOR_FULL_BATTERY * 2);

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, PowerStoneObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.craftChipBattery(2, stationEntityId);

    vm.stopPrank();
  }
}
