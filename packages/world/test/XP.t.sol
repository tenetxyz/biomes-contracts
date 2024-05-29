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
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, MAX_PLAYER_RESPAWN_HALF_WIDTH, MIN_TIME_BEFORE_AUTO_LOGOFF, INITIAL_PLAYER_XP } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, BlueDyeObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { burnTestXP, mintTestXP, testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract XPTest is MudTest, GasReporter {
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

  function testLockChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(ExperiencePoints.get(playerEntityId) == 10, "XP not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 0, "XP not set");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == address(0), "Owner not set");

    uint256 xpSupplyBefore = WorldMetadata.getXpSupply();

    startGasReport("lock chest");
    world.transferXP(chestEntityId, 10);
    endGasReport();

    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "XP not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 10, "XP not set");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    // Should be a allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    vm.startPrank(bob, bob);
    // Try transferring to chest owned by another player
    vm.expectRevert("TransferSystem: cannot transfer to/from a locked block");
    world.transfer(playerEntityId2, chestEntityId, inputObjectTypeId1, 1);

    // Try transfering from chest owned by another player
    vm.expectRevert("TransferSystem: cannot transfer to/from a locked block");
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId1, 1);

    // Try mining the chest
    vm.expectRevert("MineSystem: cannot mine a locked block");
    world.mine(chestCoord);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    world.mine(chestCoord);

    assertTrue(ObjectType.get(chestEntityId) == AirObjectID, "Chest not mined");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == address(0), "Owner not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 0, "XP not set");

    vm.stopPrank();
  }

  function testUnlockLockedChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);
    burnTestXP(playerEntityId2, ExperiencePoints.get(playerEntityId2) - 10);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = testGetUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    assertTrue(ExperiencePoints.get(playerEntityId) == 10, "XP not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 0, "XP not set");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == address(0), "Owner not set");

    uint256 xpSupplyBefore = WorldMetadata.getXpSupply();

    world.transferXP(chestEntityId, 5);

    assertTrue(ExperiencePoints.get(playerEntityId) == 5, "XP not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 5, "XP not set");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    // Should be a allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    vm.startPrank(bob, bob);

    xpSupplyBefore = WorldMetadata.getXpSupply();

    // Transfer XP to unlock chest
    startGasReport("unlock chest");
    world.transferXP(chestEntityId, 5);
    endGasReport();

    assertTrue(ExperiencePoints.get(chestEntityId) == 0, "XP not set");
    assertTrue(ExperiencePoints.get(playerEntityId2) == 5, "XP not set");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == address(0), "Owner not set");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    // Should be a allowed cuz the chest is unlocked now
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId1, 1);
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 2, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 0, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    // Mine the chest
    world.mine(chestCoord);

    // Assert chest is mined
    assertTrue(ObjectType.get(chestEntityId) == AirObjectID, "Chest not mined");

    // Rebuild chest
    world.build(ChestObjectID, chestCoord);

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId2, ExperiencePoints.get(playerEntityId2) - 5);
    vm.stopPrank();
    vm.startPrank(bob, bob);

    assertTrue(ObjectType.get(chestEntityId) == ChestObjectID, "Chest not rebuilt");
    assertTrue(ExperiencePoints.get(playerEntityId2) == 5, "XP not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 0, "XP not set");

    xpSupplyBefore = WorldMetadata.getXpSupply();

    // lock chest
    world.transferXP(chestEntityId, 5);

    assertTrue(ExperiencePoints.get(playerEntityId2) == 0, "XP not set");
    assertTrue(ExperiencePoints.get(chestEntityId) == 5, "XP not set");
    assertTrue(BlockMetadata.getOwner(chestEntityId) == bob, "Owner not set");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    vm.stopPrank();
  }

  function testTransferXPTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);

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

    vm.expectRevert("XPSystem: destination out of range");
    world.transferXP(chestEntityId, 10);

    vm.stopPrank();
  }

  function testTransferWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);

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

    vm.expectRevert("XPSystem: player does not exist");
    world.transferXP(chestEntityId, 10);
  }

  function testTransferNonChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);

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

    vm.expectRevert("XPSystem: cannot transfer to non-chest");
    world.transferXP(playerEntityId, 10);

    vm.stopPrank();
  }

  function testTransferNotEnoughXP() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);

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

    vm.expectRevert("player does not have enough xp");
    world.transferXP(chestEntityId, 20);

    vm.stopPrank();
  }

  function testTransferWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 10);

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

    vm.expectRevert("XPSystem: player isn't logged in");
    world.transferXP(chestEntityId, 10);

    vm.stopPrank();
  }

  function testEnforceLogoutPenalty() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    Health.setHealth(playerEntityId, 1);
    Stamina.setStamina(playerEntityId, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint16 healthBefore = Health.getHealth(playerEntityId);
    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    vm.stopPrank();

    vm.startPrank(bob, bob);

    uint256 xpSupplyBefore = WorldMetadata.getXpSupply();

    startGasReport("enforceLogoutPenalty");
    world.enforceLogoutPenalty(alice, respawnCoord);
    endGasReport();

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "Player xp not reduced to 0");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyNonTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    Health.setHealth(playerEntityId, 1);
    Stamina.setStamina(playerEntityId, 1);

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    bytes32 entityId = testGetUniqueEntity();
    Position.set(entityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition.set(respawnCoord.x, respawnCoord.y, respawnCoord.z, entityId);
    ObjectType.set(entityId, AirObjectID);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint16 healthBefore = Health.getHealth(playerEntityId);
    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    uint256 xpBefore = ExperiencePoints.get(playerEntityId);

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    vm.stopPrank();

    vm.startPrank(bob, bob);

    uint256 xpSupplyBefore = WorldMetadata.getXpSupply();

    startGasReport("enforceLogoutPenalty non-terrain");
    world.enforceLogoutPenalty(alice, respawnCoord);
    endGasReport();

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "Player xp not reduced to 0");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyWithDrops() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);

    Health.setHealth(playerEntityId, 1);
    Stamina.setStamina(playerEntityId, 1);

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    bytes32 airEntityId = testGetUniqueEntity();
    Position.set(airEntityId, respawnCoord.x, respawnCoord.y, respawnCoord.z);
    ReversePosition.set(respawnCoord.x, respawnCoord.y, respawnCoord.z, airEntityId);
    ObjectType.set(airEntityId, AirObjectID);

    testAddToInventoryCount(airEntityId, AirObjectID, GrassObjectID, 2);
    testAddToInventoryCount(airEntityId, AirObjectID, DiamondOreObjectID, 1);
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, GrassObjectID) == 2, "Inventory count not set properly");
    assertTrue(InventoryCount.get(airEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(airEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint16 healthBefore = Health.getHealth(playerEntityId);
    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    uint256 xpBefore = ExperiencePoints.get(playerEntityId);

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    vm.stopPrank();

    vm.startPrank(bob, bob);

    uint256 xpSupplyBefore = WorldMetadata.getXpSupply();

    startGasReport("enforceLogoutPenalty non-terrain w/ drops");
    world.enforceLogoutPenalty(alice, respawnCoord);
    endGasReport();

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "Player xp not reduced to 0");
    assertTrue(WorldMetadata.getXpSupply() < xpSupplyBefore, "World xp supply not reduced");

    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 4, "Inventory count not set properly");
    assertTrue(InventoryCount.get(playerEntityId, DiamondOreObjectID) == 1, "Inventory count not set properly");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, DiamondOreObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    vm.stopPrank();

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    vm.expectRevert("XPSystem: player does not exist");
    world.enforceLogoutPenalty(bob, respawnCoord);

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyFromStale() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId));
    Health.setHealth(playerEntityId, 1);
    Stamina.setStamina(playerEntityId, 1);
    vm.stopPrank();
    vm.startPrank(bob, bob);

    vm.warp(block.timestamp + MIN_TIME_BEFORE_AUTO_LOGOFF + 1);
    world.logoffStalePlayer(alice);

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);

    assertTrue(WorldMetadata.getXpSupply() == 0, "World xp supply not reduced");

    world.enforceLogoutPenalty(alice, respawnCoord);

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");
    assertTrue(ExperiencePoints.get(playerEntityId) == 0, "Player xp not reduced to 0");
    assertTrue(WorldMetadata.getXpSupply() == 0, "World xp supply not reduced");

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyLoggedIn() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    vm.expectRevert("XPSystem: player already logged in");
    world.enforceLogoutPenalty(alice, respawnCoord);

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyInvalidRespawnCoordNotAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory respawnCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    assertTrue(world.getTerrainBlock(respawnCoord) != AirObjectID, "Terrain block is air");

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    vm.expectRevert("XPSystem: cannot respawn on terrain non-air block");
    world.enforceLogoutPenalty(alice, respawnCoord);

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyInvalidRespawnCoordTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    VoxelCoord memory respawnCoord = VoxelCoord(
      spawnCoord.x,
      spawnCoord.y,
      spawnCoord.z + (MAX_PLAYER_RESPAWN_HALF_WIDTH + 1)
    );
    assertTrue(world.getTerrainBlock(respawnCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("XPSystem: respawn coord too far from last known position");
    world.enforceLogoutPenalty(alice, respawnCoord);

    vm.stopPrank();
  }

  function testEnforceLogoutPenaltyInvalidRespawnCoordOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    burnTestXP(playerEntityId, ExperiencePoints.get(playerEntityId) - 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.logoffPlayer();

    uint256 newBlockTime = block.timestamp + 60;
    vm.warp(newBlockTime);

    VoxelCoord memory respawnCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);

    vm.expectRevert("XPSystem: cannot respawn outside world border");
    world.enforceLogoutPenalty(alice, respawnCoord);

    vm.stopPrank();
  }
}
