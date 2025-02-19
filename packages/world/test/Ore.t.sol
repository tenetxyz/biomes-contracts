// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";

import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, DirtObjectID, SpawnTileObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord, ChunkCoord } from "../src/Types.sol";
import { CHUNK_SIZE, MAX_PLAYER_ENERGY } from "../src/Constants.sol";

contract OreTest is BiomesTest {
  function randomEntityId() internal returns (EntityId) {
    return EntityId.wrap(bytes32(vm.randomUint()));
  }

  function testOreChunkCommit() public {}

  function testRespawnOre() public {}
}
