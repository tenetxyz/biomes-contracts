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
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract BuildTest is BiomesTest {
  using VoxelCoordLib for *;

  function testBuildTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupFlatChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    assertTrue(ObjectTypeId.wrap(TerrainLib.getBlockType(buildCoord)) == AirObjectID, "Build coord is not air");
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertFalse(buildEntityId.exists(), "Build entity already exists");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    VoxelCoord memory forceFieldShardCoord = buildCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );

    vm.prank(alice);
    startGasReport("build terrain");
    world.build(buildObjectTypeId, buildCoord);
    endGasReport();

    buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, buildObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord.x, forceFieldShardCoord.y, forceFieldShardCoord.z),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testBuildNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    VoxelCoord memory forceFieldShardCoord = buildCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );

    vm.prank(alice);
    startGasReport("build non-terrain");
    world.build(buildObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, buildObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord.x, forceFieldShardCoord.y, forceFieldShardCoord.z),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testBuildMultiSize() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    VoxelCoord memory topCoord = VoxelCoord(buildCoord.x, buildCoord.y + 1, buildCoord.z);
    setObjectAtCoord(buildCoord, AirObjectID);
    setObjectAtCoord(topCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = TextSignObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    EntityId topEntityId = ReversePosition.get(topCoord.x, topCoord.y, topCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertTrue(topEntityId.exists(), "Top entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    VoxelCoord memory forceFieldShardCoord = buildCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );

    vm.prank(alice);
    startGasReport("build multi-size");
    world.build(buildObjectTypeId, buildCoord);
    endGasReport();

    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertTrue(ObjectType.get(topEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, buildObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(Mass.getMass(topEntityId), 0, "Top entity mass is not correct");
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord.x, forceFieldShardCoord.y, forceFieldShardCoord.z),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testJumpBuild() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);
    VoxelCoord memory forceFieldShardCoord = playerCoord.toForceFieldShardCoord();
    uint128 localMassBefore = ForceFieldMetadata.getTotalMassInside(
      forceFieldShardCoord.x,
      forceFieldShardCoord.y,
      forceFieldShardCoord.z
    );

    vm.prank(alice);
    startGasReport("jump build");
    world.jumpBuild(buildObjectTypeId);
    endGasReport();

    VoxelCoord memory playerCoordAfter = PlayerPosition.get(aliceEntityId).toVoxelCoord();
    assertEq(playerCoordAfter.x, playerCoord.x, "Player coord x is not correct");
    assertEq(playerCoordAfter.y, playerCoord.y + 1, "Player coord y is not correct");
    assertEq(playerCoordAfter.z, playerCoord.z, "Player coord z is not correct");

    EntityId buildEntityId = ReversePosition.get(playerCoord.x, playerCoord.y, playerCoord.z);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, buildObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );
    assertEq(
      ForceFieldMetadata.getTotalMassInside(forceFieldShardCoord.x, forceFieldShardCoord.y, forceFieldShardCoord.z),
      localMassBefore + ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Force field mass is not correct"
    );
  }

  function testBuildPassThroughAtPlayer() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, VoxelCoord memory bobCoord) = spawnPlayerOnAirChunk(
      VoxelCoord(aliceCoord.x, aliceCoord.y, aliceCoord.z + 1)
    );

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    ObjectTypeMetadata.setCanPassThrough(buildObjectTypeId, true);
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 4);
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 4, "Inventory count is not 0");

    vm.prank(alice);
    world.build(buildObjectTypeId, bobCoord);

    EntityId buildEntityId = ReversePosition.get(bobCoord.x, bobCoord.y, bobCoord.z);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Build entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Build entity mass is not correct"
    );

    vm.prank(alice);
    world.build(buildObjectTypeId, VoxelCoord(bobCoord.x, bobCoord.y + 1, bobCoord.z));
    buildEntityId = ReversePosition.get(bobCoord.x, bobCoord.y + 1, bobCoord.z);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Top entity mass is not correct"
    );

    vm.prank(alice);
    world.build(buildObjectTypeId, aliceCoord);
    buildEntityId = ReversePosition.get(aliceCoord.x, aliceCoord.y, aliceCoord.z);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Top entity mass is not correct"
    );

    vm.prank(alice);
    world.build(buildObjectTypeId, VoxelCoord(aliceCoord.x, aliceCoord.y + 1, aliceCoord.z));
    buildEntityId = ReversePosition.get(aliceCoord.x, aliceCoord.y + 1, aliceCoord.z);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Top entity is not build object type");
    assertEq(
      Mass.getMass(buildEntityId),
      ObjectTypeMetadata.getMass(buildObjectTypeId),
      "Top entity mass is not correct"
    );
  }

  function testJumpBuildFailsIfPassThrough() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    ObjectTypeMetadata.setCanPassThrough(buildObjectTypeId, true);
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Cannot jump build on a pass-through block");
    world.jumpBuild(buildObjectTypeId);
  }

  function testBuildFailsIfNonAir() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    setObjectAtCoord(buildCoord, GrassObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Cannot build on a non-air block");
    world.build(buildObjectTypeId, buildCoord);

    setObjectAtCoord(buildCoord, TextSignObjectID);

    VoxelCoord memory topCoord = VoxelCoord(buildCoord.x, buildCoord.y + 1, buildCoord.z);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a non-air block");
    world.build(buildObjectTypeId, buildCoord);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a non-air block");
    world.build(buildObjectTypeId, topCoord);
  }

  function testBuildFailsIfPlayer() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, VoxelCoord memory bobCoord) = spawnPlayerOnAirChunk(
      VoxelCoord(aliceCoord.x, aliceCoord.y, aliceCoord.z + 1)
    );

    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, bobCoord);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, VoxelCoord(bobCoord.x, bobCoord.y + 1, bobCoord.z));

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, aliceCoord);

    vm.prank(alice);
    vm.expectRevert("Cannot build on a player");
    world.build(buildObjectTypeId, VoxelCoord(aliceCoord.x, aliceCoord.y + 1, aliceCoord.z));
  }

  function testBuildFailsInvalidBlock() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GoldBarObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Cannot build non-block object");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfHasDroppedObjects() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    TestUtils.addToInventoryCount(airEntityId, AirObjectID, buildObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot build where there are dropped objects");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x + MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1,
      playerCoord.y,
      playerCoord.z
    );
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.build(buildObjectTypeId, buildCoord);

    (address bob, EntityId bobEntityId, ) = spawnPlayerOnAirChunk(
      VoxelCoord(WORLD_BORDER_LOW_X, playerCoord.y, playerCoord.z)
    );

    buildCoord = VoxelCoord(WORLD_BORDER_LOW_X - 1, playerCoord.y, playerCoord.z);
    setObjectAtCoord(buildCoord, AirObjectID);

    vm.prank(bob);
    vm.expectRevert("Cannot build outside the world border");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, buildObjectTypeId, 1);
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 1, "Inventory count is not 0");

    Energy.set(
      aliceEntityId,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 0, accDepletedTime: 0 })
    );

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    EntityId airEntityId = setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");

    vm.expectRevert("Player does not exist");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory buildCoord = VoxelCoord(
      playerCoord.x == CHUNK_SIZE - 1 ? playerCoord.x - 1 : playerCoord.x + 1,
      FLAT_CHUNK_GRASS_LEVEL + 1,
      playerCoord.z
    );
    setObjectAtCoord(buildCoord, AirObjectID);
    ObjectTypeId buildObjectTypeId = GrassObjectID;
    EntityId buildEntityId = ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z);
    assertTrue(buildEntityId.exists(), "Build entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, buildObjectTypeId), 0, "Inventory count is not 0");

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.build(buildObjectTypeId, buildCoord);
  }
}
