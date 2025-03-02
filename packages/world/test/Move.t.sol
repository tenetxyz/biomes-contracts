// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ExploredChunk } from "../src/codegen/tables/ExploredChunk.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex } from "../src/codegen/tables/ExploredChunkByIndex.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerPosition } from "../src/codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../src/codegen/tables/ReversePlayerPosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, SmartChestObjectID, TextSignObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X, MAX_PLAYER_JUMPS, MAX_PLAYER_GLIDES } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract MoveTest is BiomesTest {
  function _testMoveMultipleBlocks(address player, uint8 numBlocksToMove, bool overTerrain) internal {
    EntityId playerEntityId = Player.get(player);
    Vec3 startingCoord = PlayerPosition.get(playerEntityId);
    Vec3[] memory newCoords = new Vec3[](numBlocksToMove);
    for (int32 i = 0; i < numBlocksToMove; i++) {
      newCoords[i] = startingCoord + vec3(0, 0, i + 1);

      Vec3 belowCoord = newCoords[i] - vec3(0, 1, 0);
      Vec3 aboveCoord = newCoords[i] + vec3(0, 1, 0);
      if (overTerrain) {
        setTerrainAtCoord(newCoords[i], AirObjectID);
        setTerrainAtCoord(aboveCoord, AirObjectID);
        setTerrainAtCoord(belowCoord, GrassObjectID);
      } else {
        setObjectAtCoord(newCoords[i], AirObjectID);
        setObjectAtCoord(aboveCoord, AirObjectID);
        setObjectAtCoord(belowCoord, GrassObjectID);
      }
    }

    uint128 energyBefore = Energy.getEnergy(playerEntityId);
    Vec3 shardCoord = startingCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(player);
    startGasReport(
      string.concat("move ", Strings.toString(numBlocksToMove), " blocks ", overTerrain ? "terrain" : "non-terrain")
    );
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(playerEntityId);
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(finalCoord == newCoords[numBlocksToMove - 1], "Player did not move to the correct coord");
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == playerEntityId,
      "Above coord is not the player"
    );
    assertEq(EntityId.unwrap(ReversePlayerPosition.get(startingCoord)), bytes32(0), "Player position was not deleted");
    assertEq(
      EntityId.unwrap(ReversePlayerPosition.get(startingCoord)),
      bytes32(0),
      "Above starting coord is not the player"
    );

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(playerEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
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
    for (int32 i = 0; i < numJumps; i++) {
      newCoords[i] = playerCoord + vec3(0, i + 1, 0);
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    startGasReport("move single jump");
    world.move(newCoords);
    endGasReport();

    // Expect the player to fall down back to the original coord
    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == playerCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveGlide() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numGlides = 2;
    Vec3[] memory newCoords = new Vec3[](numGlides + 1);
    for (int32 i = 0; i < newCoords.length; i++) {
      newCoords[i] = playerCoord + vec3(0, 1, 0);
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }
    Vec3 expectedFinalCoord = playerCoord + vec3(0, 0, int32(int256(numGlides)));
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), GrassObjectID);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    world.move(newCoords);

    // Expect the player to fall down back after the last block
    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == expectedFinalCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveThroughWater() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupWaterChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](3);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 1, 1);
    newCoords[2] = playerCoord + vec3(0, 0, 2);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    world.move(newCoords);

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == newCoords[newCoords.length - 1], "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveEndAtStart() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](4);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);
    newCoords[2] = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[3] = vec3(playerCoord.x, playerCoord.y, playerCoord.z);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    world.move(newCoords);

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == playerCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
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
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1];
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), GrassObjectID);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    world.move(newCoords);

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == expectedFinalCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = vec3(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveFailsIfInvalidJump() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numJumps = MAX_PLAYER_JUMPS + 1;
    Vec3[] memory newCoords = new Vec3[](numJumps);
    for (uint8 i = 0; i < numJumps; i++) {
      newCoords[i] = playerCoord + vec3(0, int32(int(uint(i))) + 1, 0);
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Cannot jump more than 3 blocks");
    world.move(newCoords);
  }

  function testMoveFailsIfInvalidGlide() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint256 numGlides = MAX_PLAYER_GLIDES + 1;
    Vec3[] memory newCoords = new Vec3[](numGlides + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      newCoords[i] = playerCoord + vec3(0, 1, int32(int(uint(i))));
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Cannot glide more than 10 blocks");
    world.move(newCoords);
  }

  function testMoveFailsIfNonPassable() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    setObjectAtCoord(newCoords[1], DirtObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.move(newCoords);

    setObjectAtCoord(newCoords[0] + vec3(0, 1, 0), DirtObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.move(newCoords);
  }

  function testMoveFailsIfPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, Vec3 bobCoord) = spawnPlayerOnAirChunk(
      vec3(aliceCoord.x, aliceCoord.y, aliceCoord.z + 2)
    );

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = aliceCoord + vec3(0, 0, 1);
    newCoords[1] = bobCoord;
    setObjectAtCoord(newCoords[0], AirObjectID);
    setObjectAtCoord(newCoords[0] + vec3(0, 1, 0), AirObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.move(newCoords);

    newCoords[1] = bobCoord + vec3(0, 1, 0);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.move(newCoords);
  }

  function testMoveFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 3);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("New coord is too far from old coord");
    world.move(newCoords);

    newCoords[1] = vec3(WORLD_BORDER_LOW_X - 1, playerCoord.y, playerCoord.z + 2); // Can't use vector addition here due to WORLD_BORDER_LOW_X

    vm.prank(alice);
    vm.expectRevert("Cannot move outside the world border");
    world.move(newCoords);

    newCoords[0] = playerCoord - vec3(1, 0, 0);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(newCoords);
  }

  function testMoveFatal() public {}

  function testMoveFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }

    vm.expectRevert("Player does not exist");
    world.move(newCoords);
  }

  function testMoveFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](2);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    newCoords[1] = playerCoord + vec3(0, 0, 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.move(newCoords);
  }
}
