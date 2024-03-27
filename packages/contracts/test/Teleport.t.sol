// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { console } from "forge-std/console.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
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
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";
import { absInt32 } from "@biomesaw/utils/src/MathUtils.sol";
import { reverseInventoryHasItem } from "./utils/InventoryTestUtils.sol";

contract TeleportTest is MudTest, GasReporter {
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
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    // VoxelCoord[] memory path = new VoxelCoord[](1);
    // path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y, spawnCoord.z - 1);
    // world.move(path);
    // spawnCoord = path[0];

    return playerEntityId;
  }

  function testTeleportMultipleBlocks(VoxelCoord memory teleportCoord, bool overTerrain) internal {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    world.teleport(newCoord);
    uint32 oneBlockTeleportStaminaCost = staminaBefore - Stamina.getStamina(playerEntityId);

    vm.roll(block.number + 1);

    VoxelCoord memory agentCoord = newCoord;

    uint32 numBlocksToTeleport = uint32(
      absInt32(newCoord.x - teleportCoord.x) +
        absInt32(newCoord.y - teleportCoord.y) +
        absInt32(newCoord.z - teleportCoord.z)
    );
    newCoord = VoxelCoord(teleportCoord.x, teleportCoord.y, teleportCoord.z);

    vm.startPrank(worldDeployer, worldDeployer);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");
    if (!overTerrain) {
      bytes32 entityId = getUniqueEntity();
      Position.set(entityId, newCoord.x, newCoord.y, newCoord.z);
      ReversePosition.set(newCoord.x, newCoord.y, newCoord.z, entityId);
      ObjectType.set(entityId, AirObjectID);

      // set block below to non-air
      VoxelCoord memory belowCoord = VoxelCoord(newCoord.x, newCoord.y - 1, newCoord.z);
      assertTrue(world.getTerrainBlock(belowCoord) != AirObjectID, "Terrain block is air");
      bytes32 belowEntityId = getUniqueEntity();
      Position.set(belowEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
      ReversePosition.set(belowCoord.x, belowCoord.y, belowCoord.z, belowEntityId);
      ObjectType.set(belowEntityId, GrassObjectID);
    }
    vm.stopPrank();
    vm.startPrank(alice, alice);

    staminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport(
      string.concat(
        "teleport ",
        Strings.toString(numBlocksToTeleport),
        " blocks ",
        overTerrain ? "terrain" : "non-terrain"
      )
    );
    world.teleport(newCoord);
    endGasReport();

    assertTrue(Player.get(alice) == playerEntityId, "Player entity id is not correct");
    assertTrue(ReversePlayer.get(playerEntityId) == alice, "Reverse player is not correct");
    assertTrue(
      PlayerMetadata.getLastMoveBlock(playerEntityId) == block.number,
      "Player last move block is not correct"
    );
    assertTrue(
      PlayerMetadata.getNumMovesInBlock(playerEntityId) == numBlocksToTeleport,
      "Player move count is not correct"
    );
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player object type is not correct");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), newCoord),
      "Player did not move to new coords"
    );
    assertTrue(
      ReversePosition.get(newCoord.x, newCoord.y, newCoord.z) == playerEntityId,
      "Reverse position is not correct"
    );
    bytes32 oldEntityId = ReversePosition.get(newCoord.x, newCoord.y, newCoord.z);
    assertTrue(oldEntityId != bytes32(0), "Old entity id is not correct");
    assertTrue(ObjectType.get(oldEntityId) == PlayerObjectID, "Old entity object type is not correct");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(oldEntityId)), newCoord),
      "Old entity did not move to old coords"
    );
    oldEntityId = ReversePosition.get(agentCoord.x, agentCoord.y, agentCoord.z);
    assertTrue(oldEntityId != bytes32(0), "Old entity id is not correct");
    assertTrue(ObjectType.get(oldEntityId) == AirObjectID, "Old entity object type is not correct");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(oldEntityId)), agentCoord),
      "Old entity did not move to old coords"
    );
    uint32 newStamina = Stamina.getStamina(playerEntityId);
    uint32 blockTeleportStaminaCost = staminaBefore - newStamina;
    assertTrue(newStamina < staminaBefore, "Stamina not decremented");
    if (numBlocksToTeleport > 10) {
      assertTrue(
        blockTeleportStaminaCost > oneBlockTeleportStaminaCost * numBlocksToTeleport,
        "Stamina cost for multiple not more than one block move"
      );
    }
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testTeleportOneBlockTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z - 2), true);
  }

  function testTeleportOneBlockNonTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z - 2), false);
  }

  function testTeleportTenBlocksTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y - 1, SPAWN_LOW_Z - 10), true);
  }

  function testTeleportTenBlocksNonTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y - 1, SPAWN_LOW_Z - 10), false);
  }

  function testTeleportFiftyBlocksTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X + 1, SPAWN_GROUND_Y - 2, SPAWN_LOW_Z - 48), true);
  }

  function testTeleportFiftyBlocksNonTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X + 1, SPAWN_GROUND_Y - 2, SPAWN_LOW_Z - 48), false);
  }

  function testTeleportHundredBlocksTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z - 101), true);
  }

  function testTeleportHundredBlocksNonTerrain() public {
    testTeleportMultipleBlocks(VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z - 101), false);
  }

  function testTeleportWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");
    vm.stopPrank();

    vm.expectRevert("TeleportSystem: player does not exist");
    world.teleport(newCoord);
  }

  function testTeleportNonAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(newCoord) != AirObjectID, "Terrain block is not air");

    vm.expectRevert("TeleportSystem: cannot teleport to non-air block");
    world.teleport(newCoord);

    vm.stopPrank();
  }

  function testTeleportOneBlockInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    bytes32 inventoryId;
    for (uint i = 0; i < MAX_PLAYER_INVENTORY_SLOTS; i++) {
      inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, GrassObjectID);
      Inventory.set(inventoryId, playerEntityId);
      ReverseInventory.push(playerEntityId, inventoryId);
      addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    vm.stopPrank();

    vm.startPrank(alice, alice);

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

    startGasReport("teleport one block terrain w/ full inventory");
    world.teleport(newCoord);
    endGasReport();

    vm.stopPrank();
  }

  function testTeleportNotEnoughStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 0);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("TeleportSystem: not enough stamina");
    world.teleport(newCoord);

    vm.stopPrank();
  }

  function testTeleportRegenHealthAndStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

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

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

    startGasReport("teleport one block terrain w/ health and stamina regen");
    world.teleport(newCoord);
    endGasReport();

    assertTrue(Stamina.getStamina(playerEntityId) > staminaBefore, "Stamina not regened");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == newBlockTime, "Stamina last update time not set");
    assertTrue(Health.getHealth(playerEntityId) > healthBefore, "Health not regened");
    assertTrue(Health.getLastUpdatedTime(playerEntityId) == newBlockTime, "Health last update time not set");

    vm.stopPrank();
  }

  function testTeleportWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

    world.logoffPlayer();

    vm.expectRevert("TeleportSystem: player isn't logged in");
    world.teleport(newCoord);
  }
}
