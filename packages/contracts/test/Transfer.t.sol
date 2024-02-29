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
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, MAX_CHEST_INVENTORY_SLOTS, BLOCKS_BEFORE_INCREASE_STAMINA, BLOCKS_BEFORE_INCREASE_HEALTH, GRAVITY_DAMAGE } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, ChestObjectID, BlueDyeObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";

contract TransferTest is MudTest, GasReporter {
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
    spawnCoord = VoxelCoord(197, 27, 203);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    return world.spawnPlayer(spawnCoord);
  }

  function testTransferToChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory inventoryEntityIds = new bytes32[](2);

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = GrassObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    inventoryEntityIds[0] = newInventoryId1;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = BlueDyeObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    inventoryEntityIds[1] = newInventoryId2;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
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

    startGasReport("transfer to chest");
    world.transfer(playerEntityId, chestEntityId, inventoryEntityIds);
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    assertTrue(Inventory.get(newInventoryId1) == chestEntityId, "Inventory not set");
    assertTrue(Inventory.get(newInventoryId2) == chestEntityId, "Inventory not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");

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
    inventoryEntityIds[0] = newInventoryId1;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = WoodenPickObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    inventoryEntityIds[1] = newInventoryId2;
    uint16 durability = 10;
    ItemMetadata.set(newInventoryId2, durability);
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
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
    assertTrue(Inventory.get(newInventoryId2) == chestEntityId, "Inventory not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();
  }

  function testTransferToChestWithFullInventory() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory inventoryEntityIds = new bytes32[](2);

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = GrassObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    inventoryEntityIds[0] = newInventoryId1;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = BlueDyeObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    inventoryEntityIds[1] = newInventoryId2;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 1, "Input object not added to inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 1, "Input object not added to inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");

    // build chest beside player
    VoxelCoord memory chestCoord = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z);
    bytes32 chestEntityId = getUniqueEntity();
    ObjectType.set(chestEntityId, ChestObjectID);
    Position.set(chestEntityId, chestCoord.x, chestCoord.y, chestCoord.z);
    ReversePosition.set(chestCoord.x, chestCoord.y, chestCoord.z, chestEntityId);

    ObjectTypeMetadata.setStackable(DiamondOreObjectID, 1);
    for (uint i = 0; i < MAX_CHEST_INVENTORY_SLOTS - 1; i++) {
      bytes32 inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, DiamondOreObjectID);
      Inventory.set(inventoryId, chestEntityId);
      addToInventoryCount(chestEntityId, ChestObjectID, DiamondOreObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(chestEntityId, DiamondOreObjectID) == MAX_CHEST_INVENTORY_SLOTS - 1,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(chestEntityId) == MAX_CHEST_INVENTORY_SLOTS - 1, "Inventory slots not set correctly");

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert();
    world.transfer(playerEntityId, chestEntityId, inventoryEntityIds);

    vm.stopPrank();
  }

  function testTransferFromChest() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32[] memory inventoryEntityIds = new bytes32[](2);

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 inputObjectTypeId1 = GrassObjectID;
    bytes32 newInventoryId1 = getUniqueEntity();
    ObjectType.set(newInventoryId1, inputObjectTypeId1);
    Inventory.set(newInventoryId1, playerEntityId);
    inventoryEntityIds[0] = newInventoryId1;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId1, 1);

    bytes32 inputObjectTypeId2 = BlueDyeObjectID;
    bytes32 newInventoryId2 = getUniqueEntity();
    ObjectType.set(newInventoryId2, inputObjectTypeId2);
    Inventory.set(newInventoryId2, playerEntityId);
    inventoryEntityIds[1] = newInventoryId2;
    addToInventoryCount(playerEntityId, PlayerObjectID, inputObjectTypeId2, 1);
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

    startGasReport("transfer to chest");
    world.transfer(playerEntityId, chestEntityId, inventoryEntityIds);
    endGasReport();

    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId1) == 0, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(playerEntityId, inputObjectTypeId2) == 0, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    assertTrue(Inventory.get(newInventoryId1) == chestEntityId, "Inventory not set");
    assertTrue(Inventory.get(newInventoryId2) == chestEntityId, "Inventory not set");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId1) == 1, "Input object not removed from inventory");
    assertTrue(InventoryCount.get(chestEntityId, inputObjectTypeId2) == 1, "Input object not removed from inventory");
    assertTrue(InventorySlots.get(chestEntityId) == 2, "Inventory slot not set");

    vm.stopPrank();

    vm.startPrank(bob, bob);

    VoxelCoord memory spawnCoord2 = VoxelCoord(spawnCoord.x + 1, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    vm.stopPrank();
  }

  function testTransferWithFullInventoryFromChest() public {}

  function testTransferPlayerToPlayer() public {}

  function testTransferChestTooFar() public {}

  function testTransferWithoutPlayer() public {}

  function testTransferSelf() public {}

  function testTransferNotOwnedItems() public {}
}
