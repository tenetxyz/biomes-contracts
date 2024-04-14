// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
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
import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { ReverseInventory } from "../src/codegen/tables/ReverseInventory.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testAddToInventoryCount, testReverseInventoryHasItem } from "./utils/InventoryTestUtils.sol";

contract PlayerTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
  }

  function testSpawnPlayer() public {
    vm.startPrank(alice, alice);

    VoxelCoord memory spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    bytes32 terrainObjectTypeId = getTerrainObjectTypeId(worldAddress, spawnCoord);
    assertTrue(terrainObjectTypeId == AirObjectID, "Terrain block is not air");

    startGasReport("spawn player");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);
    endGasReport();

    assertTrue(playerEntityId != bytes32(0), "Player entity not found");
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), spawnCoord),
      "Player position not set"
    );
    assertTrue(
      ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z) == playerEntityId,
      "Reverse position not set"
    );
    assertTrue(Player.get(alice) == playerEntityId, "Player entity not found in player table");
    assertTrue(ReversePlayer.get(playerEntityId) == alice, "Reverse player is not correct");
    assertTrue(Health.getHealth(playerEntityId) == MAX_PLAYER_HEALTH, "Player health not set");
    assertTrue(Stamina.getStamina(playerEntityId) == MAX_PLAYER_STAMINA, "Player stamina not set");

    // Try spawning another player with same user, should fail
    VoxelCoord memory spawnCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    terrainObjectTypeId = getTerrainObjectTypeId(worldAddress, spawnCoord2);
    assertTrue(terrainObjectTypeId == AirObjectID, "Terrain block is not air");

    vm.expectRevert("PlayerSystem: player already exists");
    world.spawnPlayer(spawnCoord2);

    vm.stopPrank();

    vm.startPrank(bob, bob);

    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);
    assertTrue(playerEntityId2 != bytes32(0) && playerEntityId2 != playerEntityId, "Player entity not found");
    assertTrue(ObjectType.get(playerEntityId2) == PlayerObjectID, "Player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId2)), spawnCoord2),
      "Player position not set"
    );
    assertTrue(
      ReversePosition.get(spawnCoord2.x, spawnCoord2.y, spawnCoord2.z) == playerEntityId2,
      "Reverse position not set"
    );
    assertTrue(Player.get(bob) == playerEntityId2, "Player entity not found in player table");
    assertTrue(ReversePlayer.get(playerEntityId2) == bob, "Reverse player is not correct");
    assertTrue(Health.getHealth(playerEntityId2) == MAX_PLAYER_HEALTH, "Player health not set");
    assertTrue(Stamina.getStamina(playerEntityId2) == MAX_PLAYER_STAMINA, "Player stamina not set");

    vm.stopPrank();
  }

  function testSpawnPlayerInvalidCoord() public {
    vm.startPrank(alice, alice);

    // Invalid terrain coord
    VoxelCoord memory spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y - 1, SPAWN_LOW_Z);
    bytes32 terrainObjectTypeId = getTerrainObjectTypeId(worldAddress, spawnCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    vm.expectRevert("PlayerSystem: cannot spawn on terrain non-air block");
    world.spawnPlayer(spawnCoord);

    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y, SPAWN_LOW_Z);
    terrainObjectTypeId = getTerrainObjectTypeId(worldAddress, spawnCoord);
    assertTrue(terrainObjectTypeId == AirObjectID, "Terrain block is not air");

    world.spawnPlayer(spawnCoord);

    vm.stopPrank();

    vm.startPrank(bob, bob);

    vm.expectRevert("PlayerSystem: spawn coord is not air");
    world.spawnPlayer(spawnCoord);

    vm.stopPrank();
  }

  function testSpawnPlayerOutsideSpawn() public {
    vm.startPrank(alice, alice);

    // Invalid terrain coord
    VoxelCoord memory spawnCoord = VoxelCoord(SPAWN_HIGH_X + 1, SPAWN_GROUND_Y, SPAWN_HIGH_Z + 1);
    bytes32 terrainObjectTypeId = getTerrainObjectTypeId(worldAddress, spawnCoord);
    assertTrue(terrainObjectTypeId == AirObjectID, "Terrain block is not air");

    vm.expectRevert("PlayerSystem: cannot spawn outside spawn area");
    world.spawnPlayer(spawnCoord);

    vm.stopPrank();
  }

  function testSpawnPlayerOutsideWorldBorder() public {
    vm.startPrank(alice, alice);

    // Invalid terrain coord
    VoxelCoord memory spawnCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z);
    vm.expectRevert("PlayerSystem: cannot spawn outside world border");
    world.spawnPlayer(spawnCoord);

    vm.stopPrank();
  }

  function testSpawnPlayerInAir() public {
    vm.startPrank(alice, alice);

    VoxelCoord memory spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 2, SPAWN_LOW_Z);
    bytes32 terrainObjectTypeId = getTerrainObjectTypeId(worldAddress, spawnCoord);
    assertTrue(terrainObjectTypeId == AirObjectID, "Terrain block is not air");

    vm.expectRevert("PlayerSystem: cannot spawn player with gravity");
    world.spawnPlayer(spawnCoord);
  }
}
