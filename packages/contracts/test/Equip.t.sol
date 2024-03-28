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
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, GrassObjectID, ChestObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, OakLumberObjectID, OakLogObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";
import { testAddToInventoryCount, testReverseInventoryHasItem } from "./utils/InventoryTestUtils.sol";

contract EquipTest is MudTest, GasReporter {
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

  function testEquip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("equip");
    world.equip(newInventoryId);
    endGasReport();
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    vm.stopPrank();
  }

  function testEquipNotOwned() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId2);
    ReverseInventory.push(playerEntityId2, newInventoryId);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("EquipSystem: Entity does not own inventory item");
    world.equip(newInventoryId);

    vm.stopPrank();
  }

  function testMineWithEquipped() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    startGasReport("mine terrain w/ equipped");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);
    endGasReport();

    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Inventory count not set for pickaxe");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");
    assertTrue(ItemMetadata.get(newInventoryId) == durability - 1, "Item metadata not set");

    vm.stopPrank();
  }

  function testMineWithEquippedZeroDurability() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 1;
    ItemMetadata.set(newInventoryId, durability);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped set");
    assertTrue(ItemMetadata.get(newInventoryId) == 0, "Item metadata not set");
    assertTrue(Inventory.get(newInventoryId) == bytes32(0), "Inventory not set");
    assertTrue(!testReverseInventoryHasItem(playerEntityId, newInventoryId), "Reverse Inventory not set");

    vm.stopPrank();
  }

  function testCraftIngredientHasEquipped() public {
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

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Item not equipped");

    bytes32 outputObjectTypeId = OakLumberObjectID;
    bytes32 recipeId = keccak256(abi.encodePacked(inputObjectTypeId, uint8(1), outputObjectTypeId, uint8(4)));

    bytes32[] memory ingredientEntityIds = new bytes32[](1);
    ingredientEntityIds[0] = newInventoryId;

    world.craft(recipeId, ingredientEntityIds, bytes32(0));

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Item still equipped");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, outputObjectTypeId) == 4, "Output object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    vm.stopPrank();
  }

  function testDropEquipped() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(testReverseInventoryHasItem(playerEntityId, newInventoryId), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;

    world.drop(inventoryEntityIds, dropCoord);

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped still set");
    assertTrue(ItemMetadata.get(newInventoryId) == durability, "Durability changed");

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId) == airEntityId, "Inventory not set properly");
    assertTrue(testReverseInventoryHasItem(airEntityId, newInventoryId), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(airEntityId, WoodenPickObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testEquippedGravityFatal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    Health.setHealth(playerEntityId, 1);
    Health.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(terrainObjectTypeId, mineCoord);

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped not removed");
    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(PlayerMetadata.getNumMovesInBlock(playerEntityId) == 0, "Player move count not reset");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    vm.stopPrank();
  }

  function testHitWithEquipped() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    uint16 player1HealthBefore = Health.getHealth(playerEntityId);
    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    uint16 player2HealthBefore = Health.getHealth(playerEntityId2);
    uint32 player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    world.hit(bob);

    assertTrue(Health.getHealth(playerEntityId) == player1HealthBefore, "Player 1 health changed");
    assertTrue(Health.getHealth(playerEntityId2) < player2HealthBefore, "Player 2 health did not decrease");

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    uint16 equippedDamage = 50;
    ObjectTypeMetadata.setDamage(WoodenPickObjectID, equippedDamage);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    player1HealthBefore = Health.getHealth(playerEntityId);
    player1StaminaBefore = Stamina.getStamina(playerEntityId);

    player2HealthBefore = Health.getHealth(playerEntityId2);
    player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    startGasReport("hit player with equipped");
    world.hit(bob);
    endGasReport();

    assertTrue(Health.getHealth(playerEntityId) == player1HealthBefore, "Player 1 health changed");
    assertTrue(
      Health.getHealth(playerEntityId2) == player2HealthBefore - equippedDamage,
      "Player 2 health did not decrease"
    );

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.stopPrank();
  }

  function testTransferEquippedToChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory inventoryEntityIds = new bytes32[](2);

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = GrassObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId1);
    inventoryEntityIds[0] = newInventoryId1;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = WoodenPickObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    inventoryEntityIds[1] = newInventoryId2;
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId2, durability);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = getUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId2);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId2, "Equipped not set");

    world.transfer(playerEntityId, chestEntityId, inventoryEntityIds);

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped not removed");
    assertTrue(ItemMetadata.get(newInventoryId2) == durability, "Item metadata not set");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    assertTrue(Inventory.get(newInventoryId1) == chestEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(chestEntityId, newInventoryId1), "Reverse Inventory not set");
    assertTrue(Inventory.get(newInventoryId2) == chestEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(chestEntityId, newInventoryId2), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();
  }

  function testEquipWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();

    vm.expectRevert("EquipSystem: player does not exist");
    world.equip(newInventoryId);
  }

  function testEquipWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.logoffPlayer();

    vm.expectRevert("EquipSystem: player isn't logged in");
    world.equip(newInventoryId);

    vm.stopPrank();
  }
}
