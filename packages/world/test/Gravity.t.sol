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
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X, PLAYER_FALL_ENERGY_COST } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract GravityTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function testMineFallSingleBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = playerCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
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
    assertEq(finalCoord, mineCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)),
      aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost = assertEnergyFlowedFromPlayerToLocalPool(
      beforeEnergyDataSnapshot,
      afterEnergyDataSnapshot
    );
    assertLt(playerEnergyLost, PLAYER_FALL_ENERGY_COST, "Player energy lost is not less than the move energy cost");
  }

  function testMineFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = playerCoord - vec3(0, 1, 0);
    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(mineCoord - vec3(0, 1, 0), ObjectTypes.Air);
    setTerrainAtCoord(mineCoord - vec3(0, 2, 0), ObjectTypes.Air);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with three block fall");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertEq(finalCoord, mineCoord - vec3(0, 2, 0), "Player did not move to new coords");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)),
      aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost = assertEnergyFlowedFromPlayerToLocalPool(
      beforeEnergyDataSnapshot,
      afterEnergyDataSnapshot
    );
    assertGt(playerEnergyLost, PLAYER_FALL_ENERGY_COST, "Player energy lost is not greater than the move energy cost");
  }

  function testMineFallFatal() public {
    // TODO: implement
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
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
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
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalAliceCoord = PlayerPosition.get(aliceEntityId);
    Vec3 finalBobCoord = PlayerPosition.get(bobEntityId);
    assertEq(finalAliceCoord, mineCoord - vec3(0, 2, 0), "Player alice did not move to new coords");
    assertEq(finalBobCoord, mineCoord, "Player bob did not move to new coords");
    {
      Vec3 aboveFinalAliceCoord = finalAliceCoord + vec3(0, 1, 0);
      assertEq(
        BaseEntity.get(ReversePlayerPosition.get(aboveFinalAliceCoord)),
        aliceEntityId,
        "Above coord is not the player alice"
      );
      Vec3 aboveFinalBobCoord = finalBobCoord + vec3(0, 1, 0);
      assertEq(
        BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord)),
        bobEntityId,
        "Above coord is not the player bob"
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
    assertGt(aliceEnergyBefore - aliceEnergyAfter, PLAYER_FALL_ENERGY_COST, "Alice did not lose energy");
    assertGt(bobEnergyBefore - bobEnergyAfter, PLAYER_FALL_ENERGY_COST, "Bob did not lose energy");
  }

  function testMoveFallSingleBlocok() public {
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

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move with single block fall");
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertEq(finalCoord, expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)),
      aliceEntityId,
      "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost = assertEnergyFlowedFromPlayerToLocalPool(
      beforeEnergyDataSnapshot,
      afterEnergyDataSnapshot
    );
    assertGt(playerEnergyLost, PLAYER_FALL_ENERGY_COST, "Player energy lost is not greater than the move energy cost");
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
    Vec3 expectedFinalCoord = newCoords[newCoords.length - 1] - vec3(0, 3, 0);
    setObjectAtCoord(newCoords[newCoords.length - 1], ObjectTypes.Air);
    setObjectAtCoord(expectedFinalCoord - vec3(0, 1, 0), ObjectTypes.Dirt);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move with three block fall");
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertEq(finalCoord, expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = finalCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)),
      aliceEntityId,
      "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    uint128 playerEnergyLost = assertEnergyFlowedFromPlayerToLocalPool(
      beforeEnergyDataSnapshot,
      afterEnergyDataSnapshot
    );
    assertGt(playerEnergyLost, PLAYER_FALL_ENERGY_COST, "Player energy lost is not greater than the move energy cost");
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
    Vec3 expectedFinalAliceCoord = newCoords[newCoords.length - 1] - vec3(0, 3, 0);
    setObjectAtCoord(newCoords[newCoords.length - 1], ObjectTypes.Air);
    setObjectAtCoord(expectedFinalAliceCoord - vec3(0, 1, 0), ObjectTypes.Dirt);

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
    assertEq(finalAliceCoord, expectedFinalAliceCoord, "Player alice did not move to new coords");
    assertEq(finalBobCoord, aliceCoord, "Player bob did not move to new coords");
    Vec3 aboveFinalAliceCoord = finalAliceCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalAliceCoord)),
      aliceEntityId,
      "Above coord is not the player alice"
    );
    Vec3 aboveFinalBobCoord = finalBobCoord + vec3(0, 1, 0);
    assertEq(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord)),
      bobEntityId,
      "Above coord is not the player bob"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertGt(energyGainedInPool, 0, "Local energy pool did not gain energy");
    uint128 aliceEnergyAfter = Energy.getEnergy(aliceEntityId);
    uint128 bobEnergyAfter = Energy.getEnergy(bobEntityId);
    assertEq(
      energyGainedInPool,
      (aliceEnergyBefore - aliceEnergyAfter) + (bobEnergyBefore - bobEnergyAfter),
      "Alice and Bob did not lose energy"
    );
    assertGt(aliceEnergyBefore - aliceEnergyAfter, PLAYER_FALL_ENERGY_COST, "Alice did not lose energy");
    assertGt(bobEnergyBefore - bobEnergyAfter, PLAYER_FALL_ENERGY_COST, "Bob did not lose energy");
  }

  function testMoveFallFatal() public {
    // TODO: implement
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
    world.move(newCoords);
  }
}
