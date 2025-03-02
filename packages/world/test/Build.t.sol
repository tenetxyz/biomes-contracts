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
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { ReversePlayerPosition } from "../src/codegen/tables/ReversePlayerPosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";
import { ForceFieldMetadata } from "../src/codegen/tables/ForceFieldMetadata.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, SmartChestObjectID, TextSignObjectID, GoldBarObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract BuildTest is BiomesTest {
  function testBuildTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    assertTrue(ObjectTypeId.wrap(TerrainLib.getBlockType(buildCoord)) == AirObjectID, "Build coord is not air");
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertFalse(buildEntityId.exists(), "Build entity already exists");
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    Vec3 forceFieldShardCoord = buildCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord);

    vm.prank(alice);
    startGasReport("build terrain");
    world.build(buildObjectTypeId, buildCoord);
    endGasReport();

    buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");

    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testBuildNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    Vec3 forceFieldShardCoord = buildCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord);

    vm.prank(alice);
    startGasReport("build non-terrain");
    world.build(buildObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testBuildMultiSize() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    Vec3 topCoord = buildCoord + vec3(0, 1, 0);
    setObjectAtCoord(buildCoord, AirObjectID);
    setObjectAtCoord(topCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = TextSignObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    EntityId topEntityId = ReversePosition.get(topCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    Vec3 forceFieldShardCoord = buildCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord);

    vm.prank(alice);
    startGasReport("build multi-size");
    world.build(buildObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertTrue(ObjectType.get(topEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testJumpBuild() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    Vec3 forceFieldShardCoord = playerCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord);

    vm.prank(alice);
    startGasReport("jump build");
    world.jumpBuild(buildObjectTypeId);
    endGasReport();

    Vec3 playerCoordAfter = PlayerPosition.get(aliceEntityId);
    assertEq(playerCoordAfter, playerCoord + vec3(0, 1, 0), "Player coord is not correct");

    EntityId buildEntityId = ReversePosition.get(playerCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testBuildPassThroughAtPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, Vec3 bobCoord) = spawnPlayerOnAirChunk(aliceCoord + vec3(0, 0, 3));

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    ObjectTypeMetadata.setCanPassThrough(buildObjectTypeId, true);
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 4);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 4);

    vm.prank(alice);
    world.build(buildObjectTypeId, bobCoord);

    EntityId buildEntityId = ReversePosition.get(bobCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );

    Vec3 aboveBobCoord = bobCoord + vec3(0, 1, 0);
    vm.prank(alice);
    world.build(buildObjectTypeId, aboveBobCoord);
    buildEntityId = ReversePosition.get(aboveBobCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Top entity mass is not correct"
    );

    vm.prank(alice);
    world.build(buildObjectTypeId, aliceCoord);
    buildEntityId = ReversePosition.get(aliceCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Top entity mass is not correct"
    );

    Vec3 aboveAliceCoord = aliceCoord + vec3(0, 1, 0);
    vm.prank(alice);
    world.build(buildObjectTypeId, aboveAliceCoord);
    buildEntityId = ReversePosition.get(aboveAliceCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Top entity mass is not correct"
    );
  }

  function testJumpBuildFailsIfPassThrough() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    ObjectTypeMetadata.setCanPassThrough(buildObjectTypeId, true);
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot jump build on a pass-through block");
    world.jumpBuild(buildObjectTypeId);
  }

  function testJumpBuildFailsIfNonAir() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    setObjectAtCoord(playerCoord + vec3(0, 2, 0), GrassObjectID);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a non-passable block");
    world.jumpBuild(buildObjectTypeId);
  }

  function testJumpBuildFailsIfPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    Vec3 bobCoord = aliceCoord + vec3(0, 2, 0);
    setObjectAtCoord(bobCoord, AirObjectID);
    setObjectAtCoord(bobCoord + vec3(0, 1, 0), AirObjectID);
    (address bob, EntityId bobEntityId) = createTestPlayer(bobCoord);

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot move through a player");
    world.jumpBuild(buildObjectTypeId);
  }

  function testBuildFailsIfNonAir() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    setObjectAtCoord(buildCoord, GrassObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a non-air block");
    world.build(buildObjectTypeId, buildCoord);

    setObjectAtCoord(buildCoord, TextSignObjectID);

    Vec3 topCoord = buildCoord + vec3(0, 1, 0);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a non-air block");
    world.build(buildObjectTypeId, buildCoord);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a non-air block");
    world.build(buildObjectTypeId, topCoord);
  }

  function testBuildFailsIfPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, Vec3 bobCoord) = spawnPlayerOnAirChunk(aliceCoord + vec3(0, 0, 1));

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, bobCoord);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, bobCoord + vec3(0, 1, 0));

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, aliceCoord);
  }

  function testBuildFailsInvalidBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GoldBarObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot build non-block object");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfHasDroppedObjects() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    TestUtils.addToInventoryCount(airEntityId, AirObjectID, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot build where there are dropped objects");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = playerCoord + vec3(MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, 0, 0);
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.build(buildObjectTypeId, buildCoord);

    (address bob, EntityId bobEntityId, ) = spawnPlayerOnAirChunk(
      vec3(WORLD_BORDER_LOW_X, playerCoord.y(), playerCoord.z())
    );

    buildCoord = vec3(WORLD_BORDER_LOW_X - 1, playerCoord.y(), playerCoord.z());
    setObjectAtCoord(buildCoord, AirObjectID);

    vm.prank(bob);
    vm.expectRevert("Cannot build outside the world border");
    world.build(buildObjectTypeId, buildCoord);

    buildCoord = playerCoord - vec3(1, 0, 0);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    Energy.set(
      aliceEntityId,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1, drainRate: 0, accDepletedTime: 0 })
    );

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);

    vm.expectRevert("Player does not exist");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 buildCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL + 1, playerCoord.z());
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 0);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.build(buildObjectTypeId, buildCoord);
  }
}
