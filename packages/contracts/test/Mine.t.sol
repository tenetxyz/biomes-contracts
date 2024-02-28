// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
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
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID } from "../src/ObjectTypeIds.sol";

contract MineTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;

  function setUp() public override {
    super.setUp();

    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
  }

  function setupPlayer() public returns (bytes32) {
    spawnCoord = VoxelCoord(197, 27, 203);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    return world.spawnPlayer(spawnCoord);
  }

  function testMineTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("mine terrain");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);
    endGasReport();

    bytes32 mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(inventoryId != bytes32(0), "Inventory entity not found");
    assertTrue(Inventory.get(inventoryId) == playerEntityId, "Inventory not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Inventory object not set");
    assertTrue(InventoryCount.get(inventoryId, terrainObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(Stamina.getStamina(playerEntityId) < staminaBefore, "Stamina not decremented");
    assertTrue(Stamina.getLastUpdateBlock(playerEntityId) == block.number, "Stamina last update block not set");

    vm.stopPrank();
  }

  function testBuildTerrain() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z - 1);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");
    bytes32 inventoryId = world.mine(terrainObjectTypeId, mineCoord);

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport("build terrain");
    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    world.build(inventoryId, buildCoord);
    endGasReport();

    assertTrue(voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(inventoryId)), mineCoord), "Position not set");
    assertTrue(ObjectType.get(inventoryId) == terrainObjectTypeId, "Object not built");

    vm.stopPrank();
  }

  function testMineNonTerrain() public {}

  function testMineInventoryFull() public {}

  function testMineAgent() public {}

  function testMineAir() public {}

  function testMineWithoutPlayer() public {}

  function testMineTooFar() public {}

  function testMineNotEnoughStamina() public {}

  function testMineGravitySingle() public {}

  function testMineGravityMultiple() public {}

  function testMineGravityFatal() public {}

  function testMineWithEquipped() public {}

  function testMineRegenHealthAndStamina() public {}
}
