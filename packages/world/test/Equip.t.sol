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
import { AirObjectID, GrassObjectID, ChestObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, OakLumberObjectID, OakLogObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

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

  function testEquip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
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
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId2);
    ReverseInventoryTool.push(playerEntityId2, newInventoryId);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, WoodenPickObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, WoodenPickObjectID), "Inventory objects not set");
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
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    startGasReport("mine terrain w/ equipped");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Inventory count not set for pickaxe");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");
    assertTrue(ItemMetadata.get(newInventoryId) == durability - 1, "Item metadata not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    vm.stopPrank();
  }

  function testMineWithEquippedZeroDurability() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    uint24 durability = 1;
    ItemMetadata.set(newInventoryId, durability);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);

    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped set");
    assertTrue(ItemMetadata.get(newInventoryId) == 0, "Item metadata not set");
    assertTrue(InventoryTool.get(newInventoryId) == bytes32(0), "Inventory not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(!testReverseInventoryToolHasItem(playerEntityId, newInventoryId), "Reverse Inventory not set");

    vm.stopPrank();
  }

  function testDropEquipped() public {
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
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(InventoryTool.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(testReverseInventoryToolHasItem(playerEntityId, newInventoryId), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    world.dropTool(newInventoryId, dropCoord);

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped still set");
    assertTrue(ItemMetadata.get(newInventoryId) == durability, "Durability changed");

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(InventoryTool.get(newInventoryId) == airEntityId, "Inventory not set properly");
    assertTrue(testReverseInventoryToolHasItem(airEntityId, newInventoryId), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(airEntityId, WoodenPickObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testEquippedGravityFatal() public {
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
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");

    Health.setHealth(playerEntityId, 1);
    Health.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint256 xpSupplyBefore = WorldMetadata.getXpSupply();

    world.mine(mineCoord);

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped not removed");
    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "Player xp not reduced to 0");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

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
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
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

    vm.startPrank(worldDeployer, worldDeployer);
    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    uint8 inputObjectTypeId2 = WoodenPickObjectID;
    bytes32 newInventoryId2 = testGetUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    InventoryTool.set(newInventoryId2, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId2);
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId2, durability);
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

    world.equip(newInventoryId2);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId2, "Equipped not set");

    world.transferTool(playerEntityId, chestEntityId, newInventoryId2);
    world.transfer(playerEntityId, chestEntityId, GrassObjectID, 1);

    assertTrue(Equipped.get(playerEntityId) == bytes32(0), "Equipped not removed");
    assertTrue(ItemMetadata.get(newInventoryId2) == durability, "Item metadata not set");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    assertTrue(InventoryTool.get(newInventoryId2) == chestEntityId, "Inventory not set");
    assertTrue(testReverseInventoryToolHasItem(chestEntityId, newInventoryId2), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, WoodenPickObjectID), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, GrassObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testEquipWithoutPlayer() public {
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
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    vm.stopPrank();

    vm.expectRevert("EquipSystem: player does not exist");
    world.equip(newInventoryId);
  }

  function testEquipWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
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
