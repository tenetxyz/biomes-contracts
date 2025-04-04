// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
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

import { CHUNK_SIZE, MINE_ENERGY_COST, MOVE_ENERGY_COST, PLAYER_FALL_ENERGY_COST } from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract GravityTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testMineFallSingleBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = playerCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction);
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with single block fall");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, mineCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost =
      assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      playerEnergyLost, playerHandMassReduction, "Player shouldn't have lost energy from falling a safe distance"
    );
  }

  function testMineFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = playerCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction);
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(mineCoord - vec3(0, 1, 0), ObjectTypes.Air);
    setTerrainAtCoord(mineCoord - vec3(0, 2, 0), ObjectTypes.Air);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with three block fall");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, mineCoord - vec3(0, 2, 0), "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost =
      assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      playerEnergyLost,
      playerHandMassReduction + PLAYER_FALL_ENERGY_COST,
      "Player should have lost energy from mining and a single fall"
    );
  }

  function testMineFallFatal() public {
    vm.skip(true, "TODO");
  }

  function testMineStackedPlayers() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupFlatChunkWithPlayer();

    EntityId bobEntityId;
    {
      Vec3 bobCoord = aliceCoord + vec3(0, 2, 0);
      setObjectAtCoord(bobCoord, ObjectTypes.Air);
      setObjectAtCoord(bobCoord + vec3(0, 1, 0), ObjectTypes.Air);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    Vec3 mineCoord = aliceCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction);
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(mineCoord - vec3(0, 1, 0), ObjectTypes.Air);
    setTerrainAtCoord(mineCoord - vec3(0, 2, 0), ObjectTypes.Air);

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    startGasReport("mine with three block fall with a stacked player");
    world.mine(aliceEntityId, mineCoord, "");
    endGasReport();

    Vec3 finalAliceCoord = MovablePosition.get(aliceEntityId);
    Vec3 finalBobCoord = MovablePosition.get(bobEntityId);
    assertEq(finalAliceCoord, mineCoord - vec3(0, 2, 0), "Player alice did not move to new coords");
    assertEq(finalBobCoord, mineCoord, "Player bob did not move to new coords");
    {
      Vec3 aboveFinalAliceCoord = finalAliceCoord + vec3(0, 1, 0);
      assertEq(
        BaseEntity.get(ReverseMovablePosition.get(aboveFinalAliceCoord)),
        aliceEntityId,
        "Above coord is not the player alice"
      );
      Vec3 aboveFinalBobCoord = finalBobCoord + vec3(0, 1, 0);
      assertEq(
        BaseEntity.get(ReverseMovablePosition.get(aboveFinalBobCoord)), bobEntityId, "Above coord is not the player bob"
      );
    }

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    uint128 aliceEnergyAfter = Energy.getEnergy(aliceEntityId);
    uint128 bobEnergyAfter = Energy.getEnergy(bobEntityId);
    assertEq(
      energyGainedInPool,
      (aliceEnergyBefore - aliceEnergyAfter) + (bobEnergyBefore - bobEnergyAfter),
      "Alice and Bob did not lose energy"
    );
    assertEq(
      aliceEnergyBefore - aliceEnergyAfter,
      playerHandMassReduction + PLAYER_FALL_ENERGY_COST,
      "Alice did not lose energy"
    );
    assertEq(bobEnergyBefore - bobEnergyAfter, PLAYER_FALL_ENERGY_COST, "Bob did not lose energy");
  }

  function testMoveFallSingleBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1] - vec3(0, 1, 0);
    setObjectAtCoord(newCoords[newCoords.length - 1], ObjectTypes.Air);
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), ObjectTypes.Dirt);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, expectedFinalCoord);

    vm.prank(alice);
    startGasReport("move with single block fall");
    world.move(aliceEntityId, newCoords);
    endGasReport();

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, expectedFinalCoord);
    uint128 playerEnergyLost =
      assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(playerEnergyLost, MOVE_ENERGY_COST, "Player should only lose energy from the initial move");
  }

  function testMoveFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 1, 0), ObjectTypes.Air);
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 2, 0), ObjectTypes.Air);
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 3, 0), ObjectTypes.Air);
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1] - vec3(0, 3, 0);
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), ObjectTypes.Dirt);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, expectedFinalCoord);

    vm.prank(alice);
    startGasReport("move with three block fall");
    world.move(aliceEntityId, newCoords);
    endGasReport();

    Vec3 finalCoord = MovablePosition.get(aliceEntityId);
    assertEq(finalCoord, expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalCoord)), aliceEntityId, "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, expectedFinalCoord);
    uint128 playerEnergyLost =
      assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      playerEnergyLost,
      MOVE_ENERGY_COST + PLAYER_FALL_ENERGY_COST,
      "Player energy lost should equal one move and one fall"
    );
  }

  function testMoveStackedPlayers() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    EntityId bobEntityId;
    {
      Vec3 bobCoord = aliceCoord + vec3(0, 2, 0);
      setObjectAtCoord(bobCoord, ObjectTypes.Air);
      setObjectAtCoord(bobCoord + vec3(0, 1, 0), ObjectTypes.Air);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = aliceCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 1, 0), ObjectTypes.Air);
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 2, 0), ObjectTypes.Air);
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 3, 0), ObjectTypes.Air);
    Vec3 expectedFinalAliceCoord = newCoords[newCoords.length - 1] - vec3(0, 3, 0);
    setObjectAtCoord(expectedFinalAliceCoord - vec3(0, 1, 0), ObjectTypes.Dirt);

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = expectedFinalAliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    startGasReport("move with three block fall with a stacked player");
    world.move(aliceEntityId, newCoords);
    endGasReport();

    Vec3 finalAliceCoord = MovablePosition.get(aliceEntityId);
    Vec3 finalBobCoord = MovablePosition.get(bobEntityId);
    assertEq(finalAliceCoord, expectedFinalAliceCoord, "Player alice did not move to new coords");
    assertEq(finalBobCoord, aliceCoord, "Player bob did not move to new coords");
    Vec3 aboveFinalAliceCoord = finalAliceCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalAliceCoord)),
      aliceEntityId,
      "Above coord is not the player alice"
    );
    Vec3 aboveFinalBobCoord = finalBobCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReverseMovablePosition.get(aboveFinalBobCoord)), bobEntityId, "Above coord is not the player bob"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    uint128 aliceEnergyAfter = Energy.getEnergy(aliceEntityId);
    uint128 bobEnergyAfter = Energy.getEnergy(bobEntityId);
    assertEq(energyGainedInPool, aliceEnergyBefore - aliceEnergyAfter, "Energy was not transferred to pool from alice");
    assertGt(aliceEnergyBefore - aliceEnergyAfter, PLAYER_FALL_ENERGY_COST, "Alice did not lose energy");
    assertEq(bobEnergyBefore, bobEnergyAfter, "Bob lost energy");
  }

  function testMoveFallFatal() public {
    vm.skip(true, "TODO");
  }

  function testMoveFailsIfGravityOutsideExploredChunk() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], ObjectTypes.Air);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), ObjectTypes.Air);
    }

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(aliceEntityId, newCoords);
  }
}
