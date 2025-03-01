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
import { Vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract GravityTest is BiomesTest {
  function testMineFallSingleBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShard();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine with single block fall");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == mineCoord, "Player did not move to new coords");
    Vec3 aboveFinalCoord = vec3(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    setTerrainAtCoord(vec3(mineCoord.x, mineCoord.y - 1, mineCoord.z), AirObjectID);
    setTerrainAtCoord(vec3(mineCoord.x, mineCoord.y - 2, mineCoord.z), AirObjectID);

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine with three block fall");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == vec3(mineCoord.x, mineCoord.y - 2, mineCoord.z), "Player did not move to new coords");
    Vec3 aboveFinalCoord = vec3(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMineFallFatal() public {}

  function testMineStackedPlayers() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupFlatChunkWithPlayer();

    EntityId bobEntityId;
    {
      Vec3 bobCoord = vec3(aliceCoord.x, aliceCoord.y + 2, aliceCoord.z);
      setObjectAtCoord(bobCoord, AirObjectID);
      setObjectAtCoord(vec3(bobCoord.x, bobCoord.y + 1, bobCoord.z), AirObjectID);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    Vec3 mineCoord = vec3(aliceCoord.x, aliceCoord.y - 1, aliceCoord.z);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 0, "Inventory count is not 0");

    setTerrainAtCoord(vec3(mineCoord.x, mineCoord.y - 1, mineCoord.z), AirObjectID);
    setTerrainAtCoord(vec3(mineCoord.x, mineCoord.y - 2, mineCoord.z), AirObjectID);

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine with three block fall with a stacked player");
    world.mine(mineCoord);
    endGasReport();

    Vec3 finalAliceCoord = PlayerPosition.get(aliceEntityId);
    Vec3 finalBobCoord = PlayerPosition.get(bobEntityId);
    assertTrue(
      finalAliceCoord == vec3(mineCoord.x, mineCoord.y - 2, mineCoord.z),
      "Player alice did not move to new coords"
    );
    assertTrue(finalBobCoord == vec3(mineCoord.x, mineCoord.y, mineCoord.z), "Player bob did not move to new coords");
    {
      Vec3 aboveFinalAliceCoord = vec3(finalAliceCoord.x, finalAliceCoord.y + 1, finalAliceCoord.z);
      assertTrue(
        BaseEntity.get(
          ReversePlayerPosition.get(aboveFinalAliceCoord.x, aboveFinalAliceCoord.y, aboveFinalAliceCoord.z)
        ) == aliceEntityId,
        "Above coord is not the player alice"
      );
      Vec3 aboveFinalBobCoord = vec3(finalBobCoord.x, finalBobCoord.y + 1, finalBobCoord.z);
      assertTrue(
        BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord.x, aboveFinalBobCoord.y, aboveFinalBobCoord.z)) ==
          bobEntityId,
        "Above coord is not the player bob"
      );
    }

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertEq(InventoryCount.get(aliceEntityId, mineObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 1");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, mineObjectTypeId),
      "Inventory objects does not have terrain object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
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
    newCoords[0] = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    Vec3 expectedFinalCoord = vec3(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y - 1,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(vec3(expectedFinalCoord.x, expectedFinalCoord.y - 1, expectedFinalCoord.z), DirtObjectID);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("move with single block fall");
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = vec3(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord)) == aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    setObjectAtCoord(
      vec3(newCoords[newCoords.length - 1].x, newCoords[newCoords.length - 1].y - 1, newCoords[newCoords.length - 1].z),
      AirObjectID
    );
    setObjectAtCoord(
      vec3(newCoords[newCoords.length - 1].x, newCoords[newCoords.length - 1].y - 2, newCoords[newCoords.length - 1].z),
      AirObjectID
    );
    Vec3 expectedFinalCoord = vec3(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y - 3,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(vec3(expectedFinalCoord.x, expectedFinalCoord.y - 1, expectedFinalCoord.z), DirtObjectID);

    uint128 energyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("move with three block fall");
    world.move(newCoords);
    endGasReport();

    Vec3 finalCoord = PlayerPosition.get(aliceEntityId);
    assertTrue(finalCoord == expectedFinalCoord, "Player did not fall back to the original coord");
    Vec3 aboveFinalCoord = vec3(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), energyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testMoveStackedPlayers() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    EntityId bobEntityId;
    {
      Vec3 bobCoord = vec3(aliceCoord.x, aliceCoord.y + 2, aliceCoord.z);
      setObjectAtCoord(bobCoord, AirObjectID);
      setObjectAtCoord(vec3(bobCoord.x, bobCoord.y + 1, bobCoord.z), AirObjectID);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    Vec3[] memory newCoords = new Vec3[](1);
    newCoords[0] = vec3(aliceCoord.x, aliceCoord.y, aliceCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    setObjectAtCoord(
      vec3(newCoords[newCoords.length - 1].x, newCoords[newCoords.length - 1].y - 1, newCoords[newCoords.length - 1].z),
      AirObjectID
    );
    setObjectAtCoord(
      vec3(newCoords[newCoords.length - 1].x, newCoords[newCoords.length - 1].y - 2, newCoords[newCoords.length - 1].z),
      AirObjectID
    );
    Vec3 expectedFinalAliceCoord = vec3(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y - 3,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(
      vec3(expectedFinalAliceCoord.x, expectedFinalAliceCoord.y - 1, expectedFinalAliceCoord.z),
      DirtObjectID
    );

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    Vec3 shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("move with three block fall with a stacked player");
    world.move(newCoords);
    endGasReport();

    Vec3 finalAliceCoord = PlayerPosition.get(aliceEntityId);
    Vec3 finalBobCoord = PlayerPosition.get(bobEntityId);
    assertTrue(finalAliceCoord == expectedFinalAliceCoord, "Player alice did not move to new coords");
    assertTrue(finalBobCoord == aliceCoord, "Player bob did not move to new coords");
    Vec3 aboveFinalAliceCoord = vec3(finalAliceCoord.x, finalAliceCoord.y + 1, finalAliceCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalAliceCoord)) == aliceEntityId,
      "Above coord is not the player alice"
    );
    Vec3 aboveFinalBobCoord = vec3(finalBobCoord.x, finalBobCoord.y + 1, finalBobCoord.z);
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
    newCoords[0] = vec3(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(vec3(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(newCoords);
  }
}
