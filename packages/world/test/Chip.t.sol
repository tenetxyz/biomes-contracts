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
import { Chip, ChipData } from "../src/codegen/tables/Chip.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, TIME_BEFORE_DECREASE_BATTERY_LEVEL } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChestObjectID, GrassObjectID, ChipObjectID, ChipBatteryObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { IChip } from "../src/prototypes/IChip.sol";

contract TestChip is IChip {
  function onAttached(bytes32 playerEntityId, bytes32 entityId) external {}

  function onDetached(bytes32 playerEntityId, bytes32 entityId) external {}

  function onPowered(bytes32 playerEntityId, bytes32 entityId, uint16 numBattery) external {}

  function onChipHit(bytes32 playerEntityId, bytes32 entityId) external {}

  function onTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    return true;
  }

  function onBuild(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {}

  function onMine(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {}

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IChip).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract ChipTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;
  TestChip testChip;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
    testChip = new TestChip();
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

  function testAttachChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    startGasReport("attach chip");
    world.attachChip(chestEntityId, address(testChip));
    endGasReport();

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
  }

  function testMineWithChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.expectRevert("MineSystem: chip must be detached first");
    world.mine(chestCoord);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 0);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.detachChip(chestEntityId);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip not removed");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    world.mine(chestCoord);

    assertTrue(ObjectType.get(chestEntityId) == AirObjectID, "Chest not mined");

    vm.stopPrank();
  }

  function testAttachChipAlreadyAttached() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.expectRevert("ChipSystem: chip already attached");
    world.attachChip(chestEntityId, address(testChip));

    vm.stopPrank();
  }

  function testAttachChipInvalidAddress() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    vm.expectRevert("ChipSystem: invalid chip address");
    world.attachChip(chestEntityId, address(0));

    vm.stopPrank();
  }

  function testAttachChipInvalidObject() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 grassEntityId = world.build(GrassObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(grassEntityId) == address(0), "Chip set");

    vm.expectRevert("ChipSystem: cannot attach a chip to this object");
    world.attachChip(grassEntityId, address(0));

    vm.stopPrank();
  }

  function testAttachChipNoChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    vm.expectRevert("Not enough objects in the inventory");
    world.attachChip(chestEntityId, address(testChip));

    vm.stopPrank();
  }

  function testAttachChipWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.attachChip(chestEntityId, address(testChip));

    vm.stopPrank();
  }

  function testAttachChipWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.attachChip(chestEntityId, address(testChip));

    vm.stopPrank();
  }

  function testAttachChipTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[1] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    world.move(newCoords);

    vm.expectRevert("Player is too far");
    world.attachChip(chestEntityId, address(testChip));

    vm.stopPrank();
  }

  function testDetachChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 0);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("detach chip");
    world.detachChip(chestEntityId);
    endGasReport();

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip not removed");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    vm.stopPrank();
  }

  function testDetachChipBatteryLevelNotZero() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 100);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("ChipSystem: battery level is not zero");
    world.detachChip(chestEntityId);

    vm.stopPrank();
  }

  function testDetachChipWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 0);
    vm.stopPrank();
    vm.startPrank(alice, alice);
    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.detachChip(chestEntityId);

    vm.stopPrank();
  }

  function testDetachChipWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 0);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.detachChip(chestEntityId);

    vm.stopPrank();
  }

  function testDetachChipTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 0);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[1] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    world.move(newCoords);

    vm.expectRevert("Player is too far");
    world.detachChip(chestEntityId);

    vm.stopPrank();
  }

  function testDetachChipNoChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    vm.expectRevert("ChipSystem: no chip attached");
    world.detachChip(chestEntityId);

    vm.stopPrank();
  }

  function testPowerChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint256 initialBatteries = InventoryCount.get(playerEntityId, ChipBatteryObjectID);

    startGasReport("power chip");
    world.powerChip(chestEntityId, 10);
    endGasReport();

    uint256 newBatteryLevel = Chip.getBatteryLevel(chestEntityId);

    assertTrue(newBatteryLevel > initialBatteryLevel, "Battery level not increased");
    assertTrue(Chip.getLastUpdatedTime(chestEntityId) == block.timestamp, "Last updated time not set");
    assertTrue(
      InventoryCount.get(playerEntityId, ChipBatteryObjectID) == initialBatteries - 10,
      "Battery not removed from inventory"
    );

    vm.warp(block.timestamp + TIME_BEFORE_DECREASE_BATTERY_LEVEL + 1);
    world.activate(chestEntityId);

    assertTrue(Chip.getBatteryLevel(chestEntityId) < newBatteryLevel, "Battery level not decreased");
    assertTrue(Chip.getLastUpdatedTime(chestEntityId) == block.timestamp, "Last updated time not set");

    vm.stopPrank();
  }

  function testPowerChipWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint256 initialBatteries = InventoryCount.get(playerEntityId, ChipBatteryObjectID);
    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.powerChip(chestEntityId, 10);

    vm.stopPrank();
  }

  function testPowerChipWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint256 initialBatteries = InventoryCount.get(playerEntityId, ChipBatteryObjectID);

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.powerChip(chestEntityId, 10);

    vm.stopPrank();
  }

  function testPowerChipTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint256 initialBatteries = InventoryCount.get(playerEntityId, ChipBatteryObjectID);

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[1] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    world.move(newCoords);

    vm.expectRevert("Player is too far");
    world.powerChip(chestEntityId, 10);

    vm.stopPrank();
  }

  function testPowerChipNoChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    vm.expectRevert("ChipSystem: no chip attached");
    world.powerChip(chestEntityId, 10);

    vm.stopPrank();
  }

  function testPowerChipNotEnoughBatteries() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint256 initialBatteries = InventoryCount.get(playerEntityId, ChipBatteryObjectID);

    vm.expectRevert("Not enough objects in the inventory");
    world.powerChip(chestEntityId, 40);

    vm.stopPrank();
  }

  function testHitChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 100);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint32 playerStaminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("hit chip");
    world.hitChip(chestEntityId);
    endGasReport();

    assertTrue(Chip.getBatteryLevel(chestEntityId) < initialBatteryLevel, "Battery level not decreased");
    assertTrue(Stamina.getStamina(playerEntityId) < playerStaminaBefore, "Player stamina did not decrease");

    vm.stopPrank();
  }

  function testHitChipToDetach() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint32 playerStaminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("hit chip to detach");
    world.hitChip(chestEntityId);
    endGasReport();

    assertTrue(Chip.getBatteryLevel(chestEntityId) == 0, "Battery level not decreased");
    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip not removed");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(Stamina.getStamina(playerEntityId) < playerStaminaBefore, "Player stamina did not decrease");

    vm.stopPrank();
  }

  function testHitChipWithEquipped() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, WoodenPickObjectID), "Inventory objects not set");
    uint24 durability = 10;
    ItemMetadata.set(newInventoryId, durability);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 3, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 1000);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.warp(block.timestamp + TIME_BEFORE_DECREASE_BATTERY_LEVEL + 1);

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint32 playerStaminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("hit chip w/ equipped");
    world.hitChip(chestEntityId);
    endGasReport();

    assertTrue(Chip.getBatteryLevel(chestEntityId) < initialBatteryLevel, "Battery level not decreased");
    assertTrue(Stamina.getStamina(playerEntityId) < playerStaminaBefore, "Player stamina did not decrease");
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");
    assertTrue(ItemMetadata.get(newInventoryId) == durability - 1, "Item metadata not set");

    vm.stopPrank();
  }

  function testHitChipNotEnoughStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 100);
    Stamina.setStamina(playerEntityId, 0);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("ChipSystem: player does not have enough stamina");
    world.hitChip(chestEntityId);

    vm.stopPrank();
  }

  function testHitChipWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 100);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint32 playerStaminaBefore = Stamina.getStamina(playerEntityId);
    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.hitChip(chestEntityId);

    vm.stopPrank();
  }

  function testHitChipWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 100);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint32 playerStaminaBefore = Stamina.getStamina(playerEntityId);

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.hitChip(chestEntityId);

    vm.stopPrank();
  }

  function testHitChipTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    world.attachChip(chestEntityId, address(testChip));

    assertTrue(Chip.getChipAddress(chestEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(chestEntityId, 100);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint256 initialBatteryLevel = Chip.getBatteryLevel(chestEntityId);
    uint32 playerStaminaBefore = Stamina.getStamina(playerEntityId);

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[1] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 2);
    world.move(newCoords);

    vm.expectRevert("Player is too far");
    world.hitChip(chestEntityId);

    vm.stopPrank();
  }

  function testHitChipNoChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");

    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, airEntityId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 chestEntityId = world.build(ChestObjectID, chestCoord);

    assertTrue(Chip.getChipAddress(chestEntityId) == address(0), "Chip set");

    vm.expectRevert("ChipSystem: no chip attached");
    world.hitChip(chestEntityId);

    vm.stopPrank();
  }
}
