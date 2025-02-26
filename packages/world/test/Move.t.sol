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
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
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
      newCoords[i] = VoxelCoord(startingCoord.x, startingCoord.y, startingCoord.z + int16(int(uint(i))) + 1);

      // Check if the chunk is explored
      ChunkCoord memory chunkCoord = newCoords[i].toChunkCoord();
      if (!TerrainLib._isChunkExplored(chunkCoord, worldAddress)) {
        setupAirChunk(newCoords[i]);
      }

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

  function testMoveJump() public {}

  function testMoveGlide() public {}

  function testMoveFailsIfInvalidJump() public {}

  function testMoveFailsIfInvalidGlide() public {}

  function testMoveFailsIfNonPassable() public {}

  function testMoveFailsIfPlayer() public {}

  function testMoveFailsIfInvalidCoord() public {}

  function testMoveFailsIfNotEnoughEnergy() public {}

  function testMoveFailsIfNoPlayer() public {}

  function testMoveFailsIfLoggedOut() public {}
}
