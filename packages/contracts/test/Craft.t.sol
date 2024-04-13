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
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, AnyLogObjectID, DyeomaticObjectID, WorkbenchObjectID, GrassObjectID, OakLogObjectID, SakuraLogObjectID, OakLumberObjectID, BlueDyeObjectID, BlueOakLumberObjectID, DiamondOreObjectID, DiamondObjectID, WoodenPickObjectID, LilacObjectID, AzaleaObjectID, MagentaDyeObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testAddToInventoryCount, testReverseInventoryHasItem } from "./utils/InventoryTestUtils.sol";

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
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    assertTrue(getTerrainObjectTypeId(worldAddress, spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y, spawnCoord.z - 1);
    world.move(path);

    spawnCoord = path[0];

    return playerEntityId;
  }

  function testHandcraftSingleInput() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    bytes32 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, inputObjectTypeId);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    bytes32[] memory ingredientEntityIds = new bytes32[](1);
    ingredientEntityIds[0] = newInventoryId;

    startGasReport("handcraft single input");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 4, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    vm.stopPrank();
  }

  function testHandcraftMultipleInput() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory ingredientEntityIds = new bytes32[](10);

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = LilacObjectID;
    for (uint8 i = 0; i < 5; i++) {
      bytes32 newInventoryId = getUniqueEntity();
      ObjectType.set(newInventoryId, inputObjectTypeId1);
      Inventory.set(newInventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, newInventoryId);
      ingredientEntityIds[i] = newInventoryId;
    }
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 5);
    bytes32 inputObjectTypeId2 = AzaleaObjectID;
    for (uint8 i = 0; i < 5; i++) {
      bytes32 newInventoryId = getUniqueEntity();
      ObjectType.set(newInventoryId, inputObjectTypeId2);
      Inventory.set(newInventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, newInventoryId);
      ingredientEntityIds[i + 5] = newInventoryId;
    }
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 5);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 5, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 5, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = MagentaDyeObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId2, uint8(5), inputObjectTypeId1, uint8(5), outputObjectTypeId, uint8(10))
    );

    startGasReport("handcraft multiple input");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 10, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    vm.stopPrank();
  }

  function testHandcraftMultipleInputVariations() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory ingredientEntityIds = new bytes32[](4);

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = OakLogObjectID;
    for (uint8 i = 0; i < 1; i++) {
      bytes32 newInventoryId = getUniqueEntity();
      ObjectType.set(newInventoryId, inputObjectTypeId1);
      Inventory.set(newInventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, newInventoryId);
      ingredientEntityIds[i] = newInventoryId;
    }
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    bytes32 inputObjectTypeId2 = SakuraLogObjectID;
    for (uint8 i = 0; i < 3; i++) {
      bytes32 newInventoryId = getUniqueEntity();
      ObjectType.set(newInventoryId, inputObjectTypeId2);
      Inventory.set(newInventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, newInventoryId);
      ingredientEntityIds[i + 1] = newInventoryId;
    }
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 3);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 3, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = WoodenPickObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(AnyLogObjectID, uint8(4), outputObjectTypeId, uint8(1)));

    world.craft(recipeId, ingredientEntityIds, bytes32(0));

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 1, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    vm.stopPrank();
  }

  function testCraftWithStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory ingredientEntityIds = new bytes32[](2);

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = OakLumberObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId1);
    ingredientEntityIds[0] = newInventoryId1;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = BlueDyeObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    ingredientEntityIds[1] = newInventoryId2;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = getUniqueEntity();
    ObjectType.set(stationEntityId, DyeomaticObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = BlueOakLumberObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId1, uint8(1), inputObjectTypeId2, uint8(1), outputObjectTypeId, uint8(1))
    );

    startGasReport("craft with station");
    world.craft(recipeId, ingredientEntityIds, stationEntityId);
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 1, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    vm.stopPrank();
  }

  function testInvalidStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory ingredientEntityIds = new bytes32[](2);

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = OakLumberObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId1);
    ingredientEntityIds[0] = newInventoryId1;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = BlueDyeObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    ingredientEntityIds[1] = newInventoryId2;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = getUniqueEntity();
    ObjectType.set(stationEntityId, WorkbenchObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = BlueOakLumberObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId1, uint8(1), inputObjectTypeId2, uint8(1), outputObjectTypeId, uint8(1))
    );

    vm.expectRevert("CraftSystem: wrong station");
    world.craft(recipeId, ingredientEntityIds, stationEntityId);

    vm.expectRevert("CraftSystem: wrong station");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));

    vm.stopPrank();
  }

  function testPlayerTooFarFromStation() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory ingredientEntityIds = new bytes32[](2);

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = OakLumberObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId1);
    ingredientEntityIds[0] = newInventoryId1;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = BlueDyeObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    ingredientEntityIds[1] = newInventoryId2;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    // build statin beside player
    VoxelCoord memory stationCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    bytes32 stationEntityId = getUniqueEntity();
    ObjectType.set(stationEntityId, DyeomaticObjectID);
    Position.set(stationEntityId, stationCoord.x, stationCoord.y, stationCoord.z);
    ReversePosition.set(stationCoord.x, stationCoord.y, stationCoord.z, stationEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = BlueOakLumberObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId1, uint8(1), inputObjectTypeId2, uint8(1), outputObjectTypeId, uint8(1))
    );

    vm.expectRevert("CraftSystem: player is too far from the station");
    world.craft(recipeId, ingredientEntityIds, stationEntityId);

    vm.stopPrank();
  }

  function testCraftInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    bytes32 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, inputObjectTypeId);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    for (uint i = 0; i < MAX_PLAYER_INVENTORY_SLOTS - 1; i++) {
      bytes32 inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, GrassObjectID);
      Inventory.set(inventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, inventoryId);
      testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS - 1,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");

    ObjectTypeMetadata.setStackable(OakLumberObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    bytes32[] memory ingredientEntityIds = new bytes32[](1);
    ingredientEntityIds[0] = newInventoryId;

    vm.expectRevert("Inventory is full");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));

    vm.stopPrank();
  }

  function testCraftWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    bytes32 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, inputObjectTypeId);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    bytes32[] memory ingredientEntityIds = new bytes32[](1);
    ingredientEntityIds[0] = newInventoryId;

    vm.stopPrank();

    vm.expectRevert("CraftSystem: player does not exist");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));
  }

  function testInvalidRecipe() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    bytes32 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, inputObjectTypeId);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = DiamondObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(1)));

    bytes32[] memory ingredientEntityIds = new bytes32[](1);
    ingredientEntityIds[0] = newInventoryId;

    vm.expectRevert("CraftSystem: recipe not found");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));

    vm.stopPrank();
  }

  function testInvaidIngredients() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory ingredientEntityIds = new bytes32[](6);

    // Init inventory with ingredients
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = LilacObjectID;
    for (uint8 i = 0; i < 3; i++) {
      bytes32 newInventoryId = getUniqueEntity();
      ObjectType.set(newInventoryId, inputObjectTypeId1);
      Inventory.set(newInventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, newInventoryId);
      ingredientEntityIds[i] = newInventoryId;
    }
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 3);
    bytes32 inputObjectTypeId2 = AzaleaObjectID;
    for (uint8 i = 0; i < 3; i++) {
      bytes32 newInventoryId = getUniqueEntity();
      ObjectType.set(newInventoryId, inputObjectTypeId2);
      Inventory.set(newInventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, newInventoryId);
      ingredientEntityIds[i + 3] = newInventoryId;
    }
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 3);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 3, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = MagentaDyeObjectID;
    bytes32 recipeId = keccak256(
      abi.encodePacked(inputObjectTypeId2, uint8(5), inputObjectTypeId1, uint8(5), outputObjectTypeId, uint8(10))
    );

    vm.expectRevert("CraftSystem: not enough ingredients");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));

    vm.stopPrank();
  }

  function testCraftWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    // Init inventory with ingredients
    bytes32 inputObjectTypeId = OakLogObjectID;
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, inputObjectTypeId);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    bytes32[] memory ingredientEntityIds = new bytes32[](1);
    ingredientEntityIds[0] = newInventoryId;

    world.logoffPlayer();

    vm.expectRevert("CraftSystem: player isn't logged in");
    world.craft(recipeId, ingredientEntityIds, bytes32(0));
  }
}
