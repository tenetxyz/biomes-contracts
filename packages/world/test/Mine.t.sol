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
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
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
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, NeptuniumCubeObjectID, TextSignObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract MineTest is MudTest, GasReporter {
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

  function testMineTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("mine terrain");
    world.mine(mineCoord);
    endGasReport();

    bytes32 mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(Stamina.getStamina(playerEntityId) < staminaBefore, "Stamina not decremented");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testMineNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);
    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    world.build(terrainObjectTypeId, buildCoord);

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    vm.roll(block.number + 1);

    startGasReport("mine non-terrain");
    world.mine(buildCoord);
    endGasReport();

    bytes32 mineEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(mineEntityId)), buildCoord),
      "Mine position not set"
    );
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(Stamina.getStamina(playerEntityId) < staminaBefore, "Stamina not decremented");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testMineMultiSize() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, TextSignObjectID, 1);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    bytes32 buildEntityId = world.build(TextSignObjectID, buildCoord);

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(buildEntityId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == buildEntityId,
      "Reverse position not set"
    );
    assertTrue(ObjectType.get(buildEntityId) == TextSignObjectID, "Object not built");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, TextSignObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, TextSignObjectID) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    VoxelCoord memory topCoord = VoxelCoord(buildCoord.x, buildCoord.y + 1, buildCoord.z);
    bytes32 topEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    require(topEntityId != bytes32(0), "Top entity not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(topEntityId)), topCoord),
      "Top position not set"
    );
    assertTrue(ObjectType.get(topEntityId) == TextSignObjectID, "Top object not built");
    assertTrue(BaseEntity.get(topEntityId) == buildEntityId, "Top entity not linked");

    startGasReport("mine multi size 2");
    world.mine(buildCoord);
    endGasReport();

    bytes32 mineEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(mineEntityId)), buildCoord),
      "Mine position not set"
    );
    bytes32 mineTopEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    assertTrue(mineTopEntityId != bytes32(0), "Top mine entity not found");
    assertTrue(ObjectType.get(mineTopEntityId) == AirObjectID, "Top object not mined");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(mineTopEntityId)), topCoord),
      "Top mine position not set"
    );
    assertTrue(BaseEntity.get(mineTopEntityId) == bytes32(0), "Top mine entity still linked");
    assertTrue(InventoryCount.get(playerEntityId, TextSignObjectID) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, TextSignObjectID), "Inventory objects not set");

    buildEntityId = world.build(TextSignObjectID, buildCoord);

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(buildEntityId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == buildEntityId,
      "Reverse position not set"
    );
    assertTrue(ObjectType.get(buildEntityId) == TextSignObjectID, "Object not built");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, TextSignObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, TextSignObjectID) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    topEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    require(topEntityId != bytes32(0), "Top entity not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(topEntityId)), topCoord),
      "Top position not set"
    );
    assertTrue(ObjectType.get(topEntityId) == TextSignObjectID, "Top object not built");
    assertTrue(BaseEntity.get(topEntityId) == buildEntityId, "Top entity not linked");

    world.mine(topCoord);

    mineEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(mineEntityId)), buildCoord),
      "Mine position not set"
    );
    mineTopEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    assertTrue(mineTopEntityId != bytes32(0), "Top mine entity not found");
    assertTrue(ObjectType.get(mineTopEntityId) == AirObjectID, "Top object not mined");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(mineTopEntityId)), topCoord),
      "Top mine position not set"
    );
    assertTrue(BaseEntity.get(mineTopEntityId) == bytes32(0), "Top mine entity still linked");
    assertTrue(InventoryCount.get(playerEntityId, TextSignObjectID) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, TextSignObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testMineTooDifficultWithHand() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    world.mine(mineCoord);
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, MAX_PLAYER_STAMINA);
    bytes32 airEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    ObjectType.set(airEntityId, NeptuniumCubeObjectID);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("MineSystem: mining difficulty too high. Try a stronger tool.");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineNonBlock() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.expectRevert("MineSystem: object type is not a block");
    world.mine(spawnCoord);

    vm.stopPrank();
  }

  function testMineAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId == AirObjectID, "Terrain block is air");

    vm.expectRevert("MineSystem: cannot mine air");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineWithoutPlayer() public {
    vm.startPrank(alice, alice);

    VoxelCoord memory mineCoord = VoxelCoord(SPAWN_LOW_X - 1, SPAWN_GROUND_Y - 1, SPAWN_LOW_Z - 1);

    vm.expectRevert("Player does not exist");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineInsideSpawn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(SPAWN_LOW_X + 1, SPAWN_GROUND_Y - 1, SPAWN_LOW_Z);

    vm.expectRevert("MineSystem: cannot mine at spawn area");
    world.mine(mineCoord);

    mineCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z + 1);

    vm.expectRevert("MineSystem: cannot mine at spawn area");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    VoxelCoord memory finalCoord = VoxelCoord(WORLD_BORDER_LOW_X + 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory mineCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.expectRevert("MineSystem: cannot mine outside world border");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(
      spawnCoord.x - (MAX_PLAYER_INFLUENCE_HALF_WIDTH + 5),
      spawnCoord.y - 2,
      spawnCoord.z
    );
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.expectRevert("Player is too far");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineNotEnoughStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 0);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("MineSystem: not enough stamina");
    world.mine(mineCoord);

    vm.stopPrank();
  }

  function testMineInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(terrainObjectTypeId, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, terrainObjectTypeId, MAX_PLAYER_INVENTORY_SLOTS - 1);
    assertTrue(
      InventoryCount.get(playerEntityId, terrainObjectTypeId) == MAX_PLAYER_INVENTORY_SLOTS - 1,
      "Inventory count not set properly"
    );
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(
      InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS - 1,
      "Inventory slots not set correctly"
    );
    vm.stopPrank();

    vm.startPrank(alice, alice);
    startGasReport("final mine to make inventory full");
    world.mine(mineCoord);
    endGasReport();

    VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 2);
    terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.expectRevert("Inventory is full");
    world.mine(mineCoord2);

    vm.stopPrank();
  }

  function testMineRegenHealthAndStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 1);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);

    Health.setHealth(playerEntityId, 1);
    Health.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    uint256 newBlockTime = block.timestamp + ((TIME_BEFORE_INCREASE_STAMINA + TIME_BEFORE_INCREASE_HEALTH + 1) * 100);
    vm.warp(newBlockTime);

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    uint32 healthBefore = Health.getHealth(playerEntityId);

    startGasReport("mine terrain w/ health and stamina regen");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(Stamina.getStamina(playerEntityId) > staminaBefore, "Stamina not regened");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == newBlockTime, "Stamina last update time not set");
    assertTrue(Health.getHealth(playerEntityId) > healthBefore, "Health not regened");
    assertTrue(Health.getLastUpdatedTime(playerEntityId) == newBlockTime, "Health last update time not set");

    vm.stopPrank();
  }

  function testMineWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(SPAWN_LOW_X - 1, SPAWN_GROUND_Y, SPAWN_LOW_Z - 1);

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.mine(mineCoord);

    vm.stopPrank();
  }
}
