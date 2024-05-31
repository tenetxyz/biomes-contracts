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
import { ChestMetadata } from "../src/codegen/tables/ChestMetadata.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChestObjectID, ReinforcedChestObjectID, BedrockChestObjectID, GrassObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

import { IERC165 } from "@latticexyz/store/src/IERC165.sol";
import { IChestTransferHook } from "../src/prototypes/IChestTransferHook.sol";

contract ChestTransferHook is IChestTransferHook {
  function allowTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable returns (bool) {
    bool isWithdrawl = ObjectType.get(dstEntityId) == PlayerObjectID;
    if (msg.value > 0 && isWithdrawl && transferObjectTypeId == DiamondOreObjectID) {
      return true;
    }

    return false;
  }

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IChestTransferHook).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract ChestTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;
  ChestTransferHook chestTransferHook;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
    chestTransferHook = new ChestTransferHook();
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

  function testOwnedChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    vm.startPrank(bob, bob);

    // Try transferring to chest owned by another player
    vm.expectRevert("TransferSystem: Player not authorized to make this transfer");
    world.transfer(playerEntityId2, chestEntityId, inputObjectTypeId1, 1, new bytes(0));

    // Try transfering from chest owned by another player
    vm.expectRevert("TransferSystem: Player not authorized to make this transfer");
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId1, 1, new bytes(0));

    // Try mining the chest
    // Since strength is 0, it should be mined
    world.mine(chestCoord);

    assertTrue(ObjectType.get(chestEntityId) == AirObjectID, "Chest not mined");
    assertTrue(ChestMetadata.getOwner(chestEntityId) == address(0), "Owner set");

    vm.stopPrank();
  }

  function testStrengthenOwnedChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;
    world.strengthenChest(chestEntityId, BedrockObjectID, strengthenAmount);

    assertTrue(ChestMetadata.getStrength(chestEntityId) > 0, "Strength not 0");
    uint8[] memory strengthenObjectTypeIds = ChestMetadata.getStrengthenObjectTypeIds(chestEntityId);
    uint16[] memory strengthenObjectAmounts = ChestMetadata.getStrengthenObjectTypeAmounts(chestEntityId);
    assertTrue(strengthenObjectTypeIds.length == 1, "Strengthen object type ids not set");
    assertTrue(strengthenObjectAmounts.length == 1, "Strengthen object amounts not set");
    assertTrue(strengthenObjectTypeIds[0] == BedrockObjectID, "Strengthen object type ids not set");
    assertTrue(strengthenObjectAmounts[0] == strengthenAmount, "Strengthen object amounts not set");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    vm.startPrank(bob, bob);

    // Try mining the chest
    // Since strength is not 0, it should take multiple mines

    uint256 strengthBefore = ChestMetadata.getStrength(chestEntityId);
    world.mine(chestCoord);
    assertTrue(ChestMetadata.getStrength(chestEntityId) < strengthBefore, "Strength not decreased");
    assertTrue(ObjectType.get(chestEntityId) == BedrockChestObjectID, "Chest mined");

    strengthBefore = ChestMetadata.getStrength(chestEntityId);
    world.mine(chestCoord);
    assertTrue(ChestMetadata.getStrength(chestEntityId) < strengthBefore, "Strength not decreased");
    assertTrue(ObjectType.get(chestEntityId) == BedrockChestObjectID, "Chest mined");

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, MAX_PLAYER_STAMINA);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.mine(chestCoord);
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not decreased");
    assertTrue(ObjectType.get(chestEntityId) == BedrockChestObjectID, "Chest mined");

    // Now the mine will go through
    world.mine(chestCoord);
    assertTrue(ObjectType.get(chestEntityId) == AirObjectID, "Chest not mined");
    assertTrue(ChestMetadata.getOwner(chestEntityId) == address(0), "Owner set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");
    assertTrue(ChestMetadata.lengthStrengthenObjectTypeIds(chestEntityId) == 0, "Strengthen object type ids not set");
    assertTrue(
      ChestMetadata.lengthStrengthenObjectTypeAmounts(chestEntityId) == 0,
      "Strengthen object amounts not set"
    );

    // Check if the added bedrock was dropped
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(
      InventoryCount.get(chestEntityId, BedrockObjectID) == strengthenAmount,
      "Input object not removed from inventory"
    );
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, BedrockObjectID), "Inventory objects not set");

    vm.stopPrank();
  }

  function testStrengthenOwnedChestWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;
    vm.stopPrank();

    vm.expectRevert("ChestSystem: player does not exist");
    world.strengthenChest(chestEntityId, BedrockObjectID, strengthenAmount);

    vm.stopPrank();
  }

  function testStrengthenOwnedChestWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;

    world.logoffPlayer();

    vm.expectRevert("ChestSystem: player isn't logged in");
    world.strengthenChest(chestEntityId, BedrockObjectID, strengthenAmount);

    vm.stopPrank();
  }

  function testStrengthenOwnedChestTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[1] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    world.move(newCoords);

    vm.expectRevert("ChestSystem: player is too far from the chest");
    world.strengthenChest(chestEntityId, BedrockObjectID, strengthenAmount);

    vm.stopPrank();
  }

  function testStrengthenOwnedChestInvalidStrengthType() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ReinforcedOakLumberObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;

    vm.expectRevert("ChestSystem: invalid strengthen object type");
    world.strengthenChest(chestEntityId, ReinforcedOakLumberObjectID, strengthenAmount);

    vm.stopPrank();
  }

  function testStrengthenOwnedChestInvalidChestType() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == address(0), "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;

    vm.expectRevert("ChestSystem: invalid chest object type");
    world.strengthenChest(chestEntityId, BedrockObjectID, strengthenAmount);

    vm.stopPrank();
  }

  function testStrengthenOwnedChestNotEnoughItems() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Strengthen chest
    uint16 strengthenAmount = 5;

    vm.expectRevert("Not enough objects in the inventory");
    world.strengthenChest(chestEntityId, BedrockObjectID, strengthenAmount);

    vm.stopPrank();
  }

  function testOwnedChestWithApprovals() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook not set");
    address chestHookAddress = address(chestTransferHook);
    world.setChestTransferHook(chestEntityId, chestHookAddress);
    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == chestHookAddress, "OnTransferHook not set");

    vm.startPrank(bob, bob);

    // Try transfering from chest owned by another player
    vm.expectRevert("TransferSystem: Player not authorized to make this transfer");
    world.transfer(chestEntityId, playerEntityId2, inputObjectTypeId1, 1, new bytes(0));

    assertTrue(chestHookAddress.balance == 0, "Balance not updated");
    startGasReport("transfer from chest w/ hook");
    world.transfer{ value: 1 ether }(chestEntityId, playerEntityId2, inputObjectTypeId1, 1, new bytes(0));
    endGasReport();
    // ensure balance is updated
    assertTrue(chestHookAddress.balance == 1 ether, "Balance not updated");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 2, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 0, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(!testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    world.mine(chestCoord);

    assertTrue(ObjectType.get(chestEntityId) == AirObjectID, "Chest not mined");
    assertTrue(ChestMetadata.getOwner(chestEntityId) == address(0), "Owner set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");
    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook set");

    vm.stopPrank();
  }

  function testOwnedChestWithApprovalsWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("build bedrock chest");
    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);
    endGasReport();

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook not set");
    address chestHookAddress = address(chestTransferHook);
    vm.stopPrank();

    vm.expectRevert("ChestSystem: player does not exist");
    world.setChestTransferHook(chestEntityId, chestHookAddress);

    vm.stopPrank();
  }

  function testOwnedChestWithApprovalsWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook not set");
    address chestHookAddress = address(chestTransferHook);

    world.logoffPlayer();

    vm.expectRevert("ChestSystem: player isn't logged in");
    world.setChestTransferHook(chestEntityId, chestHookAddress);

    vm.stopPrank();
  }

  function testOwnedChestWithApprovalsTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook not set");
    address chestHookAddress = address(chestTransferHook);

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[1] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    world.move(newCoords);

    vm.expectRevert("ChestSystem: player is too far from the chest");
    world.setChestTransferHook(chestEntityId, chestHookAddress);

    vm.stopPrank();
  }

  function testOwnedChestWithApprovalsNotOwner() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(bob, bob);

    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook not set");
    address chestHookAddress = address(chestTransferHook);

    vm.expectRevert("ChestSystem: player does not own chest");
    world.setChestTransferHook(chestEntityId, chestHookAddress);

    vm.stopPrank();
  }

  function testOwnedChestWithApprovalsWithHookAlreadySet() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(BedrockChestObjectID, chestCoord);

    assertTrue(ChestMetadata.getOwner(chestEntityId) == alice, "Owner not set");
    assertTrue(ChestMetadata.getStrength(chestEntityId) == 0, "Strength not 0");

    // Should be allowed cuz we're the chest owner
    world.transfer(playerEntityId, chestEntityId, inputObjectTypeId1, 1, new bytes(0));
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(chestEntityId, inputObjectTypeId1), "Inventory objects not set");

    assertTrue(ChestMetadata.getOnTransferHook(chestEntityId) == address(0), "OnTransferHook not set");
    address chestHookAddress = address(chestTransferHook);

    world.setChestTransferHook(chestEntityId, chestHookAddress);

    vm.expectRevert("ChestSystem: chest already has a transfer hook");
    world.setChestTransferHook(chestEntityId, chestHookAddress);

    vm.stopPrank();
  }
}
