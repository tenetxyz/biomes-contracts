// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { WorldContextConsumerLib } from "@latticexyz/world/src/WorldContext.sol";
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
import { ExperiencePoints } from "../src/codegen/tables/ExperiencePoints.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Chip, ChipData } from "../src/codegen/tables/Chip.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord, VoxelCoordDirectionVonNeumann } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH, GRAVITY_DAMAGE } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChestObjectID, SmartChestObjectID, GrassObjectID, ForceFieldObjectID, ChipObjectID, ChipBatteryObjectID, PipeObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";
import { TransferData, ChipOnTransferData, ChipOnPipeTransferData, PipeTransferData } from "../src/Types.sol";

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { IChestChip } from "../src/prototypes/IChestChip.sol";
import { IForceFieldChip } from "../src/prototypes/IForceFieldChip.sol";

contract TestForceFieldChip is IForceFieldChip {
  constructor(address _biomeWorldAddress) {
    StoreSwitch.setStoreAddress(_biomeWorldAddress);
  }

  function onAttached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    return true;
  }

  function onDetached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    return true;
  }

  function onPowered(bytes32 playerEntityId, bytes32 entityId, uint16 numBattery) external {}

  function onChipHit(bytes32 playerEntityId, bytes32 entityId) external {}

  function onBuild(
    bytes32 forceFieldEntityId,
    bytes32 playerEntityId,
    uint8 objectTypeId,
    VoxelCoord memory coord,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    address player = ReversePlayer.get(playerEntityId);
    if (player == 0x70997970C51812dc3A010C7d01b50e0d17dc79C8) {
      isAllowed = true;
    }

    if (msg.value > 0) {
      return true;
    }

    // else: default is false
  }

  function onMine(
    bytes32 forceFieldEntityId,
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
    return interfaceId == type(IForceFieldChip).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract TestChestChip is IChestChip {
  bytes32 private ownerEntityId;

  constructor(address _biomeWorldAddress) {
    StoreSwitch.setStoreAddress(_biomeWorldAddress);
  }

  function transferToChest(bytes32 callerEntityId, bool isDeposit, PipeTransferData memory pipeTransferData) external {
    bytes32 playerEntityId = Player.get(msg.sender);
    require(playerEntityId == ownerEntityId, "Not the owner");
    IWorld(WorldContextConsumerLib._world()).pipeTransfer(callerEntityId, isDeposit, pipeTransferData);
  }

  function onAttached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    ownerEntityId = playerEntityId;
    return true;
  }

  function onDetached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    ownerEntityId = bytes32(0);
    return true;
  }

  function onPowered(bytes32 playerEntityId, bytes32 entityId, uint16 numBattery) external {}

  function onChipHit(bytes32 playerEntityId, bytes32 entityId) external {}

  function onTransfer(ChipOnTransferData memory transferData) external payable returns (bool isAllowed) {
    if (transferData.callerEntityId == ownerEntityId) {
      return true;
    }

    return false;
  }

  function onPipeTransfer(ChipOnPipeTransferData memory transferData) external payable returns (bool isAllowed) {
    return false;
  }

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IChestChip).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract TestOverflowChestChip is IChestChip {
  bytes32 private ownerEntityId;
  bytes32 private approvedPipeTransferEntityId;

  constructor(address _biomeWorldAddress) {
    StoreSwitch.setStoreAddress(_biomeWorldAddress);
  }

  function transferToChest(bytes32 callerEntityId, bool isDeposit, PipeTransferData memory pipeTransferData) external {
    bytes32 playerEntityId = Player.get(msg.sender);
    require(playerEntityId == ownerEntityId, "Not the owner");
    IWorld(WorldContextConsumerLib._world()).pipeTransfer(callerEntityId, isDeposit, pipeTransferData);
  }

  function setApprovedPipeTransferEntityId(bytes32 entityId) external {
    require(ownerEntityId == Player.get(msg.sender), "Not the owner");
    approvedPipeTransferEntityId = entityId;
  }

  function onAttached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    ownerEntityId = playerEntityId;
    return true;
  }

  function onDetached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    ownerEntityId = bytes32(0);
    return true;
  }

  function onPowered(bytes32 playerEntityId, bytes32 entityId, uint16 numBattery) external {}

  function onChipHit(bytes32 playerEntityId, bytes32 entityId) external {}

  function onTransfer(ChipOnTransferData memory transferData) external payable returns (bool isAllowed) {
    if (transferData.callerEntityId == ownerEntityId) {
      return true;
    }

    return false;
  }

  function onPipeTransfer(ChipOnPipeTransferData memory transferData) external payable returns (bool isAllowed) {
    return approvedPipeTransferEntityId == transferData.callerEntityId;
  }

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IChestChip).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract PipeTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;
  TestChestChip testChestChip;
  TestForceFieldChip testForceFieldChip;
  TestOverflowChestChip testOverflowChestChip;
  function setUp() public override {
    super.setUp();

    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
    testChestChip = new TestChestChip(worldAddress);
    testForceFieldChip = new TestForceFieldChip(worldAddress);
    testOverflowChestChip = new TestOverflowChestChip(worldAddress);
  }

  function setupPlayer() public returns (bytes32) {
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y - 1, spawnCoord.z - 1);
    world.move(path);

    spawnCoord = path[0];

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

  function adminClearCoord(VoxelCoord memory coord) public {
    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 airEntityId = testGetUniqueEntity();
    ObjectType.set(airEntityId, AirObjectID);
    Position.set(airEntityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, airEntityId);
    vm.stopPrank();
  }

  function testPipeTransferSmartChestToSmartChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    startGasReport("pipe transfer from smart chest to smart chest: 1 pipe, 1 object");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest2EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    // transfer back to chest1
    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;

    startGasReport("pipe transfer from smart chest to smart chest: 1 pipe, 1 object");
    testChestChip.transferToChest(
      chest1EntityId,
      false,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();
    assertTrue(InventoryCount.get(chest2EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    world.transfer(chest1EntityId, playerEntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    vm.stopPrank();
  }

  function testPipeTransferSmartChestToSmartChestMultiplePipes() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 3);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    bytes32 chest1EntityId;
    bytes32 chest2EntityId;
    {
      VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory pipeCoord2 = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory pipeCoord3 = VoxelCoord(spawnCoord.x + 4, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 5, spawnCoord.y, spawnCoord.z);
      adminClearCoord(chest1Coord);
      adminClearCoord(pipeCoord);
      adminClearCoord(pipeCoord2);
      adminClearCoord(pipeCoord3);
      adminClearCoord(chest2Coord);
      vm.stopPrank();
      vm.startPrank(alice, alice);

      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);

      assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

      chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
      world.build(PipeObjectID, pipeCoord);
      world.build(PipeObjectID, pipeCoord2);
      world.build(PipeObjectID, pipeCoord3);
      chest2EntityId = world.build(SmartChestObjectID, chest2Coord);
    }

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](3);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;
    path[1] = VoxelCoordDirectionVonNeumann.PositiveX;
    path[2] = VoxelCoordDirectionVonNeumann.PositiveX;

    startGasReport("pipe transfer from smart chest to smart chest: 3 pipes, 1 object");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest2EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    // transfer back to chest1
    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;
    path[1] = VoxelCoordDirectionVonNeumann.NegativeX;
    path[2] = VoxelCoordDirectionVonNeumann.NegativeX;

    startGasReport("pipe transfer from smart chest to smart chest: 3 pipes, 1 object");
    testChestChip.transferToChest(
      chest1EntityId,
      false,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest2EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    world.transfer(chest1EntityId, playerEntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    vm.stopPrank();
  }

  function testPipeTransferSmartChestToChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChestObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(ChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    startGasReport("pipe transfer from smart chest to chest: 1 pipe, 1 object");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest2EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    // transfer back to chest1
    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;

    startGasReport("pipe transfer from chest to smart chest: 1 pipe, 1 object");
    testChestChip.transferToChest(
      chest1EntityId,
      false,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest2EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    world.transfer(chest1EntityId, playerEntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    vm.stopPrank();
  }

  function testPipeTransferSmartChestToForceField() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 forceFieldEntityId;
    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y + 1, spawnCoord.z);
      forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, ChipBatteryObjectID, 3);

    assertTrue(
      InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 26,
      "Input object not removed from inventory"
    );
    assertTrue(InventoryCount.get(chest1EntityId, ChipBatteryObjectID) == 3, "Input object not added to inventory");

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;
    uint256 chargeBefore = Chip.getBatteryLevel(forceFieldEntityId);

    startGasReport("pipe transfer from smart chest to force field: 1 pipe, 3 objects");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: forceFieldEntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: ChipBatteryObjectID,
          numToTransfer: 3,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest1EntityId, ChipBatteryObjectID) == 0, "Input object not removed from inventory");
    uint256 chargeAfter = Chip.getBatteryLevel(forceFieldEntityId);
    assertTrue(chargeAfter > chargeBefore, "Charge not increased");

    vm.stopPrank();
  }

  function testPipeTransferToolsSmartChestToSmartChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    ItemMetadata.set(newInventoryId, 18750);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 8, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transferTool(playerEntityId, chest1EntityId, newInventoryId);

    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, WoodenPickObjectID) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    startGasReport("pipe transfer from smart chest to smart chest: 1 pipe, 1 tool");
    bytes32[] memory toolEntityIds = new bytes32[](1);
    toolEntityIds[0] = newInventoryId;
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: WoodenPickObjectID,
          numToTransfer: 1,
          toolEntityIds: toolEntityIds
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest1EntityId, WoodenPickObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest2EntityId, WoodenPickObjectID) == 1, "Input object not added to inventory");

    // transfer back to chest1
    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;

    startGasReport("pipe transfer from smart chest to smart chest: 1 pipe, 1 tool");
    testChestChip.transferToChest(
      chest1EntityId,
      false,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: WoodenPickObjectID,
          numToTransfer: 1,
          toolEntityIds: toolEntityIds
        }),
        extraData: new bytes(0)
      })
    );
    endGasReport();

    assertTrue(InventoryCount.get(chest2EntityId, WoodenPickObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, WoodenPickObjectID) == 1, "Input object not added to inventory");

    world.transferTool(chest1EntityId, playerEntityId, newInventoryId);

    assertTrue(InventoryCount.get(chest1EntityId, WoodenPickObjectID) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Input object not added to inventory");

    vm.stopPrank();
  }

  function testPipeTransferInvalidTools() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 newInventoryId = testGetUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    InventoryTool.set(newInventoryId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryId);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint24 durability = 18750;
    ItemMetadata.set(newInventoryId, durability);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, WoodenPickObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 8, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    assertTrue(InventoryCount.get(chest1EntityId, WoodenPickObjectID) == 0, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("Entity does not own inventory item");
    bytes32[] memory toolEntityIds = new bytes32[](1);
    toolEntityIds[0] = newInventoryId;
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: WoodenPickObjectID,
          numToTransfer: 1,
          toolEntityIds: toolEntityIds
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferNotAllowed() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: smart item not authorized by chip to make this transfer");
    testOverflowChestChip.transferToChest(
      chest2EntityId,
      false,
      PipeTransferData({
        targetEntityId: chest1EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidObjectToForceField() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    bytes32 chest1EntityId;
    bytes32 forceFieldEntityId;
    {
      VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
      adminClearCoord(chest1Coord);
      adminClearCoord(pipeCoord);
      vm.stopPrank();
      vm.startPrank(alice, alice);

      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y + 1, spawnCoord.z);
      forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);

      assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

      chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
      world.build(PipeObjectID, pipeCoord);
    }

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, ChipBatteryObjectID, 3);
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(
      InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 26,
      "Input object not removed from inventory"
    );
    assertTrue(InventoryCount.get(chest1EntityId, ChipBatteryObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;
    vm.expectRevert("PipeTransferSystem: force field can only accept chip batteries");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: forceFieldEntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidCaller() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: caller is not the chip of the smart item");
    world.pipeTransfer(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;
    vm.expectRevert("PipeTransferSystem: caller is not the chip of the smart item");
    world.pipeTransfer(
      chest2EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest1EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidSrcType() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 2);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");
      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 otherEntityId = world.build(inputObjectTypeId1, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(otherEntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;

    vm.expectRevert("PipeTransferSystem: source object type is not a chest");
    testChestChip.transferToChest(
      otherEntityId,
      true,
      PipeTransferData({
        targetEntityId: chest1EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidCallerNotCharged() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChestObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 forceFieldEntityId;
    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");
      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(ChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Chip.setBatteryLevel(forceFieldEntityId, 0);
    Chip.setLastUpdatedTime(forceFieldEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: caller has no charge");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    // transfer back to chest1
    path[0] = VoxelCoordDirectionVonNeumann.NegativeX;

    vm.expectRevert("PipeTransferSystem: caller has no charge");
    testChestChip.transferToChest(
      chest1EntityId,
      false,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidSelfTransfer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: cannot transfer to self");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest1EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidDstType() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 2);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 otherEntityId = world.build(inputObjectTypeId1, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(otherEntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 1, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: target object type is not valid");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: otherEntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidPath() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 30);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 2);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");
    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 5, spawnCoord.y, spawnCoord.z);
    {
      VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory pipeCoord2 = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
      VoxelCoord memory pipeCoord3 = VoxelCoord(spawnCoord.x + 3, spawnCoord.y + 1, spawnCoord.z);
      VoxelCoord memory pipeCoord4 = VoxelCoord(spawnCoord.x + 4, spawnCoord.y + 1, spawnCoord.z);
      VoxelCoord memory inputCoord = VoxelCoord(spawnCoord.x + 4, spawnCoord.y, spawnCoord.z);
      adminClearCoord(chest1Coord);
      adminClearCoord(pipeCoord);
      adminClearCoord(pipeCoord2);
      adminClearCoord(pipeCoord3);
      adminClearCoord(pipeCoord4);
      adminClearCoord(inputCoord);
      adminClearCoord(chest2Coord);
      vm.stopPrank();
      vm.startPrank(alice, alice);

      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      {
        bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
        assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

        world.attachChip(forceFieldEntityId, address(testForceFieldChip));
        world.powerChip(forceFieldEntityId, 1);
      }

      assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

      world.build(PipeObjectID, pipeCoord);
      world.build(PipeObjectID, pipeCoord2);
      world.build(PipeObjectID, pipeCoord3);
      world.build(PipeObjectID, pipeCoord4);
      world.build(inputObjectTypeId1, inputCoord);
    }

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    // transfer from player to chest
    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](3);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;
    path[1] = VoxelCoordDirectionVonNeumann.PositiveX;
    path[2] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: path must be greater than 0");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: new VoxelCoordDirectionVonNeumann[](0),
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.expectRevert("PipeTransferSystem: path coord is not a pipe");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    path[1] = VoxelCoordDirectionVonNeumann.PositiveY;
    vm.expectRevert("PipeTransferSystem: path coord is not in the world");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    path = new VoxelCoordDirectionVonNeumann[](4);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;
    path[1] = VoxelCoordDirectionVonNeumann.PositiveX;
    path[2] = VoxelCoordDirectionVonNeumann.PositiveY;
    path[3] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("PipeTransferSystem: last path coord is not in von neumann distance of 1 from dstCoord");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidMissingObjects() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");
      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 0, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("Not enough objects in the inventory");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }

  function testPipeTransferInvalidFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    vm.stopPrank();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);

    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 3);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 30);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 2);

    uint8 inputObjectTypeId1 = DiamondOreObjectID;
    testAddToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);
    testAddToInventoryCount(playerEntityId2, PlayerObjectID, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, ForceFieldObjectID) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 3, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, ChipBatteryObjectID) == 30, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, SmartChestObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, PipeObjectID) == 2, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId2, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 7, "Inventory slot not set");
    assertTrue(InventorySlots.get(playerEntityId2) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ForceFieldObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, ChipBatteryObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, SmartChestObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, PipeObjectID), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, inputObjectTypeId1), "Inventory objects not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId2, inputObjectTypeId1), "Inventory objects not set");

    VoxelCoord memory chest1Coord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory pipeCoord = VoxelCoord(spawnCoord.x + 2, spawnCoord.y, spawnCoord.z);
    VoxelCoord memory chest2Coord = VoxelCoord(spawnCoord.x + 3, spawnCoord.y, spawnCoord.z);
    adminClearCoord(chest1Coord);
    adminClearCoord(pipeCoord);
    adminClearCoord(chest2Coord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    {
      VoxelCoord memory forceFieldCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y + 1, spawnCoord.z);
      bytes32 forceFieldEntityId = world.build(ForceFieldObjectID, forceFieldCoord);
      assertTrue(Chip.getChipAddress(forceFieldEntityId) == address(0), "Chip set");

      world.attachChip(forceFieldEntityId, address(testForceFieldChip));
      world.powerChip(forceFieldEntityId, 1);
    }

    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 2, "Input object not removed from inventory");

    bytes32 chest1EntityId = world.build(SmartChestObjectID, chest1Coord);
    world.build(PipeObjectID, pipeCoord);
    bytes32 chest2EntityId = world.build(SmartChestObjectID, chest2Coord);

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(0), "Chip set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(0), "Chip set");

    world.attachChip(chest1EntityId, address(testChestChip));
    world.attachChip(chest2EntityId, address(testOverflowChestChip));

    assertTrue(Chip.getChipAddress(chest1EntityId) == address(testChestChip), "Chip not set");
    assertTrue(Chip.getChipAddress(chest2EntityId) == address(testOverflowChestChip), "Chip not set");
    assertTrue(InventoryCount.get(playerEntityId, ChipObjectID) == 0, "Input object not removed from inventory");

    world.transfer(playerEntityId, chest1EntityId, inputObjectTypeId1, 1);

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chest1EntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");

    testOverflowChestChip.setApprovedPipeTransferEntityId(chest1EntityId);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(chest2EntityId, ChestObjectID, inputObjectTypeId1, MAX_CHEST_INVENTORY_SLOTS * 99);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoordDirectionVonNeumann[] memory path = new VoxelCoordDirectionVonNeumann[](1);
    path[0] = VoxelCoordDirectionVonNeumann.PositiveX;

    vm.expectRevert("Inventory is full");
    testChestChip.transferToChest(
      chest1EntityId,
      true,
      PipeTransferData({
        targetEntityId: chest2EntityId,
        path: path,
        transferData: TransferData({
          objectTypeId: inputObjectTypeId1,
          numToTransfer: 1,
          toolEntityIds: new bytes32[](0)
        }),
        extraData: new bytes(0)
      })
    );

    vm.stopPrank();
  }
}
