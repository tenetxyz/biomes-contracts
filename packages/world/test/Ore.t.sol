// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ExploredChunk } from "../src/codegen/tables/ExploredChunk.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex } from "../src/codegen/tables/ExploredChunkByIndex.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID } from "../src/ObjectTypeIds.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { CHUNK_SIZE, CHUNK_COMMIT_EXPIRY_BLOCKS } from "../src/Constants.sol";

contract OreTest is BiomesTest {
  function exploreChunk(Vec3 coord) internal {
    Vec3 chunkCoord = coord.toChunkCoord();

    address chunkPtr = TerrainLib._getChunkPointer(chunkCoord, worldAddress);

    // Set chunk's code to non zero
    bytes memory chunkData = hex"00";
    vm.etch(chunkPtr, chunkData);

    ExploredChunk.set(chunkCoord, address(0));
    uint256 exploredChunkCount = ExploredChunkCount.get();
    ExploredChunkByIndex.set(exploredChunkCount, chunkCoord);
    ExploredChunkCount.set(exploredChunkCount + 1);
  }

  function addMinedOre(Vec3 coord) internal {
    uint256 count = TotalMinedOreCount.get();
    TotalMinedOreCount.set(count + 1);
    MinedOrePosition.set(count, coord);
  }

  function testOreChunkCommit() public {
    Vec3 coord = vec3(0, 0, 0);
    Vec3 chunkCoord = coord.toChunkCoord();
    exploreChunk(coord);

    (address alice, ) = createTestPlayer(coord);

    vm.prank(alice);
    world.oreChunkCommit(chunkCoord);

    assertEq(OreCommitment.get(chunkCoord), block.number + 1);
  }

  function testOreChunkCommitCannotCommitIfExisting() public {
    Vec3 coord = vec3(0, 0, 0);
    Vec3 chunkCoord = coord.toChunkCoord();
    exploreChunk(coord);

    (address alice, ) = createTestPlayer(coord);

    vm.prank(alice);
    world.oreChunkCommit(chunkCoord);

    vm.roll(block.number + 1 + CHUNK_COMMIT_EXPIRY_BLOCKS);

    vm.prank(alice);
    vm.expectRevert("Existing ore commitment");
    world.oreChunkCommit(chunkCoord);

    // Next block it should be possible to commit
    vm.roll(block.number + 1);
    vm.prank(alice);
    world.oreChunkCommit(chunkCoord);

    assertEq(OreCommitment.get(chunkCoord), block.number + 1);
  }

  function testRespawnOre() public {
    Vec3 minedOreCoord = vec3(0, 0, 0);

    addMinedOre(minedOreCoord);

    // Burn ore so it becomes available to respawn
    TotalBurnedOreCount.set(1);

    // Set coord to air
    EntityId entityId = randomEntityId();
    ReversePosition.set(minedOreCoord, entityId);
    ObjectType.set(entityId, AirObjectID);

    address alice = vm.randomAddress();

    vm.prank(alice);
    world.respawnOre(block.number - 1);

    assertEq(TotalMinedOreCount.get(), 0);
    assertEq(TotalBurnedOreCount.get(), 0);

    // Check that the air entity was removed
    assertTrue(ObjectType.get(entityId).isNull());
  }

  function testRespawnOreFailsIfNoBurnedOres() public {
    Vec3 minedOreCoord = vec3(0, 0, 0);

    addMinedOre(minedOreCoord);

    // Set coord to air
    EntityId entityId = randomEntityId();
    ReversePosition.set(minedOreCoord, entityId);
    ObjectType.set(entityId, AirObjectID);

    address alice = vm.randomAddress();

    vm.prank(alice);
    vm.expectRevert("No ores available for respawn");
    world.respawnOre(block.number - 1);
  }
}
