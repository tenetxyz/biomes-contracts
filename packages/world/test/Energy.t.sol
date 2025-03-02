// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
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
import { Vec3, vec3 } from "../src/Vec3.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X, MACHINE_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract EnergyTest is BiomesTest {
  function testPlayerLosesEnergyWhenIdle() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    // pass some time
    vm.warp(block.timestamp + 2);
    world.activatePlayer(alice);

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMachineLosesEnergyWhenIdle() public {
    (, , Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 forceFieldCoord = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({
        lastUpdatedTime: uint128(block.timestamp),
        energy: 10000,
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    uint128 forceFieldEnergyBefore = Energy.getEnergy(forceFieldEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    // pass some time
    vm.warp(block.timestamp + 2);
    world.activate(forceFieldEntityId);

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(
      Energy.getEnergy(forceFieldEntityId),
      forceFieldEnergyBefore - energyGainedInPool,
      "Machine did not lose energy"
    );
  }
}
