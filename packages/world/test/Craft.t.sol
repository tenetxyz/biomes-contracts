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
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, AnyLogObjectID, DyeomaticObjectID, WorkbenchObjectID, GrassObjectID, OakLogObjectID, SakuraLogObjectID, OakLumberObjectID, BlueDyeObjectID, BlueOakLumberObjectID, DiamondOreObjectID, DiamondObjectID, WoodenPickObjectID, LilacObjectID, AzaleaObjectID, MagentaDyeObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract CraftTest is MudTest, GasReporter {
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

  function testHandcraftSingleInput() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    uint8 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    startGasReport("handcraft single input");
    world.craft(recipeId, bytes32(0));
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 4, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, outputObjectTypeId), "Inventory objects not set");

    vm.stopPrank();
  }

  function testHandcraftMultipleInput() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = LilacObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 5);
    uint8 inputObjectTypeId2 = AzaleaObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 5);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 5, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 5, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = MagentaDyeObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId1, uint8(5), inputObjectTypeId2, uint8(5), outputObjectTypeId, uint8(10))
    );

    startGasReport("handcraft multiple input");
    world.craft(recipeId, bytes32(0));
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 10, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, outputObjectTypeId), "Inventory objects not set");

    vm.stopPrank();
  }

  function testHandcraftMultipleInputVariations() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = OakLogObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    uint8 inputObjectTypeId2 = SakuraLogObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 3);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 3, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = WoodenPickObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(AnyLogObjectID, uint8(4), outputObjectTypeId, uint8(1)));

    world.craft(recipeId, bytes32(0));

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 1, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, outputObjectTypeId), "Inventory objects not set");

    vm.stopPrank();
  }

  function testHandcraftMultipleInputVariationsNotEnough() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = OakLogObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    uint8 inputObjectTypeId2 = SakuraLogObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 2);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 2, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = WoodenPickObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(AnyLogObjectID, uint8(4), outputObjectTypeId, uint8(1)));

    vm.expectRevert("CraftSystem: not enough logs");
    world.craft(recipeId, bytes32(0));

    vm.stopPrank();
  }

  function testCraftWithStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = OakLumberObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, DyeomaticObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = BlueOakLumberObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId2, uint8(1), inputObjectTypeId1, uint8(1), outputObjectTypeId, uint8(1))
    );

    startGasReport("craft with station");
    world.craft(recipeId, stationEntityId);
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 1, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, outputObjectTypeId), "Inventory objects not set");

    vm.stopPrank();
  }

  function testInvalidStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = OakLumberObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, WorkbenchObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = BlueOakLumberObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId2, uint8(1), inputObjectTypeId1, uint8(1), outputObjectTypeId, uint8(1))
    );

    vm.expectRevert("CraftSystem: wrong station");
    world.craft(recipeId, stationEntityId);

    vm.expectRevert("CraftSystem: wrong station");
    world.craft(recipeId, bytes32(0));

    vm.stopPrank();
  }

  function testPlayerTooFarFromStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = OakLumberObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = BlueDyeObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId2), "Inventory objects not set");

    // build station beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = testGetUniqueEntity();
    ObjectType.set(stationEntityId, DyeomaticObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = BlueOakLumberObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId2, uint8(1), inputObjectTypeId1, uint8(1), outputObjectTypeId, uint8(1))
    );

    VoxelCoord[] memory newCoords = new VoxelCoord[](uint(int(MAX_PLAYER_INFLUENCE_HALF_WIDTH)) + 1);
    for (int16 i = 0; i < MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1; i++) {
      newCoords[uint(int(i))] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + i + 1);
    }
    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    world.setObjectAtCoord(AirObjectID, newCoords);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.move(newCoords);

    vm.expectRevert("Player is too far");
    world.craft(recipeId, stationEntityId);

    vm.stopPrank();
  }

  function testCraftInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    uint8 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");

    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, MAX_PLAYER_INVENTORY_SLOTS - 1);
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS - 1,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    ObjectTypeMetadata.setStackable(OakLumberObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    vm.expectRevert("Inventory is full");
    world.craft(recipeId, bytes32(0));

    vm.stopPrank();
  }

  function testCraftWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    uint8 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.craft(recipeId, bytes32(0));
  }

  function testInvalidRecipe() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    uint8 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = DiamondObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(1)));

    vm.expectRevert("CraftSystem: recipe not found");
    world.craft(recipeId, bytes32(0));

    vm.stopPrank();
  }

  function testInvaidIngredients() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = LilacObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 3);
    uint8 inputObjectTypeId2 = AzaleaObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 3);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 3, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = MagentaDyeObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId1, uint8(5), inputObjectTypeId2, uint8(5), outputObjectTypeId, uint8(10))
    );

    vm.expectRevert("Not enough objects in the inventory");
    world.craft(recipeId, bytes32(0));

    vm.stopPrank();
  }

  function testCraftWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    uint8 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId), "Inventory objects not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.craft(recipeId, bytes32(0));
  }
}
