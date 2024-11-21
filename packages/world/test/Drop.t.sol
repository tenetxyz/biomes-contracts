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
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, GRAVITY_DAMAGE } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract DropTest is MudTest, GasReporter {
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

  function testDropSingleTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    startGasReport("drop single terrain");
    world.drop(GrassObjectID, 1, dropCoord);
    endGasReport();

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropSingleNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");
    bytes32 airEntityId = testGetUniqueEntity();
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("drop single non-terrain");
    world.drop(GrassObjectID, 1, dropCoord);
    endGasReport();

    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropMultipleTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 99);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 99, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    startGasReport("drop multiple terrain");
    world.drop(GrassObjectID, 99, dropCoord);
    endGasReport();

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 99, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropMultipleNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 99);

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");
    bytes32 airEntityId = testGetUniqueEntity();
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");

    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 99, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("drop multiple non-terrain");
    world.drop(GrassObjectID, 99, dropCoord);
    endGasReport();

    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 99, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testMovePickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    world.drop(GrassObjectID, 2, dropCoord);
    world.drop(DiamondOreObjectID, 1, dropCoord);

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = dropCoord;

    startGasReport("move pick up multiple drops");
    world.move(newCoords);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), dropCoord),
      "Player did not move to new coords"
    );
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testMovePickUpDropFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, MAX_PLAYER_INVENTORY_SLOTS);
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32 airEntityId = testGetUniqueEntity();
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);
    testAddToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 1);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    vm.stopPrank();

    vm.startPrank(alice, alice);

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = dropCoord;

    vm.expectRevert("Inventory is full");
    world.move(newCoords);

    vm.stopPrank();
  }

  function testMoveMultiplePickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    world.drop(GrassObjectID, 2, dropCoord);
    world.drop(DiamondOreObjectID, 1, dropCoord);

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    VoxelCoord[] memory newCoords = new VoxelCoord[](3);
    newCoords[0] = dropCoord;
    newCoords[1] = VoxelCoord(dropCoord.x, dropCoord.y, dropCoord.z + 1);
    newCoords[2] = VoxelCoord(dropCoord.x, dropCoord.y, dropCoord.z + 2);

    world.move(newCoords);

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), newCoords[2]),
      "Player did not move to new coords"
    );

    // assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    // assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");
    // assertTrue(!testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    // assertTrue(!testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    // assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    // assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    // Note: we don't allow drops to be picked up that are in between during a move
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  // function testTeleportPickUpDrop() public {
  //   vm.startPrank(alice, alice);

  //   bytes32 playerEntityId = setupPlayer();

  //   vm.roll(block.number + 1);

  //   vm.startPrank(worldDeployer, worldDeployer);
  //   testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
  //   testAddToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
  //   vm.stopPrank();
  //   vm.startPrank(alice, alice);
  //   assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
  //   assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
  //   assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");
  //   assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

  //   VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
  //   assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

  //   world.drop(GrassObjectID, 2, dropCoord);
  //   world.drop(DiamondOreObjectID, 1, dropCoord);

  //   bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
  //   assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
  //   assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
  //   assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
  //   assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
  //   assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
  //   assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
  //   assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");
  //   assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

  //   VoxelCoord memory newCoord = dropCoord;

  //   startGasReport("teleport pick up multiple drops");
  //   world.teleport(newCoord);
  //   endGasReport();

  //   assertTrue(
  //     voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), dropCoord),
  //     "Player did not move to new coords"
  //   );
  //   assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
  //   assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
  //   assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");
  //   assertTrue(!testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
  //   assertTrue(!testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
  //   assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
  //   assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

  //   vm.stopPrank();
  // }

  // function testTeleportPickUpDropFullInventory() public {
  //   vm.startPrank(alice, alice);

  //   bytes32 playerEntityId = setupPlayer();

  //   vm.roll(block.number + 1);

  //   vm.startPrank(worldDeployer, worldDeployer);
  //   ObjectTypeMetadata.setStackable(GrassObjectID, 1);
  //   testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, MAX_PLAYER_INVENTORY_SLOTS);
  //   assertTrue(
  //     InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
  //     "Inventory count not set properly"
  //   );
  //   assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
  //   assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

  //   VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
  //   assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

  //   bytes32 airEntityId = testGetUniqueEntity();
  //   Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
  //   ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
  //   ObjectType.set(airEntityId, AirObjectID);
  //   testAddToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 1);
  //   assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
  //   assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
  //   vm.stopPrank();

  //   vm.startPrank(alice, alice);

  //   VoxelCoord memory newCoord = dropCoord;

  //   vm.expectRevert("Inventory is full");
  //   world.teleport(newCoord);

  //   vm.stopPrank();
  // }

  function testGravityPickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);

    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = mineCoord;

    world.drop(GrassObjectID, 1, dropCoord);
    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    assertTrue(world.getTerrainBlock(newCoords[0]) == AirObjectID, "Terrain block is not air");

    world.move(newCoords);

    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testGravityFatalPickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 2, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord2);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId2 = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId2 != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    Health.setHealth(playerEntityId, GRAVITY_DAMAGE + 1);
    Health.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 3, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = mineCoord;

    world.drop(terrainObjectTypeId, 1, dropCoord);
    world.drop(terrainObjectTypeId2, 1, dropCoord);

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId2) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, terrainObjectTypeId2), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId2), "Inventory objects not set");

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    assertTrue(world.getTerrainBlock(newCoords[0]) == AirObjectID, "Terrain block is not air");

    vm.roll(block.number + 1);

    vm.expectRevert("MoveSystem: cannot move player with gravity");
    world.move(newCoords);

    // assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    // assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    // assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    // assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    // assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    // // All 3 blocks should be on the air object at mineCoord2
    // bytes32 airEntityId2 = ReversePosition.get(mineCoord2.x, mineCoord2.y, mineCoord2.z);
    // assertTrue(airEntityId2 != bytes32(0), "Dropped entity not set");
    // assertTrue(ObjectType.get(airEntityId2) == AirObjectID, "Dropped object not set");
    // assertTrue(InventoryCount.get(airEntityId2, terrainObjectTypeId) == 1, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(airEntityId2, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(airEntityId2, DiamondOreObjectID) == 1, "Inventory count not set properly");
    // assertTrue(testInventoryObjectsHasObjectType(airEntityId2, terrainObjectTypeId), "Inventory objects not set");
    // assertTrue(testInventoryObjectsHasObjectType(airEntityId2, terrainObjectTypeId2), "Inventory objects not set");
    // assertTrue(testInventoryObjectsHasObjectType(airEntityId2, DiamondOreObjectID), "Inventory objects not set");

    // assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    // assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId2), "Inventory objects not set");
    // assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    // vm.stopPrank();

    // vm.startPrank(bob, bob);

    // playerEntityId = setupPlayer();

    // // move the player to the same location as the dropped items
    // vm.roll(block.number + 1);

    // world.move(newCoords);

    // // player should have picked up all the items
    // assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    // assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    // assertTrue(InventorySlots.get(playerEntityId) == 3, "Inventory slots not set correctly");
    // assertTrue(!testInventoryObjectsHasObjectType(airEntityId2, terrainObjectTypeId), "Inventory objects not set");
    // assertTrue(!testInventoryObjectsHasObjectType(airEntityId2, terrainObjectTypeId2), "Inventory objects not set");
    // assertTrue(!testInventoryObjectsHasObjectType(airEntityId2, DiamondOreObjectID), "Inventory objects not set");

    // assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    // assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId2), "Inventory objects not set");
    // assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testDropNonAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) != AirObjectID, "Terrain block is air");

    vm.expectRevert("DropSystem: cannot drop on non-air block");
    world.drop(GrassObjectID, 1, dropCoord);

    vm.stopPrank();
  }

  function testBuildOnDrops() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    bytes32 airEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(airEntityId != bytes32(0), "Mined entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Mined object not set");

    VoxelCoord memory dropCoord = mineCoord;
    world.drop(terrainObjectTypeId, 1, mineCoord);

    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not unset");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not unset");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId) == 1, "Inventory count not unset");
    assertTrue(InventorySlots.get(airEntityId) == 1, "Inventory slot not unset");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 2);
    terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);

    vm.expectRevert("BuildSystem: Cannot build where there are dropped objects");
    world.build(terrainObjectTypeId, dropCoord);

    vm.stopPrank();
  }

  function testDropWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.drop(GrassObjectID, 1, dropCoord);
  }

  function testDropTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(
      spawnCoord.x,
      spawnCoord.y,
      spawnCoord.z + MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1
    );
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("Player is too far");
    world.drop(GrassObjectID, 1, dropCoord);

    vm.stopPrank();
  }

  function testLoginPickUpDrops() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 airEntityId = testGetUniqueEntity();
    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);

    testAddToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 2);
    testAddToInventoryCount(airEntityId, AirObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");

    VoxelCoord memory respawnCoord = dropCoord;
    world.loginPlayer(respawnCoord);

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), respawnCoord),
      "Player position not set"
    );
    assertTrue(
      ReversePosition.get(respawnCoord.x, respawnCoord.y, respawnCoord.z) == playerEntityId,
      "Reverse position not set"
    );
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testSpawnPickUpDrops() public {
    vm.startPrank(worldDeployer, worldDeployer);
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);

    bytes32 airEntityId = testGetUniqueEntity();
    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);

    testAddToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 2);
    testAddToInventoryCount(airEntityId, AirObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");

    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), spawnCoord),
      "Player position not set"
    );
    assertTrue(
      ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z) == playerEntityId,
      "Reverse position not set"
    );
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testLoginPickUpDropsFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 airEntityId = testGetUniqueEntity();
    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);

    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, MAX_PLAYER_INVENTORY_SLOTS);
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    testAddToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 2);
    testAddToInventoryCount(airEntityId, AirObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");

    VoxelCoord memory respawnCoord = dropCoord;

    vm.expectRevert("Inventory is full");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }

  function testDropWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.drop(GrassObjectID, 1, dropCoord);
  }

  function testDropInvalidArgs() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("Amount must be greater than 0");
    world.drop(GrassObjectID, 0, dropCoord);
  }

  function testDropOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    VoxelCoord memory dropCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);

    vm.expectRevert("DropSystem: cannot drop outside world border");
    world.drop(GrassObjectID, 1, dropCoord);
  }
}
