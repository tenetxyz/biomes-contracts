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
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { ChunkCoord } from "../src/Types.sol";
import { VoxelCoord } from "../src/VoxelCoord.sol";
import { CHUNK_SIZE } from "../src/Constants.sol";
import { encodeChunk } from "./utils/encodeChunk.sol";
import { testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

int32 constant GRASS_LEVEL = 4;

contract MineTest is BiomesTest {
  function setupFlatChunk(VoxelCoord memory coord) internal {
    uint8[][][] memory chunk = _getFlatChunk();
    bytes memory encodedChunk = encodeChunk(chunk);
    ChunkCoord memory chunkCoord = coord.toChunkCoord();
    bytes32[] memory merkleProof = new bytes32[](0);

    world.exploreChunk(chunkCoord, encodedChunk, merkleProof);
  }

  function _getFlatChunk() internal pure returns (uint8[][][] memory chunk) {
    chunk = new uint8[][][](uint256(int256(CHUNK_SIZE)));
    for (uint256 x = 0; x < uint256(int256(CHUNK_SIZE)); x++) {
      chunk[x] = new uint8[][](uint256(int256(CHUNK_SIZE)));
      for (uint256 y = 0; y < uint256(int256(CHUNK_SIZE)); y++) {
        chunk[x][y] = new uint8[](uint256(int256(CHUNK_SIZE)));
        for (uint256 z = 0; z < uint256(int256(CHUNK_SIZE)); z++) {
          if (y < uint256(int256(GRASS_LEVEL))) {
            chunk[x][y][z] = uint8(ObjectTypeId.unwrap(DirtObjectID));
          } else if (y == uint256(int256(GRASS_LEVEL))) {
            chunk[x][y][z] = uint8(ObjectTypeId.unwrap(GrassObjectID));
          } else {
            chunk[x][y][z] = uint8(ObjectTypeId.unwrap(AirObjectID));
          }
        }
      }
    }
  }

  function testMineTerrain() public {
    VoxelCoord memory coord = VoxelCoord(0, 0, 0);
    setupFlatChunk(coord);

    VoxelCoord memory spawnCoord = VoxelCoord(1, GRASS_LEVEL + 1, 1);
    (EntityId aliceEntityId, address alice) = createTestPlayer(spawnCoord);

    ObjectTypeId terrainObjectTypeId = GrassObjectID;

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x + 1, GRASS_LEVEL, spawnCoord.z);

    vm.prank(alice);

    startGasReport("mine terrain");
    world.mine(mineCoord);
    endGasReport();

    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID);
    assertTrue(InventoryCount.get(aliceEntityId, terrainObjectTypeId) == 1);
    assertTrue(InventorySlots.get(aliceEntityId) == 1);
    assertTrue(testInventoryObjectsHasObjectType(aliceEntityId, terrainObjectTypeId));
  }

  function testMineNonTerrain() public {}

  function testMineMultiSize() public {}

  function testMineInForceField() public {}

  function testMineOre() public {}

  function testMineFailsIfForceField() public {}

  function testMineFailsIfInvalidBlock() public {}

  function testMineFailsIfInvalidCoord() public {}

  function testMineFailsIfNotEnoughEnergy() public {}

  function testMineFailsIfInventoryFull() public {}

  function testMineFailsIfLoggedOut() public {}

  function testMineFailsIfNoPlayer() public {}

  function testMineFailsIfHasEnergy() public {}
}
