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
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract GravityTest is BiomesTest {
  using VoxelCoordLib for *;

  function testMineFallSingleBlock() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupFlatChunkWithPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with single block fall");
    world.mine(mineCoord);
    endGasReport();

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, mineCoord), "Player did not move to new coords");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupFlatChunkWithPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(playerCoord.x, playerCoord.y - 1, playerCoord.z);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(VoxelCoord(mineCoord.x, mineCoord.y - 1, mineCoord.z), AirObjectID);
    setTerrainAtCoord(VoxelCoord(mineCoord.x, mineCoord.y - 2, mineCoord.z), AirObjectID);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("mine with three block fall");
    world.mine(mineCoord);
    endGasReport();

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(
      VoxelCoordLib.equals(finalCoord, VoxelCoord(mineCoord.x, mineCoord.y - 2, mineCoord.z)),
      "Player did not move to new coords"
    );
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMineFallFatal() public {
    // TODO: implement
  }

  function testMineStackedPlayers() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory aliceCoord) = setupFlatChunkWithPlayer();

    EntityId bobEntityId;
    {
      VoxelCoord memory bobCoord = VoxelCoord(aliceCoord.x, aliceCoord.y + 2, aliceCoord.z);
      setObjectAtCoord(bobCoord, AirObjectID);
      setObjectAtCoord(VoxelCoord(bobCoord.x, bobCoord.y + 1, bobCoord.z), AirObjectID);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    VoxelCoord memory mineCoord = VoxelCoord(aliceCoord.x, aliceCoord.y - 1, aliceCoord.z);
    ObjectTypeId mineObjectTypeId = ObjectTypeId.wrap(TerrainLib.getBlockType(mineCoord));
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    EntityId mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    setTerrainAtCoord(VoxelCoord(mineCoord.x, mineCoord.y - 1, mineCoord.z), AirObjectID);
    setTerrainAtCoord(VoxelCoord(mineCoord.x, mineCoord.y - 2, mineCoord.z), AirObjectID);

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("mine with three block fall with a stacked player");
    world.mine(mineCoord);
    endGasReport();

    VoxelCoord memory finalAliceCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    VoxelCoord memory finalBobCoord = PlayerPosition.get(bobEntityId).toVoxelCoord();
    assertTrue(
      VoxelCoordLib.equals(finalAliceCoord, VoxelCoord(mineCoord.x, mineCoord.y - 2, mineCoord.z)),
      "Player alice did not move to new coords"
    );
    assertTrue(
      VoxelCoordLib.equals(finalBobCoord, VoxelCoord(mineCoord.x, mineCoord.y, mineCoord.z)),
      "Player bob did not move to new coords"
    );
    {
      VoxelCoord memory aboveFinalAliceCoord = VoxelCoord(finalAliceCoord.x, finalAliceCoord.y + 1, finalAliceCoord.z);
      assertTrue(
        BaseEntity.get(
          ReversePlayerPosition.get(aboveFinalAliceCoord.x, aboveFinalAliceCoord.y, aboveFinalAliceCoord.z)
        ) == aliceEntityId,
        "Above coord is not the player alice"
      );
      VoxelCoord memory aboveFinalBobCoord = VoxelCoord(finalBobCoord.x, finalBobCoord.y + 1, finalBobCoord.z);
      assertTrue(
        BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord.x, aboveFinalBobCoord.y, aboveFinalBobCoord.z)) ==
          bobEntityId,
        "Above coord is not the player bob"
      );
    }

    mineEntityId = ReversePosition.get(mineCoord.x, mineCoord.y, mineCoord.z);
    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
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
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    VoxelCoord memory expectedFinalCoord = VoxelCoord(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y - 1,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(VoxelCoord(expectedFinalCoord.x, expectedFinalCoord.y - 1, expectedFinalCoord.z), DirtObjectID);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move with single block fall");
    world.move(newCoords);
    endGasReport();

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, expectedFinalCoord), "Player did not fall back to the original coord");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveFallMultipleBlocks() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    setObjectAtCoord(
      VoxelCoord(
        newCoords[newCoords.length - 1].x,
        newCoords[newCoords.length - 1].y - 1,
        newCoords[newCoords.length - 1].z
      ),
      AirObjectID
    );
    setObjectAtCoord(
      VoxelCoord(
        newCoords[newCoords.length - 1].x,
        newCoords[newCoords.length - 1].y - 2,
        newCoords[newCoords.length - 1].z
      ),
      AirObjectID
    );
    VoxelCoord memory expectedFinalCoord = VoxelCoord(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y - 3,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(VoxelCoord(expectedFinalCoord.x, expectedFinalCoord.y - 1, expectedFinalCoord.z), DirtObjectID);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("move with three block fall");
    world.move(newCoords);
    endGasReport();

    VoxelCoord memory finalCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertTrue(VoxelCoordLib.equals(finalCoord, expectedFinalCoord), "Player did not fall back to the original coord");
    VoxelCoord memory aboveFinalCoord = VoxelCoord(finalCoord.x, finalCoord.y + 1, finalCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalCoord.x, aboveFinalCoord.y, aboveFinalCoord.z)) ==
        aliceEntityId,
      "Above coord is not the player"
    );
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testMoveStackedPlayers() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory aliceCoord) = setupAirChunkWithPlayer();

    EntityId bobEntityId;
    {
      VoxelCoord memory bobCoord = VoxelCoord(aliceCoord.x, aliceCoord.y + 2, aliceCoord.z);
      setObjectAtCoord(bobCoord, AirObjectID);
      setObjectAtCoord(VoxelCoord(bobCoord.x, bobCoord.y + 1, bobCoord.z), AirObjectID);
      (, bobEntityId) = createTestPlayer(bobCoord);
    }

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(aliceCoord.x, aliceCoord.y, aliceCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }
    setObjectAtCoord(
      VoxelCoord(
        newCoords[newCoords.length - 1].x,
        newCoords[newCoords.length - 1].y - 1,
        newCoords[newCoords.length - 1].z
      ),
      AirObjectID
    );
    setObjectAtCoord(
      VoxelCoord(
        newCoords[newCoords.length - 1].x,
        newCoords[newCoords.length - 1].y - 2,
        newCoords[newCoords.length - 1].z
      ),
      AirObjectID
    );
    VoxelCoord memory expectedFinalAliceCoord = VoxelCoord(
      newCoords[newCoords.length - 1].x,
      newCoords[newCoords.length - 1].y - 3,
      newCoords[newCoords.length - 1].z
    );
    setObjectAtCoord(newCoords[newCoords.length - 1], AirObjectID);
    setObjectAtCoord(
      VoxelCoord(expectedFinalAliceCoord.x, expectedFinalAliceCoord.y - 1, expectedFinalAliceCoord.z),
      DirtObjectID
    );

    uint128 bobEnergyBefore = Energy.getEnergy(bobEntityId);
    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = aliceCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("move with three block fall with a stacked player");
    world.move(newCoords);
    endGasReport();

    VoxelCoord memory finalAliceCoord = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    VoxelCoord memory finalBobCoord = PlayerPosition.get(bobEntityId).toVoxelCoord();
    assertTrue(
      VoxelCoordLib.equals(finalAliceCoord, expectedFinalAliceCoord),
      "Player alice did not move to new coords"
    );
    assertTrue(VoxelCoordLib.equals(finalBobCoord, aliceCoord), "Player bob did not move to new coords");
    VoxelCoord memory aboveFinalAliceCoord = VoxelCoord(finalAliceCoord.x, finalAliceCoord.y + 1, finalAliceCoord.z);
    assertTrue(
      BaseEntity.get(
        ReversePlayerPosition.get(aboveFinalAliceCoord.x, aboveFinalAliceCoord.y, aboveFinalAliceCoord.z)
      ) == aliceEntityId,
      "Above coord is not the player alice"
    );
    VoxelCoord memory aboveFinalBobCoord = VoxelCoord(finalBobCoord.x, finalBobCoord.y + 1, finalBobCoord.z);
    assertTrue(
      BaseEntity.get(ReversePlayerPosition.get(aboveFinalBobCoord.x, aboveFinalBobCoord.y, aboveFinalBobCoord.z)) ==
        bobEntityId,
      "Above coord is not the player bob"
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

  function testMoveFallFatal() public {
    // TODO: implement
  }

  function testMoveFailsIfGravityOutsideExploredChunk() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    for (uint8 i = 0; i < newCoords.length; i++) {
      setObjectAtCoord(newCoords[i], AirObjectID);
      setObjectAtCoord(VoxelCoord(newCoords[i].x, newCoords[i].y + 1, newCoords[i].z), AirObjectID);
    }

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.move(newCoords);
  }
}
