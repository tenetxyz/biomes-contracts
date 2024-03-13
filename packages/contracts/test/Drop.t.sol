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
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, BLOCKS_BEFORE_INCREASE_STAMINA, BLOCKS_BEFORE_INCREASE_HEALTH, GRAVITY_DAMAGE } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";

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

  function testDropSingleTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, GrassObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;

    startGasReport("drop single terrain");
    world.drop(inventoryEntityIds, dropCoord);
    endGasReport();

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropSingleNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, GrassObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");
    bytes32 airEntityId = getUniqueEntity();
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;

    startGasReport("drop single non-terrain");
    world.drop(inventoryEntityIds, dropCoord);
    endGasReport();

    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropMultipleTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, playerEntityId);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](3);
    inventoryEntityIds[0] = newInventoryId1;
    inventoryEntityIds[1] = newInventoryId2;
    inventoryEntityIds[2] = newInventoryId3;

    startGasReport("drop multiple terrain");
    world.drop(inventoryEntityIds, dropCoord);
    endGasReport();

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropMultipleNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, playerEntityId);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");
    bytes32 airEntityId = getUniqueEntity();
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");

    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32[] memory inventoryEntityIds = new bytes32[](3);
    inventoryEntityIds[0] = newInventoryId1;
    inventoryEntityIds[1] = newInventoryId2;
    inventoryEntityIds[2] = newInventoryId3;

    startGasReport("drop multiple non-terrain");
    world.drop(inventoryEntityIds, dropCoord);
    endGasReport();

    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropEquipped() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint32 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
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
    assertTrue(InventoryCount.get(airEntityId, WoodenPickObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testMovePickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, playerEntityId);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](3);
    inventoryEntityIds[0] = newInventoryId1;
    inventoryEntityIds[1] = newInventoryId2;
    inventoryEntityIds[2] = newInventoryId3;

    world.drop(inventoryEntityIds, dropCoord);

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
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
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testMovePickUpDropFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    for (uint i = 0; i < MAX_PLAYER_INVENTORY_SLOTS; i++) {
      bytes32 inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, GrassObjectID);
      Inventory.set(inventoryId, playerEntityId);
      addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32 airEntityId = getUniqueEntity();
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);
    bytes32 droppedEntityId = getUniqueEntity();
    ObjectType.set(droppedEntityId, GrassObjectID);
    Inventory.set(droppedEntityId, airEntityId);
    addToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 1);
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
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

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, playerEntityId);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](3);
    inventoryEntityIds[0] = newInventoryId1;
    inventoryEntityIds[1] = newInventoryId2;
    inventoryEntityIds[2] = newInventoryId3;

    world.drop(inventoryEntityIds, dropCoord);

    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
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
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testGravityPickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    bytes32 newInventoryId = world.mine(terrainObjectTypeId, mineCoord);

    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = mineCoord;

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;

    world.drop(inventoryEntityIds, dropCoord);
    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slots not set correctly");

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    world.move(newCoords);

    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testGravityFatalPickUpDrop() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 2, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    bytes32 newInventoryId1 = world.mine(terrainObjectTypeId, mineCoord2);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId2 = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId2 != AirObjectID, "Terrain block is air");

    bytes32 newInventoryId2 = world.mine(terrainObjectTypeId2, mineCoord);

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, DiamondOreObjectID, 1);
    Health.setHealth(playerEntityId, GRAVITY_DAMAGE + 1);
    Health.setLastUpdateBlock(playerEntityId, block.number);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 3, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = mineCoord;

    bytes32[] memory inventoryEntityIds = new bytes32[](2);
    inventoryEntityIds[0] = newInventoryId1;
    inventoryEntityIds[1] = newInventoryId2;

    world.drop(inventoryEntityIds, dropCoord);
    bytes32 airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId2) == 0, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    world.move(newCoords);

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(PlayerMetadata.getNumMovesInBlock(playerEntityId) == 0, "Player move count not reset");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    // All 3 blocks should be on the air object at mineCoord2
    bytes32 airEntityId2 = ReversePosition.get(mineCoord2.x, mineCoord2.y, mineCoord2.z);
    assertTrue(airEntityId2 != bytes32(0), "Dropped entity not set");
    assertTrue(ObjectType.get(airEntityId2) == AirObjectID, "Dropped object not set");
    assertTrue(Inventory.get(newInventoryId1) == airEntityId2, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId2, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId2, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId2, terrainObjectTypeId) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId2, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId2, DiamondOreObjectID) == 1, "Inventory count not set properly");

    vm.stopPrank();

    vm.startPrank(bob, bob);

    playerEntityId = setupPlayer();

    // move the player to the same location as the dropped items
    world.move(newCoords);

    // player should have picked up all the items
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId2) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 3, "Inventory slots not set correctly");

    vm.stopPrank();
  }

  function testDropNonAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, GrassObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) != AirObjectID, "Terrain block is air");

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;

    vm.expectRevert("InventorySystem: cannot drop on non-air block");
    world.drop(inventoryEntityIds, dropCoord);

    vm.stopPrank();
  }

  function testBuildOnDrops() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);
    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    bytes32 airEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(airEntityId != bytes32(0), "Mined entity not set");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Mined object not set");

    bytes32[] memory dropEntityIds = new bytes32[](1);
    dropEntityIds[0] = inventoryId;
    VoxelCoord memory dropCoord = mineCoord;
    world.drop(dropEntityIds, mineCoord);

    assertTrue(Inventory.get(inventoryId) == airEntityId, "Inventory not unset");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not unset");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not unset");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not unset");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId) == 1, "Inventory count not unset");
    assertTrue(InventorySlots.get(airEntityId) == 1, "Inventory slot not unset");

    mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 2);
    terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    vm.expectRevert("BuildSystem: Cannot build where there are dropped objects");
    world.build(inventoryId, dropCoord);

    vm.stopPrank();
  }

  function testDropWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, GrassObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;
    vm.stopPrank();

    vm.expectRevert("InventorySystem: player does not exist");
    world.drop(inventoryEntityIds, dropCoord);
  }

  function testDropTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, GrassObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slots not set correctly");

    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    assertTrue(world.getTerrainBlock(dropCoord) == AirObjectID, "Terrain block is not air");

    bytes32[] memory inventoryEntityIds = new bytes32[](1);
    inventoryEntityIds[0] = newInventoryId;

    vm.expectRevert("Inventory: player is too far from the drop coord");
    world.drop(inventoryEntityIds, dropCoord);

    vm.stopPrank();
  }

  function testLoginPickUpDrops() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 airEntityId = getUniqueEntity();
    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);

    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, airEntityId);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, airEntityId);
    addToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 2);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, airEntityId);
    addToInventoryCount(airEntityId, AirObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");

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
    assertTrue(Inventory.get(newInventoryId1) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == playerEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == playerEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 0, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 0, "Inventory count not set properly");

    vm.stopPrank();
  }

  function testLoginPickUpDropsFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    world.logoffPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 airEntityId = getUniqueEntity();
    VoxelCoord memory dropCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    Position.set(airEntityId, dropCoord.x, dropCoord.y, dropCoord.z);
    ReversePosition.set(dropCoord.x, dropCoord.y, dropCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);

    ObjectTypeMetadata.setStackable(GrassObjectID, 1);

    for (uint i = 0; i < MAX_PLAYER_INVENTORY_SLOTS; i++) {
      bytes32 inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, GrassObjectID);
      Inventory.set(inventoryId, playerEntityId);
      addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");

    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, airEntityId);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, airEntityId);
    addToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 2);
    bytes32 newInventoryId3 = getUniqueEntity();
    ObjectType.set(newInventoryId3, DiamondOreObjectID);
    Inventory.set(newInventoryId3, airEntityId);
    addToInventoryCount(airEntityId, AirObjectID, DiamondOreObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    assertTrue(Inventory.get(newInventoryId1) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId2) == airEntityId, "Inventory not set properly");
    assertTrue(Inventory.get(newInventoryId3) == airEntityId, "Inventory not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");

    VoxelCoord memory respawnCoord = dropCoord;

    vm.expectRevert("Inventory is full");
    world.loginPlayer(respawnCoord);

    vm.stopPrank();
  }
}
