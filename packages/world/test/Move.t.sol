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

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, SmartChestObjectID, TextSignObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X, MAX_PLAYER_JUMPS, MAX_PLAYER_GLIDES } from "../src/Constants.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { ChunkCoord } from "../src/Types.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract MoveTest is BiomesTest {
  using VoxelCoordLib for *;

  function _testMoveMultipleBlocks(address player, uint8 numBlocksToMove, bool overTerrain) internal {
    EntityId playerEntityId = Player.get(player);
    VoxelCoord memory startingCoord = PlayerPosition.get(playerEntityId).toVoxelCoord();
    VoxelCoord[] memory newCoords = new VoxelCoord[](numBlocksToMove);
    for (uint8 i = 0; i < numBlocksToMove; i++) {
      newCoords[i] = VoxelCoord(startingCoord.x, startingCoord.y, startingCoord.z + int32(int(uint(i))) + 1);

      VoxelCoord memory belowCoord = VoxelCoord(newCoords[i].x, newCoords[i].y - 1, newCoords[i].z);
      VoxelCoord memory aboveCoord = VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z);
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
    VoxelCoord memory shardCoord = startingCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(player);
    startGasReport(
      string.concat("move ", Strings.toString(numBlocksToMove), " blocks ", overTerrain ? "terrain" : "non-terrain")
    );
    world.move(newCoords);
    endGasReport();

    VoxelCoord memory finalCoord = PlayerPosition.get(playerEntityId).toVoxelCoord();
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      VoxelCoordLib.equals(finalCoord, newCoords[numBlocksToMove - 1]),
      "Player did not move to the correct coord"
    );
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        playerEntityId,
      "Above coord is not the player"
    );
    assertEq(
      EntityId.unwrap(ReversePlayerPosition.get(startingCoord.x, startingCoord.y, startingCoord.z)),
      bytes32(0),
      "Player position was not deleted"
    );
    assertEq(
      EntityId.unwrap(ReversePlayerPosition.get(startingCoord.x, startingCoord.y + 1, startingCoord.z)),
      bytes32(0),
      "Above starting coord is not the player"
    );

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(playerEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveOneBlockTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 1, true);
  }

  function testMoveOneBlockNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 1, false);
  }

  function testMoveFiveBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 5, true);
  }

  function testMoveFiveBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 5, false);
  }

  function testMoveTenBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 10, true);
  }

  function testMoveTenBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 10, false);
  }

  function testMoveFiftyBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 50, true);
  }

  function testMoveFiftyBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 50, false);
  }

  function testMoveHundredBlocksTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 100, true);
  }

  function testMoveHundredBlocksNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();
    _testMoveMultipleBlocks(alice, 100, false);
  }

  function testMoveJump() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    uint256 numJumps = 1;
    VoxelCoord[] memory newCoords = new VoxelCoord[](numJumps);
    for (uint8 i = 0; i < numJumps; i++) {
      newCoords[i] = VoxelCoord(playerCoord.x, playerCoord.y + int32(int(uint(i))) + 1, playerCoord.z);
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("move single jump");
    world.move(newCoords);
    endGasReport();

    // Expect the player to fall down back to the original coord
    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, playerCoord), "Player did not fall back to the original coord");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveGlide() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    uint256 numGlides = 2;
    VoxelCoord[] memory newCoords = new VoxelCoord[](numGlides + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      newCoords[i] = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z + int32(int(uint(i))));
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    VoxelCoord memory expectedFinalCoord = VoxelCoord(
      playerCoord.x,
      playerCoord.y,
      playerCoord.z + int32(int(uint(numGlides)))
    );
    setObjectAtCoord(VoxelCoord(expectedFinalCoord.x, expectedFinalCoord.y - 1, expectedFinalCoord.z), GrassObjectID);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    world.move(newCoords);

    // Expect the player to fall down back after the last block
    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, expectedFinalCoord), "Player did not move to new coords");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveThroughWater() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupWaterChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](3);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z + 1);
    newCoords[2] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 2);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    world.move(newCoords);

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, newCoords[newCoords.length - 1]), "Player did not move to new coords");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveEndAtStart() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](4);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 2);
    newCoords[2] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[3] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    world.move(newCoords);

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, playerCoord), "Player did not move to new coords");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveOverlapStartingCoord() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](6);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 2);
    newCoords[2] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[3] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z);
    newCoords[4] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z - 1);
    newCoords[5] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z - 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    VoxelCoord memory expectedFinalCoord = VoxelCoord(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(VoxelCoord(expectedFinalCoord.x, expectedFinalCoord.y - 1, expectedFinalCoord.z), GrassObjectID);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    world.move(newCoords);

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, expectedFinalCoord), "Player did not move to new coords");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveFailsIfInvalidJump() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    uint256 numJumps = MAX_PLAYER_JUMPS + 1;
    VoxelCoord[] memory newCoords = new VoxelCoord[](numJumps);
    for (uint8 i = 0; i < numJumps; i++) {
      newCoords[i] = VoxelCoord(playerCoord.x, playerCoord.y + int32(int(uint(i))) + 1, playerCoord.z);
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Cannot jump more than 3 blocks");
    world.move(newCoords);
  }

  function testMoveFailsIfInvalidGlide() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    uint256 numGlides = MAX_PLAYER_GLIDES + 1;
    VoxelCoord[] memory newCoords = new VoxelCoord[](numGlides + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      newCoords[i] = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z + int32(int(uint(i))));
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Cannot glide more than 10 blocks");
    world.move(newCoords);
  }

  function testMoveFailsIfNonPassable() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    setObjectAtCoord(VoxelCoord(newCoords[1].x, newCoords[1].y, newCoords[1].z), DirtObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.move(newCoords);

    setObjectAtCoord(VoxelCoord(newCoords[0].x, newCoords[0].y + 1, newCoords[0].z), DirtObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.move(newCoords);
  }

  function testMoveFailsIfPlayer() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, VoxelCoord memory bobCoord) = spawnPlayerOnAirChunk(
      VoxelCoord(aliceCoord.x, aliceCoord.y, aliceCoord.z + 2)
    );

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(aliceCoord.x, aliceCoord.y, aliceCoord.z + 1);
    newCoords[1] = bobCoord;
    setObjectAtCoord(newCoords[0], AirObjectID);
    setObjectAtCoord(VoxelCoord(newCoords[0].x, newCoords[0].y + 1, newCoords[0].z), AirObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.move(newCoords);

    newCoords[1] = VoxelCoord(bobCoord.x, bobCoord.y + 1, bobCoord.z);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.move(newCoords);
  }

  function testMoveFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 3);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("New coord is too far from old coord");
    world.move(newCoords);

    newCoords[1] = VoxelCoord(WORLD_BORDER_LOW_X - 1, playerCoord.y, playerCoord.z + 2);

    vm.prank(alice);
    vm.expectRevert("Cannot move outside the world border");
    world.move(newCoords);

    newCoords[0] = VoxelCoord(playerCoord.x - 1, playerCoord.y, playerCoord.z);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(newCoords);
  }

  function testMoveFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.expectRevert("Player does not exist");
    world.move(newCoords);
  }

  function testMoveFailsIfLoggedOut() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](2);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    newCoords[1] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 2);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    world.logoffPlayer();

    vm.prank(alice);
    vm.expectRevert("Player isn't logged in");
    world.move(newCoords);
  }
}
