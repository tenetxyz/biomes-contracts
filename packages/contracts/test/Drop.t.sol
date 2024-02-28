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
import { positionDataToVoxelCoord, addToInventoryCount } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, BLOCKS_BEFORE_INCREASE_STAMINA, BLOCKS_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";

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
    spawnCoord = VoxelCoord(197, 27, 203);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    return world.spawnPlayer(spawnCoord);
  }

  function testDropSingle() public {}

  function testDropMultiple() public {}

  function testMovePickUpDrop() public {}

  function testMoveMultiplePickUpDrop() public {}

  function testGravityPickUpDrop() public {}

  function testGravityFatalPickUpDrop() public {}

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
    world.drop(dropEntityIds, mineCoord);

    assertTrue(Inventory.get(inventoryId) == airEntityId, "Inventory not unset");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not unset");
    assertTrue(InventoryCount.get(playerEntityId, terrainObjectTypeId) == 0, "Inventory count not unset");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not unset");
    assertTrue(InventoryCount.get(airEntityId, terrainObjectTypeId) == 1, "Inventory count not unset");
    assertTrue(InventorySlots.get(airEntityId) == 1, "Inventory slot not unset");

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");

    vm.expectRevert();
    world.build(inventoryId, buildCoord);

    vm.stopPrank();
  }
}
