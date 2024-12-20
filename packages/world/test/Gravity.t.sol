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
import { ExperiencePoints } from "../src/codegen/tables/ExperiencePoints.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { GRAVITY_DAMAGE, MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, WoodenPickObjectID, DiamondOreObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem } from "./utils/TestUtils.sol";

contract GravityTest is MudTest, GasReporter {
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

  function testMineGravitySingle() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint16 healthBefore = Health.getHealth(playerEntityId);

    startGasReport("gravity via mine, fall one block");
    world.mine(mineCoord);
    endGasReport();

    // assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");
    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testMineGravityMultiple() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 2, spawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint16 healthBefore = Health.getHealth(playerEntityId);

    world.mine(mineCoord);

    VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    startGasReport("gravity via mine, fall two blocks");
    world.mine(mineCoord2);
    endGasReport();

    // assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");

    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");

    bytes32 newEntityId2 = ReversePosition.get(mineCoord2.x, mineCoord2.y, mineCoord2.z);
    assertTrue(newEntityId2 != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId2) == AirObjectID, "Player didnt fall, air not set");

    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testMineGravityFatal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    VoxelCoord memory mineCoord;
    for (uint16 i = 0; i < GRAVITY_DAMAGE - 1; i++) {
      mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - (int16(int(uint(i))) + 2), spawnCoord.z);
      assertTrue(world.getTerrainBlock(mineCoord) != AirObjectID, "Terrain block is air");
      bytes32 entityId = testGetUniqueEntity();
      Position.set(entityId, mineCoord.x, mineCoord.y, mineCoord.z);
      ReversePosition.set(mineCoord.x, mineCoord.y, mineCoord.z, entityId);
      ObjectType.set(entityId, AirObjectID);
    }
    vm.stopPrank();
    vm.startPrank(bob, bob);

    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntity2 = world.spawnPlayer(spawnCoord2);

    mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint16 healthBefore = Health.getHealth(playerEntityId);

    startGasReport("gravity via mine, fatal fall from full health");
    world.mine(mineCoord);
    endGasReport();

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    assertTrue(Player.get(bob) == playerEntity2, "Player removed from world");
    assertTrue(ReversePlayer.get(playerEntity2) == bob, "Player removed from world");

    vm.stopPrank();
  }

  function testMineGravityDoublePlayers() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
    world.move(path);

    vm.roll(block.number + 1);

    // move on top of player entity id 1
    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    world.move(newCoords);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint256 health1Before = Health.getHealth(playerEntityId);
    uint256 health2Before = Health.getHealth(playerEntityId2);

    world.mine(mineCoord);

    // assertTrue(Health.getHealth(playerEntityId) < health1Before, "Player health not reduced");
    // assertTrue(Health.getHealth(playerEntityId2) < health2Before, "Player health not reduced");
    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(ObjectType.get(playerEntityId2) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord),
      "Player position not set"
    );
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId2)), spawnCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testMineGravityDoublePlayersFatal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Health.setHealth(playerEntityId, 1);
    vm.stopPrank();
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
    world.move(path);

    vm.roll(block.number + 1);

    // move on top of player entity id 1
    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    world.move(newCoords);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    uint256 health1Before = Health.getHealth(playerEntityId);
    uint256 health2Before = Health.getHealth(playerEntityId2);

    world.mine(mineCoord);

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    assertTrue(Player.get(bob) == playerEntityId2, "Player removed from world");
    assertTrue(ReversePlayer.get(playerEntityId2) == bob, "Player removed from world");
    assertTrue(ObjectType.get(playerEntityId2) == PlayerObjectID, "Player object not removed");

    assertTrue(Health.getHealth(playerEntityId2) < health2Before, "Player health not reduced");
    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    assertTrue(ObjectType.get(playerEntityId2) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId2)), mineCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testOneBlockMoveGravitySingle() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    uint16 healthBefore = Health.getHealth(playerEntityId);

    startGasReport("gravity via move, fall one block");
    world.move(newCoords);
    endGasReport();

    // assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");
    bytes32 newEntityId = ReversePosition.get(newCoords[0].x, newCoords[0].y, newCoords[0].z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testMultipleBlockMoveGravitySingle() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    newCoords[1] = VoxelCoord(newCoords[0].x, newCoords[0].y, newCoords[0].z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    uint16 healthBefore = Health.getHealth(playerEntityId);

    world.move(newCoords);

    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), newCoords[1]),
      "Player position not set"
    );

    // assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");
    // bytes32 newEntityId = ReversePosition.get(newCoords[0].x, newCoords[0].y, newCoords[0].z);
    // assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    // assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    // assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    // assertTrue(
    //   voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord),
    //   "Player position not set"
    // );
    // bytes32 newEntityId2 = ReversePosition.get(newCoords[1].x, newCoords[1].y, newCoords[1].z);
    // assertTrue(newEntityId2 == bytes32(0), "Agent reached invalid position");

    vm.stopPrank();
  }

  function testOneBlockMoveGravityMultiple() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 2, spawnCoord.z + 1);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord2);

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(mineCoord);

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    uint16 healthBefore = Health.getHealth(playerEntityId);

    startGasReport("gravity via move, fall two blocks");
    world.move(newCoords);
    endGasReport();

    // assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");

    bytes32 newEntityId = ReversePosition.get(newCoords[0].x, newCoords[0].y, newCoords[0].z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");

    bytes32 newEntityId2 = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(newEntityId2 != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId2) == AirObjectID, "Player didnt fall, air not set");

    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord2),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testOneBlockMoveGravityFatal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    vm.startPrank(worldDeployer, worldDeployer);
    for (uint16 i = 0; i < GRAVITY_DAMAGE; i++) {
      VoxelCoord memory mineCoord = VoxelCoord(
        spawnCoord.x,
        spawnCoord.y - (int16(int(uint(i))) + 1),
        spawnCoord.z + 1
      );
      assertTrue(world.getTerrainBlock(mineCoord) != AirObjectID, "Terrain block is air");
      bytes32 entityId = testGetUniqueEntity();
      Position.set(entityId, mineCoord.x, mineCoord.y, mineCoord.z);
      ReversePosition.set(mineCoord.x, mineCoord.y, mineCoord.z, entityId);
      ObjectType.set(entityId, AirObjectID);
    }
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    uint16 healthBefore = Health.getHealth(playerEntityId);

    // startGasReport("gravity via move, fatal fall from full health");
    vm.expectRevert("MoveSystem: cannot move player with gravity");
    world.move(newCoords);
    // endGasReport();

    // assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    // assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    // assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    // assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    // assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    vm.stopPrank();
  }

  function testOneBlockMovePlayerAboveGravity() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    vm.stopPrank();
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
    world.move(path);

    vm.roll(block.number + 1);

    // move on top of player entity id 1
    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    world.move(newCoords);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    uint256 healthBefore = Health.getHealth(playerEntityId);
    uint256 health2Before = Health.getHealth(playerEntityId2);

    world.move(newCoords);

    // assertTrue(Health.getHealth(playerEntityId) == healthBefore, "Player health reduced");
    // assertTrue(Health.getHealth(playerEntityId2) < health2Before, "Player health not reduced");
    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(ObjectType.get(playerEntityId2) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), newCoords[0]),
      "Player position not set"
    );
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId2)), spawnCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  // function testOneBlockTeleportGravitySingle() public {
  //   vm.startPrank(alice, alice);

  //   bytes32 playerEntityId = setupPlayer();

  //   vm.roll(block.number + 1);

  //   VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
  //   uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
  //   assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

  //   world.mine(mineCoord);

  //   VoxelCoord memory newCoord = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
  //   assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

  //   uint16 healthBefore = Health.getHealth(playerEntityId);

  //   startGasReport("gravity via teleport, fall one block");
  //   world.teleport(newCoord);
  //   endGasReport();

  //   assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");
  //   bytes32 newEntityId = ReversePosition.get(newCoord.x, newCoord.y, newCoord.z);
  //   assertTrue(newEntityId != bytes32(0), "Mine entity not found");
  //   assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
  //   assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
  //   assertTrue(
  //     voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord),
  //     "Player position not set"
  //   );

  //   vm.stopPrank();
  // }

  // function testOneBlockTeleportGravityMultiple() public {
  //   vm.startPrank(alice, alice);

  //   bytes32 playerEntityId = setupPlayer();

  //   vm.roll(block.number + 1);

  //   VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 2, spawnCoord.z + 1);
  //   uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
  //   assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

  //   world.mine(mineCoord2);

  //   VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
  //   terrainObjectTypeId = world.getTerrainBlock(mineCoord);
  //   assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

  //   world.mine(mineCoord);

  //   VoxelCoord memory newCoord = VoxelCoord(mineCoord.x, mineCoord.y + 1, mineCoord.z);
  //   assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

  //   uint16 healthBefore = Health.getHealth(playerEntityId);

  //   startGasReport("gravity via teleport, fall two blocks");
  //   world.teleport(newCoord);
  //   endGasReport();

  //   assertTrue(Health.getHealth(playerEntityId) < healthBefore, "Player health not reduced");

  //   bytes32 newEntityId = ReversePosition.get(newCoord.x, newCoord.y, newCoord.z);
  //   assertTrue(newEntityId != bytes32(0), "Mine entity not found");
  //   assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");

  //   bytes32 newEntityId2 = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
  //   assertTrue(newEntityId2 != bytes32(0), "Mine entity not found");
  //   assertTrue(ObjectType.get(newEntityId2) == AirObjectID, "Player didnt fall, air not set");

  //   assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
  //   assertTrue(
  //     voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord2),
  //     "Player position not set"
  //   );

  //   vm.stopPrank();
  // }

  // function testOneBlockTeleportGravityFatal() public {
  //   vm.startPrank(alice, alice);

  //   bytes32 playerEntityId = setupPlayer();

  //   vm.roll(block.number + 1);

  //   vm.startPrank(worldDeployer, worldDeployer);
  //   for (uint16 i = 0; i < GRAVITY_DAMAGE; i++) {
  //     VoxelCoord memory mineCoord = VoxelCoord(
  //       spawnCoord.x,
  //       spawnCoord.y - (int16(int(uint(i))) + 1),
  //       spawnCoord.z + 1
  //     );
  //     assertTrue(world.getTerrainBlock(mineCoord) != AirObjectID, "Terrain block is air");
  //     bytes32 entityId = testGetUniqueEntity();
  //     Position.set(entityId, mineCoord.x, mineCoord.y, mineCoord.z);
  //     ReversePosition.set(mineCoord.x, mineCoord.y, mineCoord.z, entityId);
  //     ObjectType.set(entityId, AirObjectID);
  //   }
  //   vm.stopPrank();
  //   vm.startPrank(alice, alice);

  //   VoxelCoord memory newCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
  //   assertTrue(world.getTerrainBlock(newCoord) == AirObjectID, "Terrain block is not air");

  //   uint16 healthBefore = Health.getHealth(playerEntityId);

  //   startGasReport("gravity via teleport, fatal fall from full health");
  //   world.teleport(newCoord);
  //   endGasReport();

  //   assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
  //   assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
  //   assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
  //   assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
  //   assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

  //   vm.stopPrank();
  // }

  // function testOneBlockTeleportPlayerAboveGravity() public {
  //   vm.startPrank(alice, alice);

  //   bytes32 playerEntityId = setupPlayer();

  //   vm.roll(block.number + 1);

  //   vm.stopPrank();
  //   vm.startPrank(bob, bob);
  //   VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
  //   assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
  //   bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

  //   // move player outside spawn
  //   VoxelCoord[] memory path = new VoxelCoord[](1);
  //   path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
  //   world.move(path);

  //   vm.roll(block.number + 1);

  //   // move on top of player entity id 1
  //   VoxelCoord[] memory newCoords = new VoxelCoord[](1);
  //   newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
  //   world.move(newCoords);

  //   vm.stopPrank();
  //   vm.startPrank(alice, alice);

  //   newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
  //   assertTrue(world.getTerrainBlock(newCoords[0]) == AirObjectID, "Terrain block is not air");

  //   uint256 healthBefore = Health.getHealth(playerEntityId);
  //   uint256 health2Before = Health.getHealth(playerEntityId2);

  //   vm.roll(block.number + 1);

  //   world.move(newCoords);

  //   assertTrue(Health.getHealth(playerEntityId) == healthBefore, "Player health reduced");
  //   assertTrue(Health.getHealth(playerEntityId2) < health2Before, "Player health not reduced");
  //   bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
  //   assertTrue(newEntityId != bytes32(0), "Mine entity not found");
  //   assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
  //   assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
  //   assertTrue(ObjectType.get(playerEntityId2) == PlayerObjectID, "Player didnt fall, player object not found");
  //   assertTrue(
  //     voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), newCoords[0]),
  //     "Player position not set"
  //   );
  //   assertTrue(
  //     voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId2)), spawnCoord),
  //     "Player position not set"
  //   );

  //   vm.stopPrank();
  // }

  function testHitGravitySingle() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.roll(block.number + 1);

    vm.stopPrank();
    vm.startPrank(worldDeployer, worldDeployer);
    Health.setHealth(playerEntityId, 1);
    vm.stopPrank();
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntity2 = world.spawnPlayer(spawnCoord2);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
    world.move(path);

    vm.roll(block.number + 1);

    // move on top of player entity id 1
    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y + 1, spawnCoord.z);
    world.move(newCoords);
    world.hit(alice);

    assertTrue(Player.get(alice) == bytes32(0), "Player not removed from world");
    assertTrue(ReversePlayer.get(playerEntityId) == address(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Player stamina not reduced to 0");

    assertTrue(Player.get(bob) == playerEntity2, "Player removed from world");
    assertTrue(ReversePlayer.get(playerEntity2) == bob, "Player removed from world");
    assertTrue(ObjectType.get(playerEntity2) == PlayerObjectID, "Player object not removed");
    // Player should have fallen
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntity2)), spawnCoord),
      "Player position not set"
    );

    vm.stopPrank();
  }

  function testDirectCallGravity() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.expectRevert();
    world.runGravity(playerEntityId, spawnCoord);

    vm.stopPrank();
  }
}
