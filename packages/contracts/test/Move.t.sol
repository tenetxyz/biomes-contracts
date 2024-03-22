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
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";

contract MoveTest is MudTest, GasReporter {
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

  function testMoveMultipleBlocks(uint8 numBlocksToMove, bool overTerrain) internal {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);
    world.move(newCoords);
    uint32 oneBlockMoveStaminaCost = staminaBefore - Stamina.getStamina(playerEntityId);

    vm.roll(block.number + 1);

    VoxelCoord memory agentCoord = newCoords[0];

    newCoords = new VoxelCoord[](numBlocksToMove);
    for (uint8 i = 0; i < numBlocksToMove; i++) {
      newCoords[i] = VoxelCoord(agentCoord.x, agentCoord.y, agentCoord.z + int32(int(uint(i))) + 1);
    }

    vm.startPrank(worldDeployer, worldDeployer);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
      if (!overTerrain) {
        bytes32 entityId = getUniqueEntity();
        Position.set(entityId, newCoords[i].x, newCoords[i].y, newCoords[i].z);
        ReversePosition.set(newCoords[i].x, newCoords[i].y, newCoords[i].z, entityId);
        ObjectType.set(entityId, AirObjectID);

        // set block below to non-air
        VoxelCoord memory belowCoord = VoxelCoord(newCoords[i].x, newCoords[i].y - 1, newCoords[i].z);
        assertTrue(world.getTerrainBlock(belowCoord) != AirObjectID, "Terrain block is air");
        bytes32 belowEntityId = getUniqueEntity();
        Position.set(belowEntityId, belowCoord.x, belowCoord.y, belowCoord.z);
        ReversePosition.set(belowCoord.x, belowCoord.y, belowCoord.z, belowEntityId);
        ObjectType.set(belowEntityId, GrassObjectID);
      }
    }
    vm.stopPrank();
    vm.startPrank(alice, alice);

    staminaBefore = Stamina.getStamina(playerEntityId);

    startGasReport(
      string.concat("move ", Strings.toString(numBlocksToMove), " blocks ", overTerrain ? "terrain" : "non-terrain")
    );
    world.move(newCoords);
    endGasReport();

    assertTrue(Player.get(alice) == playerEntityId, "Player entity id is not correct");
    assertTrue(ReversePlayer.get(playerEntityId) == alice, "Reverse player is not correct");
    assertTrue(
      PlayerMetadata.getLastMoveBlock(playerEntityId) == block.number,
      "Player last move block is not correct"
    );
    assertTrue(
      PlayerMetadata.getNumMovesInBlock(playerEntityId) == numBlocksToMove,
      "Player move count is not correct"
    );
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player object type is not correct");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), newCoords[numBlocksToMove - 1]),
      "Player did not move to new coords"
    );
    assertTrue(
      ReversePosition.get(
        newCoords[numBlocksToMove - 1].x,
        newCoords[numBlocksToMove - 1].y,
        newCoords[numBlocksToMove - 1].z
      ) == playerEntityId,
      "Reverse position is not correct"
    );
    for (uint i = 0; i < newCoords.length - 1; i++) {
      bytes32 oldEntityId = ReversePosition.get(newCoords[i].x, newCoords[i].y, newCoords[i].z);
      assertTrue(oldEntityId != bytes32(0), "Old entity id is not correct");
      assertTrue(ObjectType.get(oldEntityId) == AirObjectID, "Old entity object type is not correct");
      assertTrue(
        voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(oldEntityId)), newCoords[i]),
        "Old entity did not move to old coords"
      );
    }
    bytes32 oldEntityId = ReversePosition.get(agentCoord.x, agentCoord.y, agentCoord.z);
    assertTrue(oldEntityId != bytes32(0), "Old entity id is not correct");
    assertTrue(ObjectType.get(oldEntityId) == AirObjectID, "Old entity object type is not correct");
    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(oldEntityId)), agentCoord),
      "Old entity did not move to old coords"
    );
    uint32 newStamina = Stamina.getStamina(playerEntityId);
    uint32 blockMoveStaminaCost = staminaBefore - newStamina;
    assertTrue(newStamina < staminaBefore, "Stamina not decremented");
    if (numBlocksToMove > 1) {
      assertTrue(
        blockMoveStaminaCost > oneBlockMoveStaminaCost * numBlocksToMove,
        "Stamina cost for multiple not more than one block move"
      );
    }
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testMoveOneBlockTerrain() public {
    testMoveMultipleBlocks(1, true);
  }

  function testMoveOneBlockNonTerrain() public {
    testMoveMultipleBlocks(1, false);
  }

  function testMoveFiveBlocksTerrain() public {
    testMoveMultipleBlocks(5, true);
  }

  function testMoveFiveBlocksNonTerrain() public {
    testMoveMultipleBlocks(5, false);
  }

  function testMoveTenBlocksTerrain() public {
    testMoveMultipleBlocks(10, true);
  }

  function testMoveTenBlocksNonTerrain() public {
    testMoveMultipleBlocks(10, false);
  }

  function testMoveWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }
    vm.stopPrank();

    vm.expectRevert("MoveSystem: player does not exist");
    world.move(newCoords);
  }

  function testMoveNonAir() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) != AirObjectID, "Terrain block is not air");
    }

    vm.expectRevert("MoveSystem: cannot move to non-air block");
    world.move(newCoords);

    vm.stopPrank();
  }

  function testMoveInValidCoords() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 3);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    vm.expectRevert("MoveSystem: new coord is not in surrounding cube of old coord");
    world.move(newCoords);

    vm.stopPrank();
  }

  function testMoveOneBlockInventoryFull() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    ObjectTypeMetadata.setStackable(GrassObjectID, 1);
    bytes32 inventoryId;
    for (uint i = 0; i < MAX_PLAYER_INVENTORY_SLOTS; i++) {
      inventoryId = getUniqueEntity();
      ObjectType.set(inventoryId, GrassObjectID);
      Inventory.set(inventoryId, playerEntityId);
      addToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 1);
    }
    assertTrue(
      InventoryCount.get(playerEntityId, GrassObjectID) == MAX_PLAYER_INVENTORY_SLOTS,
      "Inventory count not set properly"
    );
    assertTrue(InventorySlots.get(playerEntityId) == MAX_PLAYER_INVENTORY_SLOTS, "Inventory slots not set correctly");
    vm.stopPrank();

    vm.startPrank(alice, alice);

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    startGasReport("move one block terrain w/ full inventory");
    world.move(newCoords);
    endGasReport();

    vm.stopPrank();
  }

  function testMoveNotEnoughStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 0);
    Stamina.setLastUpdatedTime(playerEntityId, block.timestamp);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("MoveSystem: not enough stamina");
    world.move(newCoords);

    vm.stopPrank();
  }

  function testMoveRegenHealthAndStamina() public {
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

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    startGasReport("move one block terrain w/ health and stamina regen");
    world.move(newCoords);
    endGasReport();

    assertTrue(Stamina.getStamina(playerEntityId) > staminaBefore, "Stamina not regened");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == newBlockTime, "Stamina last update time not set");
    assertTrue(Health.getHealth(playerEntityId) > healthBefore, "Health not regened");
    assertTrue(Health.getLastUpdatedTime(playerEntityId) == newBlockTime, "Health last update time not set");

    vm.stopPrank();
  }

  function testMoveWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + 1);
    for (uint i = 0; i < newCoords.length; i++) {
      assertTrue(world.getTerrainBlock(newCoords[i]) == AirObjectID, "Terrain block is not air");
    }

    world.logoffPlayer();

    vm.expectRevert("MoveSystem: player isn't logged in");
    world.move(newCoords);
  }
}
