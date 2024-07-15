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
import { ShardFields } from "../src/codegen/tables/ShardFields.sol";
import { ForceField, ForceFieldData } from "../src/codegen/tables/ForceField.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, TIME_BEFORE_DECREASE_BATTERY_LEVEL, BATTERY_DECREASE_RATE, FORCE_FIELD_SHARD_DIM, FORCE_FIELD_DIM } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChestObjectID, GrassObjectID, ChipObjectID, ChipBatteryObjectID, ForceFieldObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType, getForceField } from "./utils/TestUtils.sol";

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
    bytes32 playerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    address player = ReversePlayer.get(playerEntityId);
    if (player == 0x70997970C51812dc3A010C7d01b50e0d17dc79C8) {
      isAllowed = true;
    }

    // else: default is false
  }

  function onMine(
    bytes32 playerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    address player = ReversePlayer.get(playerEntityId);
    if (player == 0x70997970C51812dc3A010C7d01b50e0d17dc79C8) {
      isAllowed = true;
    }

    // else: default is false
  }

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IChip).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract ForceFieldTest is MudTest, GasReporter {
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

  function testForceField() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);

    assertTrue(getForceField(forceFieldCoord) == bytes32(0), "Force field already exists");

    startGasReport("build force field");
    bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord, new bytes(0));
    endGasReport();

    assertTrue(getForceField(forceFieldCoord) == forceFieldEntityId, "Force field not created");

    // try building grass
    VoxelCoord memory grassCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(grassCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert("Cannot build in force field without chip");
    world.build(GrassObjectID, grassCoord, new bytes(0));

    // Try mining
    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y - 1, spawnCoord.z + 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("mine in force field");
    world.mine(mineCoord, new bytes(0));
    endGasReport();

    bytes32 mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 2, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, terrainObjectTypeId), "Inventory objects not set");
    assertTrue(Stamina.getStamina(playerEntityId) < staminaBefore, "Stamina not decremented");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    // mine force field object

    startGasReport("mine force field");
    world.mine(forceFieldCoord, new bytes(0));
    endGasReport();

    assertTrue(getForceField(forceFieldCoord) == bytes32(0), "Force field still exists");

    bytes32 buildEntityId = world.build(GrassObjectID, grassCoord, new bytes(0));
    assertTrue(ObjectType.get(buildEntityId) == GrassObjectID, "Object not mined");

    vm.stopPrank();
  }

  function testForceFieldOverlap() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, GrassObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 3, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, GrassObjectID), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);

    assertTrue(getForceField(forceFieldCoord) == bytes32(0), "Force field already exists");

    bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord, new bytes(0));
    assertTrue(getForceField(forceFieldCoord) == forceFieldEntityId, "Force field not created");

    // Move FORCE_FIELD_DIM in x direction
    VoxelCoord[] memory path = new VoxelCoord[](uint(int(FORCE_FIELD_DIM / 2)) + 1);
    path[0] = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z + 1);
    for (int16 i = 1; i <= (FORCE_FIELD_DIM / 2); i++) {
      VoxelCoord memory testCoord = VoxelCoord(forceFieldCoord.x + i, forceFieldCoord.y, forceFieldCoord.z);
      path[uint16(i)] = testCoord;
      assertTrue(getForceField(testCoord) == forceFieldEntityId, "Force field already exists");
    }
    world.move(path);

    forceFieldCoord = VoxelCoord(spawnCoord.x + 3 + FORCE_FIELD_DIM / 2, spawnCoord.y + 1, spawnCoord.z);
    assertTrue(getForceField(forceFieldCoord) == bytes32(0), "Force field found");

    vm.expectRevert("Force field overlaps with another force field");
    world.build(ForceFieldObjectID, forceFieldCoord, new bytes(0));

    vm.stopPrank();
  }

  function testForceFieldWithChip() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);

    uint8 inputObjectTypeId1 = GrassObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 4, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
    bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord, new bytes(0));
    assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

    world.attachChip(forceFieldEntityId, address(testChip));
    world.powerChip(forceFieldEntityId, 1);

    assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(testChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // Try building with allowed player

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z + 2);
    assertTrue(getForceField(buildCoord) == forceFieldEntityId, "Force field not found");
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    startGasReport("build in force field with chip");
    bytes32 buildEntityId = world.build(GrassObjectID, buildCoord, new bytes(0));
    endGasReport();

    assertTrue(ObjectType.get(buildEntityId) == GrassObjectID, "Object not built");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    world.mine(buildCoord, new bytes(0));
    uint32 staminaSpent = staminaBefore - Stamina.getStamina(playerEntityId);
    assertTrue(ObjectType.get(buildEntityId) == AirObjectID, "Object not built");
    assertTrue(staminaSpent > 0, "Stamina not spent");

    world.build(GrassObjectID, buildCoord, new bytes(0));
    assertTrue(ObjectType.get(buildEntityId) == GrassObjectID, "Object not built");

    vm.stopPrank();
    vm.startPrank(bob, bob);

    // try building
    vm.expectRevert("Player not authorized by chip to build here");
    world.build(GrassObjectID, VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z + 3), new bytes(0));

    uint32 stamina2Before = Stamina.getStamina(playerEntityId2);
    world.mine(buildCoord, new bytes(0));
    uint32 stamina2Spent = stamina2Before - Stamina.getStamina(playerEntityId2);
    assertTrue(ObjectType.get(buildEntityId) == AirObjectID, "Object not built");

    // It should cost more stamina to non-authorized players
    assertTrue(stamina2Spent > staminaSpent, "Stamina not spent");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(forceFieldEntityId, 1);
    vm.stopPrank();
    vm.startPrank(bob, bob);

    // Mine force field object
    world.hitChip(forceFieldEntityId);
    world.mine(forceFieldCoord, new bytes(0));
    assertTrue(getForceField(forceFieldCoord) == bytes32(0), "Force field still exists");

    // Now build
    buildEntityId = world.build(GrassObjectID, buildCoord, new bytes(0));
    assertTrue(ObjectType.get(buildEntityId) == GrassObjectID, "Object not built");

    vm.stopPrank();
  }
}
