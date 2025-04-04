// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { console } from "forge-std/console.sol";

import { EntityId } from "../src/EntityId.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";

import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";

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
  ReversePosition
} from "../src/utils/Vec3Storage.sol";

import { CHUNK_SIZE, MACHINE_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { TestUtils } from "./utils/TestUtils.sol";

contract EnergyTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testPlayerLosesEnergyWhenIdle() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    // pass some time
    vm.warp(block.timestamp + 2);
    world.activatePlayer(alice);

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMachineLosesEnergyWhenIdle() public {
    (,, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 forceFieldCoord = playerCoord + vec3(0, 0, 1);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000, drainRate: MACHINE_ENERGY_DRAIN_RATE })
    );

    uint128 forceFieldEnergyBefore = Energy.getEnergy(forceFieldEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    // pass some time
    vm.warp(block.timestamp + 2);
    world.activate(forceFieldEntityId);

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    assertEq(
      Energy.getEnergy(forceFieldEntityId), forceFieldEnergyBefore - energyGainedInPool, "Machine did not lose energy"
    );
  }
}
