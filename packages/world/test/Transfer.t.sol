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

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, GRAVITY_DAMAGE } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, BlueDyeObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract TransferTest is MudTest, GasReporter {
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
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y - 1, spawnCoord.z - 1);
    world.move(path);

    spawnCoord = path[0];

    return playerEntityId;
  }

  function testTransferToChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("transfer to chest: 1 object");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    vm.stopPrank();
  }

  function testTransferAlotToChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 99);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 99, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("transfer to chest 99 objects");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId, 99, new bytes(0));
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId) == 99, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId), "Inventory objects not set");

    vm.stopPrank();
  }

  function testTransferToChestWithFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    ObjectTypeMetadata.setStackable(inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 2);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 2, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    ObjectTypeMetadata.setStackable(DiamondOreObjectID, 1);
    testAddToInventoryCount(chestEntityId, ChestObjectID, DiamondOreObjectID, MAX_CHEST_INVENTORY_SLOTS - 1);
    assertTrue(
      InventoryCount.get(chestEntityId, DiamondOreObjectID) == MAX_CHEST_INVENTORY_SLOTS - 1,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(chestEntityId) == MAX_CHEST_INVENTORY_SLOTS - 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("Inventory is full");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 2, new bytes(0));

    vm.stopPrank();
  }

  function testTransferFromChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId2, 1, new bytes(0));

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();

    vm.startPrank(bob, bob);

    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId2), "Inventory objects not set");

    startGasReport("transfer from chest");
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId1, 1, new bytes(0));
    endGasReport();
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId2, 1, new bytes(0));

    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 2, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
  }

  function testTransferWithFullInventoryFromChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId2, 1, new bytes(0));

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();

    vm.startPrank(bob, bob);

    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    // fill up inventory
    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, GrassObjectID, MAX_PLAYER_INVENTORY_SLOTS);
    assertTrue(
      InventoryCount.get(playerEntityId2, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId2) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, GrassObjectID), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(bob, bob);

    vm.expectRevert("Inventory is full");
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId1, 1, new bytes(0));

    vm.stopPrank();
  }

  function testMineChestPickUpDrops() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId2, 1, new bytes(0));

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();

    vm.startPrank(bob, bob);

    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId2), "Inventory objects not set");

    startGasReport("mine chest with items");
    world.mine(chestCoord, new bytes(0));
    endGasReport();

    bytes32 airEntityId = ReversePosition.get(chestCoord.x, chestCoord.y, chestCoord.z);
    assertTrue(airEntityId != bytes32(0), "Air entity not found");
    assertTrue(InventoryCount.get(airEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(airEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(airEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, inputObjectTypeId2), "Inventory objects not set");

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = chestCoord;
    world.move(newCoords);

    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 3, "Inventory slot not set");
    assertTrue(InventoryCount.get(airEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(airEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(airEntityId) == 0, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(airEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
  }

  function testTransferPlayerToPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(bob, bob);

    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    vm.expectRevert("TransferSystem: cannot transfer to non-chest");
    world.transfer(playerEntityId, playerEntityId2, inputObjectTypeId1, 1, new bytes(0));

    vm.stopPrank();
  }

  function testTransferChestTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("TransferSystem: destination out of range");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));

    vm.stopPrank();
  }

  function testTransferWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
  }

  function testTransferSelf() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("TransferSystem: cannot transfer to self");
    world.transfer(playerEntityId, playerEntityId, inputObjectTypeId1, 1, new bytes(0));

    vm.stopPrank();
  }

  function testTransferNotOwnedItems() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(chestEntityId, ChestObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(chestEntityId, ChestObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));

    vm.stopPrank();
  }

  function testTransferInvalidArgs() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(chestEntityId, ChestObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(chestEntityId, ChestObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("Amount must be greater than 0");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 0, new bytes(0));

    vm.stopPrank();
  }

  function testTransferWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));

    vm.stopPrank();
  }
}
