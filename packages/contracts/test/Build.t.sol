// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
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
import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { ReverseInventory } from "../src/codegen/tables/ReverseInventory.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";

import { ObjectTypeMetadata } from "@biomesaw/terrain/src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "@biomesaw/terrain/src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { getTerrainObjectTypeId } from "../src/utils/TerrainUtils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testAddToInventoryCount, testReverseInventoryHasItem } from "./utils/InventoryTestUtils.sol";
import { TERRAIN_WORLD_ADDRESS } from "../src/Constants.sol";

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
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    assertTrue(getTerrainObjectTypeId(spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y, spawnCoord.z - 1);
    world.move(path);

    spawnCoord = path[0];

    return playerEntityId;
  }

  function testBuildTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);
    assertTrue(inventoryId != bytes32(0), "Inventory entity not found");
    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");
    startGasReport("build terrain");
    world.build(inventoryId, buildCoord);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(inventoryId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == inventoryId,
      "Reverse position not set"
    );
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Object not built");
    assertTrue(Stamina.getStamina(playerEntityId) == staminaBefore, "Stamina consumed");
    assertTrue(Inventory.get(inventoryId) == bytes32(0), "Inventory still set");
    assertTrue(!testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
  }

  function testBuildNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);
    assertTrue(inventoryId != bytes32(0), "Inventory entity not found");
    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    bytes32 mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Terrain block is not air");
    VoxelCoord memory buildCoord = mineCoord;
    startGasReport("build non-terrain");
    world.build(inventoryId, buildCoord);
    endGasReport();

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(inventoryId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == inventoryId,
      "Reverse position not set"
    );
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Object not built");
    assertTrue(Stamina.getStamina(playerEntityId) == staminaBefore, "Stamina consumed");
    assertTrue(Inventory.get(inventoryId) == bytes32(0), "Inventory still set");
    assertTrue(!testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
  }

  function testBuildInsideSpawn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId1);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(SPAWN_LOW_X + 1, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: cannot build at spawn area");
    world.build(newInventoryId1, buildCoord);

    buildCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z + 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: cannot build at spawn area");
    world.build(newInventoryId2, buildCoord);

    vm.stopPrank();
  }

  function testBuildOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, GrassObjectID);
    Inventory.set(newInventoryId1, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId1);
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, GrassObjectID);
    Inventory.set(newInventoryId2, playerEntityId);
    ReverseInventory.push(playerEntityId, newInventoryId2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("BuildSystem: cannot build outside world border");
    VoxelCoord memory buildCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);
    world.build(newInventoryId1, buildCoord);

    vm.stopPrank();
  }

  function testBuildNonAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);
    assertTrue(inventoryId != bytes32(0), "Inventory entity not found");
    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x - 1, spawnCoord.y - 1, spawnCoord.z);
    assertTrue(getTerrainObjectTypeId(buildCoord) != AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: cannot build on terrain non-air block");
    world.build(inventoryId, buildCoord);

    vm.stopPrank();
  }

  function testBuildNonBlock() public {
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

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: object type is not a block");
    world.build(newInventoryId, buildCoord);

    vm.stopPrank();
  }

  function testBuildWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.stopPrank();

    vm.expectRevert("BuildSystem: player does not exist");
    world.build(inventoryId, buildCoord);

    vm.stopPrank();
  }

  function testBuildTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(
      spawnCoord.x - (MAX_PLAYER_BUILD_MINE_HALF_WIDTH + 5),
      spawnCoord.y,
      spawnCoord.z
    );
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("BuildSystem: player is too far from the block");
    world.build(inventoryId, buildCoord);

    vm.stopPrank();
  }

  function testBuildInvalidInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    inventoryId = bytes32(uint256(inventoryId) + 1);
    assertTrue(Inventory.get(inventoryId) == bytes32(0), "Inventory entity found");
    assertTrue(!testReverseInventoryHasItem(playerEntityId, inventoryId), "Reverse Inventory not set");

    vm.expectRevert("BuildSystem: inventory entity does not belong to the player");
    world.build(inventoryId, buildCoord);

    vm.stopPrank();
  }

  function testBuildInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(IStore(TERRAIN_WORLD_ADDRESS), GrassObjectID, 1);
    bytes32 inventoryId;
    for (uint i = 0; i < MAX_PLAYER_INVENTORY_SLOTS; i++) {
      inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, GrassObjectID);
      Inventory.set(inventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, inventoryId);
      testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    vm.stopPrank();

    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");
    startGasReport("build terrain w/ full inventory");
    world.build(inventoryId, buildCoord);
    endGasReport();

    vm.stopPrank();
  }

  function testBuildRegenHealthAndStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

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
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");
    startGasReport("build terrain w/ health and stamina regen");
    world.build(inventoryId, buildCoord);
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
    uint8 terrainObjectTypeId = getTerrainObjectTypeId(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(getTerrainObjectTypeId(buildCoord) == AirObjectID, "Terrain block is not air");

    world.logoffPlayer();

    vm.expectRevert("BuildSystem: player isn't logged in");
    world.build(inventoryId, buildCoord);

    vm.stopPrank();
  }
}
