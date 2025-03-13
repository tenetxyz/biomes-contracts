// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";

import { OreCommitment, MinedOrePosition, LocalEnergyPool, ReversePosition, Position } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { CHUNK_SIZE, CHUNK_COMMIT_EXPIRY_BLOCKS } from "../src/Constants.sol";

contract OreTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function exploreChunk(Vec3 coord) internal {
    Vec3 chunkCoord = coord.toChunkCoord();

    address chunkPtr = TerrainLib._getChunkPointer(chunkCoord, worldAddress);

    // Set chunk's code to non zero
    bytes memory chunkData = hex"00";
    vm.etch(chunkPtr, chunkData);
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
    ObjectType.set(entityId, ObjectTypes.Air);

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
    ObjectType.set(entityId, ObjectTypes.Air);

    address alice = vm.randomAddress();

    vm.prank(alice);
    vm.expectRevert("No ores available for respawn");
    world.respawnOre(block.number - 1);
  }
}
