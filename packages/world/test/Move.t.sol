// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { console } from "forge-std/console.sol";

import { EntityId } from "../src/EntityId.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";

import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { InventoryTypeSlots } from "../src/codegen/tables/InventoryTypeSlots.sol";

import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";

import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { DustTest } from "./DustTest.sol";

import {
  LocalEnergyPool,
  MinedOrePosition,
  MovablePosition,
  OreCommitment,
  Position,
  ReverseMovablePosition,
  ReversePosition
} from "../src/utils/Vec3Storage.sol";

import {
  CHUNK_SIZE,
  MAX_PLAYER_GLIDES,
  MAX_PLAYER_JUMPS,
  MOVE_ENERGY_COST,
  PLAYER_FALL_DAMAGE_THRESHOLD,
  PLAYER_FALL_ENERGY_COST
} from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract MoveTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function _testMoveMultipleBlocks(address player, uint8 numBlocksToMove, bool overTerrain) internal {
    EntityId playerEntityId = Player.get(player);
    Vec3 startingCoord = MovablePosition.get(playerEntityId);
    Vec3[] memory newCoords = new Vec3[](numBlocksToMove);
    for (uint32 i = 0; i < numBlocksToMove; i++) {
      newCoords[i] = startingCoord + vec3(0, 0, int32(i) + 1);

      Vec3 belowCoord = newCoords[i] - vec3(0, 1, 0);
      Vec3 aboveCoord = newCoords[i] + vec3(0, 1, 0);
      if (overTerrain) {
        setTerrainAtCoord(newCoords[i], ObjectTypes.Air);
        setTerrainAtCoord(aboveCoord, ObjectTypes.Air);
        setTerrainAtCoord(belowCoord, ObjectTypes.Grass);
      } else {
        setObjectAtCoord(newCoords[i], ObjectTypes.Air);
        setObjectAtCoord(aboveCoord, ObjectTypes.Air);
        setObjectAtCoord(belowCoord, ObjectTypes.Grass);
      }
    }

    EnergyDataSnapshot memory beforeEnergyDataSnapshot =
      getEnergyDataSnapshot(playerEntityId, newCoords[numBlocksToMove - 1]);

    vm.prank(player);
    startGasReport(
      string.concat("move ", Strings.toString(numBlocksToMove), " blocks ", overTerrain ? "terrain" : "non-terrain")
    );
    world.move(playerEntityId, newCoords);
    endGasReport();

    Vec3 finalCoord = MovablePosition.get(playerEntityId);
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(finalCoord, newCoords[numBlocksToMove - 1], "Player did not move to the correct coord");
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), playerEntityId, "Above coord is not the player"
    );
    assertEq(EntityId.unwrap(ReverseMovablePosition.get(startingCoord)), bytes32(0), "Player position was not deleted");
    assertEq(
      EntityId.unwrap(ReverseMovablePosition.get(startingCoord)), bytes32(0), "Above starting coord is not the player"
    );

    EnergyDataSnapshot memory afterEnergyDataSnapshot =
      getEnergyDataSnapshot(playerEntityId, newCoords[numBlocksToMove - 1]);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveOneBlockTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 1, true);
  }

  function testMoveOneBlockNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 1, false);
  }

  function testMoveFiveBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 5, true);
  }

  function testMoveFiveBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 5, false);
  }

  function testMoveTenBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 10, true);
  }

  function testMoveTenBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 10, false);
  }

  function testMoveFiftyBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 50, true);
  }

  function testMoveFiftyBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 50, false);
  }

  function testMoveHundredBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 100, true);
  }

  function testMoveHundredBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 100, false);
  }

  function testMoveJump() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numJumps = 1;
    Vec3[] memory newCoords = new Vec3[](numJumps);
    for (uint32 i = 0; i < numJumps; i++) {
      newCoords[i] = playerCoord + vec3(0, int32(i) + 1, 0);
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move single jump");
    world.move(aliceEntityId, newCoords);
    endGasReport();

    // Expect the player to fall down back to the original coord
    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, playerCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveGlide() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numGlides = 2;
    Vec3[] memory newCoords = new Vec3[](numGlides + 1);
    for (uint32 i = 0; i < newCoords.length; i++) {
      newCoords[i] = playerCoord + vec3(0, 1, int32(int256(uint256(i))));
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }
    Vec3 expectedFinalCoord = playerCoord + vec3(0, 0, int32(int256(numGlides)));
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), ObjectTypes.Grass);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    // Expect the player to fall down back after the last block
    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, expectedFinalCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveFallWithoutDamage() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint32 numFalls = PLAYER_FALL_DAMAGE_THRESHOLD - 1;
    Vec3[] memory newCoords = new Vec3[](numFalls + 1);
    for (uint32 i = 0; i < numFalls; i++) {
      Vec3 airCoord = playerCoord + vec3(0, -int32(i + 1), 1);
      setObjectAtCoord(airCoord, ObjectTypes.Air);
      newCoords[i] = airCoord + vec3(0, 1, 0);
    }
    Vec3 grassCoord = playerCoord + vec3(0, -int32(numFalls + 1), 1);
    newCoords[numFalls] = grassCoord + vec3(0, 1, 0);
    setObjectAtCoord(grassCoord, ObjectTypes.Grass);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    // Expect the player to be above the grass
    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, grassCoord + vec3(0, 1, 0), "Player did not move to the grass coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost =
      assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    // Fall damage is greater than the move energy cost
    assertGt(PLAYER_FALL_ENERGY_COST, MOVE_ENERGY_COST, "Fall energy cost is not greater than the move energy cost");
    assertEq(
      playerEnergyLost,
      MOVE_ENERGY_COST * newCoords.length,
      "Player energy lost is not greater than the move energy cost"
    );
  }

  function testMoveFallDamage() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint32 numFalls = PLAYER_FALL_DAMAGE_THRESHOLD + 1;
    Vec3[] memory newCoords = new Vec3[](numFalls + 1);
    for (uint32 i = 0; i < numFalls; i++) {
      Vec3 airCoord = playerCoord + vec3(0, -int32(i + 1), 1);
      setObjectAtCoord(airCoord, ObjectTypes.Air);
      newCoords[i] = airCoord + vec3(0, 1, 0);
    }
    Vec3 grassCoord = playerCoord + vec3(0, -int32(numFalls + 1), 1);
    newCoords[numFalls] = grassCoord + vec3(0, 1, 0);
    setObjectAtCoord(grassCoord, ObjectTypes.Grass);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    // Expect the player to be above the grass
    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, grassCoord + vec3(0, 1, 0), "Player did not move to the grass coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost =
      assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    // Fall damage is greater than the move energy cost
    assertGt(PLAYER_FALL_ENERGY_COST, MOVE_ENERGY_COST, "Fall energy cost is not greater than the move energy cost");
    assertGt(
      playerEnergyLost,
      MOVE_ENERGY_COST * newCoords.length,
      "Player energy lost is not greater than the move energy cost"
    );
  }

  function testMoveThroughWater() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](3);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 1, 1);
    newCoords[2] = playerCoord + vec3(0, 0, 2);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, newCoords[newCoords.length - 1], "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveEndAtStart() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](4);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);
    newCoords[2] = playerCoord + vec3(0, 0, 1);
    newCoords[3] = playerCoord;
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, playerCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveOverlapStartingCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](6);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);
    newCoords[2] = playerCoord + vec3(0, 0, 1);
    newCoords[3] = playerCoord;
    newCoords[4] = playerCoord + vec3(0, 0, -1);
    newCoords[5] = playerCoord + vec3(0, 0, -2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1];
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), ObjectTypes.Grass);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, expectedFinalCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveFailsIfInvalidJump() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numJumps = MAX_PLAYER_JUMPS + 1;
    Vec3[] memory newCoords = new Vec3[](numJumps);
    for (uint8 i = 0; i < numJumps; i++) {
      newCoords[i] = playerCoord + vec3(0, int32(int256(uint256(i))) + 1, 0);
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }

    vm.prank(alice);
    vm.expectRevert("Cannot jump more than 3 blocks");
    world.move(aliceEntityId, newCoords);
  }

  function testMoveFailsIfInvalidGlide() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numGlides = MAX_PLAYER_GLIDES + 1;
    Vec3[] memory newCoords = new Vec3[](numGlides + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      newCoords[i] = playerCoord + vec3(0, 1, int32(int256(uint256(i))));
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }

    vm.prank(alice);
    vm.expectRevert("Cannot glide more than 10 blocks");
    world.move(aliceEntityId, newCoords);
  }

  function testMoveFailsIfNonPassable() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }

    setObjectAtCoord(newCoords[1], ObjectTypes.Dirt);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.move(aliceEntityId, newCoords);

    setObjectAtCoord(newCoords[0] + vec3(0, 1, 0), ObjectTypes.Dirt);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.move(aliceEntityId, newCoords);
  }

  function testMoveFailsIfPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, Vec3 bobCoord) = spawnPlayerOnAirChunk(aliceCoord + vec3(0, 0, 2));

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = aliceCoord + vec3(0, 0, 1);
    newCoords[1] = bobCoord;
    setObjectAtCoord(newCoords[0], ObjectTypes.Air);
    setObjectAtCoord(newCoords[0] + vec3(0, 1, 0), ObjectTypes.Air);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.move(aliceEntityId, newCoords);

    newCoords[1] = bobCoord + vec3(0, 1, 0);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.move(aliceEntityId, newCoords);
  }

  function testMoveFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 3);

    vm.prank(alice);
    vm.expectRevert("New coord is too far from old coord");
    world.move(aliceEntityId, newCoords);

    uint256 pathLength = uint256(int256(playerCoord.x()));
    newCoords = new Vec3[](pathLength);
    newCoords[0] = playerCoord - vec3(1, 0, 0);
    for (uint32 i = 0; i < pathLength; i++) {
      newCoords[i] = (playerCoord - vec3(1, 0, 0).mul(int32(i)));
    }

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(aliceEntityId, newCoords);
  }

  function testMoveFatal() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Set player energy to exactly enough for one move
    uint128 exactEnergy = MOVE_ENERGY_COST;
    Energy.set(
      aliceEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: exactEnergy, drainRate: 0 })
    );

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    setObjectAtCoord(newCoords[0], ObjectTypes.Air);
    setObjectAtCoord(newCoords[0] + vec3(0, 1, 0), ObjectTypes.Air);
    setObjectAtCoord(newCoords[0] - vec3(0, 1, 0), ObjectTypes.Dirt);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    // Check energy is zero
    assertEq(Energy.getEnergy(aliceEntityId), 0, "Player energy is not 0");

    // Call activate to trigger player removal from grid
    vm.prank(alice);
    world.activate(aliceEntityId);

    // Verify the player entity is still registered to the address, but removed from the grid
    assertEq(Player.get(alice), aliceEntityId, "Player entity was deleted");
    assertEq(MovablePosition.get(aliceEntityId), vec3(0, 0, 0), "Player position was not deleted");
    assertEq(ReverseMovablePosition.get(playerCoord), EntityId.wrap(0), "Player reverse position was not deleted");
    assertEq(
      ReverseMovablePosition.get(playerCoord + vec3(0, 1, 0)),
      EntityId.wrap(0),
      "Player reverse position at head was not deleted"
    );
  }

  function testDeathFromLongFall() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Add items to player's inventory to test transfer
    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.Stone, 10);
    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.IronOre, 5);

    // Setup a fall path with a specific death point
    uint32 fallHeight = 10; // Well above the PLAYER_FALL_DAMAGE_THRESHOLD
    Vec3[] memory newCoords = new Vec3[](fallHeight + 1);

    // Create a high column of air blocks
    for (uint32 i = 0; i < fallHeight; i++) {
      Vec3 airCoord = playerCoord + vec3(0, -int32(i + 1), 1);
      setObjectAtCoord(airCoord, ObjectTypes.Air);
      newCoords[i] = airCoord + vec3(0, 1, 0);
    }

    // Set the last coordinate
    Vec3 landingCoord = playerCoord + vec3(0, -int32(fallHeight + 1), 1);
    newCoords[fallHeight] = landingCoord + vec3(0, 1, 0);
    setObjectAtCoord(landingCoord, ObjectTypes.Grass);

    // Calculate energy costs for the fall
    // Falls after threshold cost PLAYER_FALL_ENERGY_COST each
    uint32 deathIndex = 5; // We want the player to die at the 5th step (index 4)

    // Calculate energy needed to die exactly at deathIndex
    uint128 energyForFallsBeforeDeath = PLAYER_FALL_ENERGY_COST * (deathIndex - PLAYER_FALL_DAMAGE_THRESHOLD);

    Energy.set(
      aliceEntityId,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: energyForFallsBeforeDeath, drainRate: 0 })
    );

    // Verify inventory before move
    assertInventoryHasObject(aliceEntityId, ObjectTypes.Stone, 10);
    assertInventoryHasObject(aliceEntityId, ObjectTypes.IronOre, 5);

    // Get entity at the expected death location
    EntityId entityAtDeathLocation = ReversePosition.get(newCoords[fallHeight]);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    // Verify player died (energy went to zero)
    assertEq(Energy.getEnergy(aliceEntityId), 0, "Player energy should be 0 after fatal fall");

    // Verify player position was cleared
    assertEq(MovablePosition.get(aliceEntityId), vec3(0, 0, 0), "Player position should be cleared after death");

    // Verify inventory was transferred to the entity at death location
    assertInventoryHasObject(entityAtDeathLocation, ObjectTypes.Stone, 10);
    assertInventoryHasObject(entityAtDeathLocation, ObjectTypes.IronOre, 5);

    // Player's inventory should be empty
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory not empty");
  }

  function testMoveHorizontalPathFatal() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    // Add items to player's inventory to test transfer
    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.IronOre, 8);
    TestInventoryUtils.addObject(aliceEntityId, ObjectTypes.Diamond, 3);

    // Create a horizontal path where player will run out of energy at a specific point
    uint32 pathLength = 5;
    uint32 deathIndex = 3;

    // Calculate energy needed to die exactly at deathIndex
    // Energy for moves before death point + 1 energy unit to die at exact position
    uint128 energy = MOVE_ENERGY_COST * deathIndex + 1;

    Energy.set(aliceEntityId, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: energy, drainRate: 0 }));

    // Create a horizontal path
    Vec3[] memory newCoords = new Vec3[](pathLength);
    for (uint32 i = 0; i < pathLength; i++) {
      newCoords[i] = playerCoord + vec3(0, 0, int32(i) + 1);
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] - vec3(0, 1, 0), ObjectTypes.Dirt);
    }

    // Identify the exact death location
    Vec3 expectedDeathCoord = newCoords[deathIndex];

    // Get or create entity at the expected death location
    EntityId entityAtDeathLocation = ReversePosition.get(expectedDeathCoord);

    vm.prank(alice);
    world.move(aliceEntityId, newCoords);

    // Verify player died (energy went to zero)
    assertEq(Energy.getEnergy(aliceEntityId), 0, "Player energy should be 0 after energy depletion");

    // Verify player position was cleared
    assertEq(MovablePosition.get(aliceEntityId), vec3(0, 0, 0), "Player position should be cleared after death");

    // Verify inventory was transferred to the entity at death location
    assertInventoryHasObject(entityAtDeathLocation, ObjectTypes.IronOre, 8);
    assertInventoryHasObject(entityAtDeathLocation, ObjectTypes.Diamond, 3);

    // Player's inventory should be empty
    assertEq(Inventory.length(aliceEntityId), 0, "Player inventory not empty");
  }

  function testMoveFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);

    vm.expectRevert("Caller not allowed");
    world.move(aliceEntityId, newCoords);
  }

  function testMoveFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.move(aliceEntityId, newCoords);
  }
}
