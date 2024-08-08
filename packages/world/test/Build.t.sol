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
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";
import { Terrain } from "../src/codegen/tables/Terrain.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract BuildTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;

  function setUp() public override {
    super.setUp();

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

  function testBuildTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    startGasReport("build terrain");
    bytes32 buildEntityId = world.build(terrainObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(buildEntityId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == buildEntityId,
      "Reverse position not set"
    );
    assertTrue(ObjectType.get(buildEntityId) == terrainObjectTypeId, "Object not built");
    assertTrue(Stamina.getStamina(playerEntityId) == staminaBefore, "Stamina consumed");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
  }

  function testBuildNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    bytes32 mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Terrain block is not air");

    vm.startPrank(worldDeployer, worldDeployer);
    Terrain.set(mineCoord.x, mineCoord.y, mineCoord.z, terrainObjectTypeId);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = mineCoord;
    startGasReport("build non-terrain");
    bytes32 buildEntityId = world.build(terrainObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(buildEntityId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == buildEntityId,
      "Reverse position not set"
    );
    assertTrue(Stamina.getStamina(playerEntityId) == staminaBefore, "Stamina consumed");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
  }

  function testBuildInsideSpawn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(SPAWN_LOW_X + 1, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: cannot build at spawn area");
    world.build(GrassObjectID, buildCoord);

    buildCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z + 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: cannot build at spawn area");
    world.build(GrassObjectID, buildCoord);

    vm.stopPrank();
  }

  function testBuildOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("BuildSystem: cannot build outside world border");
    VoxelCoord memory buildCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);
    world.build(GrassObjectID, buildCoord);

    vm.stopPrank();
  }

  function testBuildNonAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x - 1, spawnCoord.y - 1, spawnCoord.z);
    assertTrue(world.getTerrainBlock(buildCoord) != AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: cannot build on terrain non-air block");
    world.build(terrainObjectTypeId, buildCoord);

    vm.stopPrank();
  }

  function testBuildNonBlock() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: object type is not a block");
    world.build(WoodenPickObjectID, buildCoord);

    vm.stopPrank();
  }

  function testBuildWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.build(terrainObjectTypeId, buildCoord);

    vm.stopPrank();
  }

  function testBuildTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(
      spawnCoord.x - (MAX_PLAYER_INFLUENCE_HALF_WIDTH + 5),
      spawnCoord.y,
      spawnCoord.z
    );
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("Player is too far");
    world.build(terrainObjectTypeId, buildCoord);

    vm.stopPrank();
  }

  function testBuildInvalidInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("Not enough objects in the inventory");
    world.build(terrainObjectTypeId, buildCoord);

    vm.stopPrank();
  }

  function testBuildInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, MAX_PLAYER_INVENTORY_SLOTS);
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    vm.stopPrank();

    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    startGasReport("build terrain w/ full inventory");
    world.build(GrassObjectID, buildCoord);
    endGasReport();

    vm.stopPrank();
  }

  function testBuildRegenHealthAndStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 1);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);

    Health.setHealth(playerEntityId, 1);
    Health.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    uint256 newBlockTime = block.timestamp + TIME_BEFORE_INCREASE_STAMINA + TIME_BEFORE_INCREASE_HEALTH + 1;
    vm.warp(newBlockTime);

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    uint32 healthBefore = Health.getHealth(playerEntityId);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    startGasReport("build terrain w/ health and stamina regen");
    world.build(terrainObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(Stamina.getStamina(playerEntityId) > staminaBefore, "Stamina not regened");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == newBlockTime, "Stamina last update time not set");
    assertTrue(Health.getHealth(playerEntityId) > healthBefore, "Health not regened");
    assertTrue(Health.getLastUpdatedTime(playerEntityId) == newBlockTime, "Health last update time not set");

    vm.stopPrank();
  }

  function testBuildWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.build(terrainObjectTypeId, buildCoord);

    vm.stopPrank();
  }
}
