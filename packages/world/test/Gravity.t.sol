// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";

import { MinedOrePosition, ExploredChunk, ExploredChunkByIndex, ForceField, LocalEnergyPool, ReversePosition, PlayerPosition, ReversePlayerPosition, Position, OreCommitment } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, SmartChestObjectID, TextSignObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract GravityTest is BiomesTest {
  function testMineFallSingleBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = playerCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with single block fall");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == mineCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = playerCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(mineCoord - vec3(0, 1, 0), AirObjectID);
    setTerrainAtCoord(mineCoord - vec3(0, 2, 0), AirObjectID);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with three block fall");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == mineCoord - vec3(0, 2, 0), "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineFallFatal() public {}

  function testMineStackedPlayers() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupFlatChunkWithPlayer();

    EntityId bobEntityId;
    {
      Vec3 bobCoord = aliceCoord + vec3(0, 2, 0);
      setObjectAtCoord(bobCoord, AirObjectID);
      setObjectAtCoord(bobCoord + vec3(0, 1, 0), AirObjectID);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    Vec3 mineCoord = aliceCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(mineCoord - vec3(0, 1, 0), AirObjectID);
    setTerrainAtCoord(mineCoord - vec3(0, 2, 0), AirObjectID);

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    startGasReport("mine with three block fall with a stacked player");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalAliceCoord = PlayerPosition.get(aliceEntityId);
    Vec3 finalBobCoord = PlayerPosition.get(bobEntityId);
    assertTrue(finalAliceCoord == mineCoord - vec3(0, 2, 0), "Player alice did not move to new coords");
    assertTrue(finalBobCoord == mineCoord, "Player bob did not move to new coords");
    {
      Vec3 aboveFinalAliceCoord = finalAliceCoord + vec3(0, 1, 0);
      assertTrue(
        BaseEntity.get(ReversePlayerPosition.get(aboveFinalAliceCoord)) == aliceEntityId,
        "Above coord is not the player alice"
      );
      Vec3 aboveFinalBobCoord = finalBobCoord + vec3(0, 1, 0);
      assertTrue(
        BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord)) == bobEntityId,
        "Above coord is not the player bob"
      );
    }

    mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    uint128 aliceEnergyAfter = Energy.getEnergy(aliceEntityId);
    uint128 bobEnergyAfter = Energy.getEnergy(bobEntityId);
    assertEq(
      energyGainedInPool,
      (aliceEnergyBefore - aliceEnergyAfter) + (bobEnergyBefore - bobEnergyAfter),
      "Alice and Bob did not lose energy"
    );
  }

  function testMoveFallSingleBlocok() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1] - vec3(0, 1, 0);
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), DirtObjectID);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move with single block fall");
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 1, 0), AirObjectID);
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 2, 0), AirObjectID);
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1] - vec3(0, 3, 0);
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), DirtObjectID);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move with three block fall");
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveStackedPlayers() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    EntityId bobEntityId;
    {
      Vec3 bobCoord = aliceCoord + vec3(0, 2, 0);
      setObjectAtCoord(bobCoord, AirObjectID);
      setObjectAtCoord(bobCoord + vec3(0, 1, 0), AirObjectID);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = aliceCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 1, 0), AirObjectID);
    setObjectAtCoord(newCoords[newCoords.length - 1] - vec3(0, 2, 0), AirObjectID);
    Vec3 expectedFinalAliceCoord = newCoords[newCoords.length - 1] - vec3(0, 3, 0);
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(expectedFinalAliceCoord - vec3(0, 1, 0), DirtObjectID);

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord);

    vm.prank(alice);
    startGasReport("move with three block fall with a stacked player");
    world.move(newCoords);
    endGasReport();

    Vec3 finalAliceCoord = PlayerPosition.get(aliceEntityId);
    Vec3 finalBobCoord = PlayerPosition.get(bobEntityId);
    assertTrue(finalAliceCoord == expectedFinalAliceCoord, "Player alice did not move to new coords");
    assertTrue(finalBobCoord == aliceCoord, "Player bob did not move to new coords");
    Vec3 aboveFinalAliceCoord = finalAliceCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalAliceCoord)) == aliceEntityId,
      "Above coord is not the player alice"
    );
    Vec3 aboveFinalBobCoord = finalBobCoord + vec3(0, 1, 0);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord)) == bobEntityId,
      "Above coord is not the player bob"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    uint128 aliceEnergyAfter = Energy.getEnergy(aliceEntityId);
    uint128 bobEnergyAfter = Energy.getEnergy(bobEntityId);
    assertEq(
      energyGainedInPool,
      (aliceEnergyBefore - aliceEnergyAfter) + (bobEnergyBefore - bobEnergyAfter),
      "Alice and Bob did not lose energy"
    );
  }

  function testMoveFallFatal() public {}

  function testMoveFailsIfGravityOutsideExploredChunk() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = playerCoord + vec3(0, 0, 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(newCoords[i] + vec3(0, 1, 0), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(newCoords);
  }
}
