// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

import { validateSpanningTree } from "../src/systems/ForceFieldSystem.sol";
import { BiomesTest, console } from "./BiomesTest.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ReversePosition, PlayerPosition, Position } from "../src/utils/Vec3Storage.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { MACHINE_ENERGY_DRAIN_RATE, FORCE_FIELD_SHARD_DIM } from "../src/Constants.sol";
import { IForceFieldChip } from "../src/prototypes/IForceFieldChip.sol";
import { IForceFieldShardChip } from "../src/prototypes/IForceFieldShardChip.sol";
import { TestForceFieldUtils, TestInventoryUtils } from "./utils/TestUtils.sol";

contract TestForceFieldChip is IForceFieldChip, System {
  // Just for testing, real chips should use tables
  bool revertOnBuild;
  bool revertOnMine;

  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onBuild(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnBuild, "Not allowed by forcefield");
  }

  function onMine(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnMine, "Not allowed by forcefield");
  }

  function onPowered(EntityId callerEntityId, EntityId targetEntityId, uint16 numBattery) external {}

  function onForceFieldHit(EntityId callerEntityId, EntityId targetEntityId) external {}

  function onExpand(EntityId callerEntityId, EntityId targetEntityId) external {}

  function onContract(EntityId callerEntityId, EntityId targetEntityId) external {}

  function setRevertOnBuild(bool _revertOnBuild) external {
    revertOnBuild = _revertOnBuild;
  }

  function setRevertOnMine(bool _revertOnMine) external {
    revertOnMine = _revertOnMine;
  }

  function supportsInterface(bytes4 interfaceId) public pure override(IERC165, WorldContextConsumer) returns (bool) {
    return interfaceId == type(IForceFieldChip).interfaceId || super.supportsInterface(interfaceId);
  }
}

contract TestForceFieldShardChip is IForceFieldShardChip, System {
  // Just for testing, real chips should use tables
  bool revertOnBuild;
  bool revertOnMine;

  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onBuild(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnBuild, "Not allowed by forcefield shard");
  }

  function onMine(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnMine, "Not allowed by forcefield shard");
  }

  function setRevertOnBuild(bool _revertOnBuild) external {
    revertOnBuild = _revertOnBuild;
  }

  function setRevertOnMine(bool _revertOnMine) external {
    revertOnMine = _revertOnMine;
  }

  function supportsInterface(bytes4 interfaceId) public pure override(IERC165, WorldContextConsumer) returns (bool) {
    return interfaceId == type(IForceFieldShardChip).interfaceId || super.supportsInterface(interfaceId);
  }
}

contract ForceFieldTest is BiomesTest {
  function attachTestChip(EntityId forceFieldEntityId, System chip) internal {
    bytes14 namespace = "chipNamespace";
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId chipSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "chipName");
    world.registerNamespace(namespaceId);
    world.registerSystem(chipSystemId, chip, false);
    world.transferOwnership(namespaceId, address(0));

    Vec3 coord = Position.get(forceFieldEntityId);

    // Attach chip with test player
    (address bob, ) = createTestPlayer(coord - vec3(1, 0, 0));
    vm.prank(bob);
    world.attachChip(forceFieldEntityId, chipSystemId);
  }

  function testMineWithForceFieldWithNoEnergy() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1, accDepletedTime: 0 })
    );

    TestForceFieldChip chip = new TestForceFieldChip();
    attachTestChip(forceFieldEntityId, chip);
    chip.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    world.mine(mineCoord);

    // Verify that the block was successfully mined (should be replaced with Air)
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");
  }

  function testMineFailsIfNotAllowedByForceField() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    TestForceFieldChip chip = new TestForceFieldChip();
    attachTestChip(forceFieldEntityId, chip);
    chip.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield");
    world.mine(mineCoord);
  }

  function testMineFailsIfNotAllowedByForceFieldShard() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    (, EntityId shardEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    TestForceFieldShardChip chip = new TestForceFieldShardChip();
    attachTestChip(shardEntityId, chip);
    chip.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield shard");
    world.mine(mineCoord);
  }

  function testBuildWithForceFieldWithNoEnergy() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1, accDepletedTime: 0 })
    );

    TestForceFieldChip chip = new TestForceFieldChip();
    attachTestChip(forceFieldEntityId, chip);
    chip.setRevertOnBuild(true);

    // Define build coordinates within force field
    Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

    // Set terrain at build coord to air
    setTerrainAtCoord(buildCoord, ObjectTypes.Air);

    // Add block to player's inventory
    ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    // Build the block
    vm.prank(alice);
    world.build(buildObjectTypeId, buildCoord);

    // Verify that the block was successfully built
    EntityId buildEntityId = ReversePosition.get(buildCoord);
    assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Block was not built correctly");
  }

  function testBuildFailsIfNotAllowedByForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with NO energy (depleted)
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({
        lastUpdatedTime: uint128(block.timestamp),
        energy: 1000,
        drainRate: 1,
        accDepletedTime: 100 // Depleted
      })
    );

    TestForceFieldChip chip = new TestForceFieldChip();
    attachTestChip(forceFieldEntityId, chip);
    chip.setRevertOnBuild(true);

    // Define build coordinates within force field
    Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

    // Set terrain at build coord to air
    setTerrainAtCoord(buildCoord, ObjectTypes.Air);

    // Add block to player's inventory
    ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    // Try to build the block, should fail
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testBuildFailsIfNotAllowedByForceFieldShard() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with NO energy (depleted)
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    setupForceField(
      forceFieldCoord,
      EnergyData({
        lastUpdatedTime: uint128(block.timestamp),
        energy: 1000,
        drainRate: 1,
        accDepletedTime: 100 // Depleted
      })
    );

    (, EntityId shardEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    TestForceFieldShardChip chip = new TestForceFieldShardChip();
    attachTestChip(shardEntityId, chip);
    chip.setRevertOnBuild(true);

    // Define build coordinates within force field
    Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

    // Set terrain at build coord to air
    setTerrainAtCoord(buildCoord, ObjectTypes.Air);

    // Add block to player's inventory
    ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    // Try to build the block, should fail
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield shard");
    world.build(buildObjectTypeId, buildCoord);
  }

  function testSetupForceField() public {
    // Set up a flat chunk with a player
    (, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(forceFieldCoord);

    // Verify that the force field is active
    assertTrue(TestForceFieldUtils.isForceFieldActive(forceFieldEntityId), "Force field not active");

    // Verify that the shard at the force field coordinate exists
    Vec3 shardCoord = forceFieldCoord.toForceFieldShardCoord();
    assertTrue(TestForceFieldUtils.isForceFieldShard(forceFieldEntityId, shardCoord), "Force field shard not found");

    // Verify that we can get the force field from the coordinate
    (EntityId retrievedForceFieldId, ) = TestForceFieldUtils.getForceField(forceFieldCoord);
    assertEq(
      EntityId.unwrap(retrievedForceFieldId),
      EntityId.unwrap(forceFieldEntityId),
      "Retrieved incorrect force field"
    );
  }

  function testExpandForceField() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    EnergyData memory initialEnergyData = EnergyData({
      lastUpdatedTime: uint128(block.timestamp),
      energy: 1000,
      drainRate: 1,
      accDepletedTime: 0
    });

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(forceFieldCoord, initialEnergyData);

    // Define expansion area
    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();
    Vec3 fromShardCoord = refShardCoord + vec3(1, 0, 0);
    Vec3 toShardCoord = refShardCoord + vec3(2, 0, 1);

    // Expand the force field
    vm.prank(alice);
    startGasReport("Expand forcefield 2x2");
    world.expandForceField(forceFieldEntityId, refShardCoord, fromShardCoord, toShardCoord);
    endGasReport();

    // Calculate expected number of added shards (2x1x2 = 4 new shards)
    uint128 addedShards = 4;

    // Verify that the energy drain rate has increased
    EnergyData memory afterEnergyData = Energy.get(forceFieldEntityId);
    assertEq(
      afterEnergyData.drainRate,
      initialEnergyData.drainRate + MACHINE_ENERGY_DRAIN_RATE * addedShards,
      "Energy drain rate did not increase correctly"
    );

    // Verify that each new shard exists
    for (int32 x = fromShardCoord.x(); x <= toShardCoord.x(); x++) {
      for (int32 y = fromShardCoord.y(); y <= toShardCoord.y(); y++) {
        for (int32 z = fromShardCoord.z(); z <= toShardCoord.z(); z++) {
          Vec3 shardCoord = vec3(x, y, z);
          assertTrue(
            TestForceFieldUtils.isForceFieldShard(forceFieldEntityId, shardCoord),
            "Force field shard not found at coordinate"
          );
        }
      }
    }
  }

  function testContractForceField() public {
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();

    // Expand the force field
    vm.prank(alice);
    startGasReport("Expand forcefield 3x3");
    world.expandForceField(
      forceFieldEntityId,
      refShardCoord,
      refShardCoord + vec3(1, 0, 0),
      refShardCoord + vec3(3, 0, 2)
    );
    endGasReport();

    // Get energy data after expansion
    EnergyData memory afterExpandEnergyData = Energy.get(forceFieldEntityId);

    // Contract a portion of the force field within a scope
    {
      Vec3 contractFrom = refShardCoord + vec3(2, 0, 0);
      Vec3 contractTo = refShardCoord + vec3(3, 0, 1);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1;
      parents[3] = 2;
      parents[4] = 3;

      vm.prank(alice);
      startGasReport("Contract forcefield 2x2");
      world.contractForceField(forceFieldEntityId, contractFrom, contractTo, parents);
      endGasReport();
    }

    // Get energy data after contraction
    EnergyData memory afterContractEnergyData = Energy.get(forceFieldEntityId);

    // Verify energy drain rate (4 shards removed: 2x1x2)
    assertEq(
      afterContractEnergyData.drainRate,
      afterExpandEnergyData.drainRate - MACHINE_ENERGY_DRAIN_RATE * 4,
      "Energy drain rate did not decrease correctly"
    );

    // Verify removed shards no longer exist
    for (int32 x = refShardCoord.x() + 2; x <= refShardCoord.x() + 3; x++) {
      for (int32 y = refShardCoord.y(); y <= refShardCoord.y(); y++) {
        for (int32 z = refShardCoord.z(); z <= refShardCoord.z() + 1; z++) {
          assertFalse(
            TestForceFieldUtils.isForceFieldShard(forceFieldEntityId, vec3(x, y, z)),
            "Force field shard still exists after contraction"
          );
        }
      }
    }

    // Verify original shard still exists
    assertTrue(
      TestForceFieldUtils.isForceFieldShard(forceFieldEntityId, refShardCoord),
      "Original force field shard was removed"
    );
  }

  function testExpandForceFieldFailsIfInvalidCoordinates() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Reference shard coordinate
    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();

    // Test with fromShardCoord > toShardCoord (invalid)
    Vec3 fromShardCoord = refShardCoord + vec3(2, 0, 0);
    Vec3 toShardCoord = refShardCoord + vec3(1, 0, 0);

    // Expand should fail with these invalid coordinates
    vm.prank(alice);
    vm.expectRevert("Invalid coordinates");
    world.expandForceField(forceFieldEntityId, refShardCoord, fromShardCoord, toShardCoord);
  }

  function testExpandForceFieldFailsIfRefShardNotAdjacent() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Reference shard coordinate
    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();

    // These coordinates are not adjacent to the reference shard
    Vec3 fromShardCoord = refShardCoord + vec3(3, 0, 0);
    Vec3 toShardCoord = refShardCoord + vec3(4, 0, 0);

    // Expand should fail because new shards not adjacent to reference shard
    vm.prank(alice);
    vm.expectRevert("Reference shard is not adjacent to new shards");
    world.expandForceField(forceFieldEntityId, refShardCoord, fromShardCoord, toShardCoord);
  }

  function testExpandForceFieldFailsIfRefShardNotInForceField() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Invalid reference shard coordinate (not part of the force field)
    Vec3 invalidRefShardCoord = forceFieldCoord.toForceFieldShardCoord() + vec3(10, 0, 0);

    // Expansion area
    Vec3 fromShardCoord = invalidRefShardCoord + vec3(1, 0, 0);
    Vec3 toShardCoord = invalidRefShardCoord + vec3(2, 0, 0);

    // Expand should fail because reference shard is not part of the force field
    vm.prank(alice);
    vm.expectRevert("Reference shard is not part of forcefield");
    world.expandForceField(forceFieldEntityId, invalidRefShardCoord, fromShardCoord, toShardCoord);
  }

  function testContractForceFieldFailsIfInvalidCoordinates() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // First expand the force field to create a larger area
    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();
    Vec3 expandFromShardCoord = refShardCoord + vec3(1, 0, 0);
    Vec3 expandToShardCoord = refShardCoord + vec3(3, 0, 2);

    // Expand the force field
    vm.prank(alice);
    world.expandForceField(forceFieldEntityId, refShardCoord, expandFromShardCoord, expandToShardCoord);

    // Try to contract with invalid coordinates (from > to)
    Vec3 contractFromShardCoord = refShardCoord + vec3(3, 0, 0);
    Vec3 contractToShardCoord = refShardCoord + vec3(1, 0, 0);
    uint256[] memory parents = new uint256[](0);

    // Contract should fail with invalid coordinates
    vm.prank(alice);
    vm.expectRevert("Invalid coordinates");
    world.contractForceField(forceFieldEntityId, contractFromShardCoord, contractToShardCoord, parents);
  }

  function testContractForceFieldFailsIfNoBoundaryShards() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Try to contract an area that has no shards or boundaries
    Vec3 contractFromShardCoord = forceFieldCoord.toForceFieldShardCoord() + vec3(10, 0, 0);
    Vec3 contractToShardCoord = contractFromShardCoord + vec3(1, 0, 0);
    uint256[] memory parents = new uint256[](0);

    // Contract should fail because there are no boundary shards
    vm.prank(alice);
    vm.expectRevert("No boundary shards found");
    world.contractForceField(forceFieldEntityId, contractFromShardCoord, contractToShardCoord, parents);
  }

  function testContractForceFieldFailsIfInvalidSpanningTree() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // First expand the force field to create a larger area
    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();
    Vec3 expandFromShardCoord = refShardCoord + vec3(1, 0, 0);
    Vec3 expandToShardCoord = refShardCoord + vec3(3, 0, 2);

    // Expand the force field
    vm.prank(alice);
    world.expandForceField(forceFieldEntityId, refShardCoord, expandFromShardCoord, expandToShardCoord);

    // Try to contract with valid coordinates but invalid parent array
    Vec3 contractFromShardCoord = refShardCoord + vec3(2, 0, 0);
    Vec3 contractToShardCoord = refShardCoord + vec3(3, 0, 1);

    // Compute the boundary shards that will remain after contraction
    Vec3[] memory boundaryShards = TestForceFieldUtils.computeBoundaryShards(
      forceFieldEntityId,
      contractFromShardCoord,
      contractToShardCoord
    );

    // Create an INVALID parent array for the boundary shards (all zeros)
    uint256[] memory invalidParents = new uint256[](boundaryShards.length);
    for (uint256 i = 0; i < boundaryShards.length; i++) {
      invalidParents[i] = 0; // This creates disconnected components
    }

    // Contract should fail because the parent array doesn't represent a valid spanning tree
    vm.prank(alice);
    vm.expectRevert("Invalid spanning tree");
    world.contractForceField(forceFieldEntityId, contractFromShardCoord, contractToShardCoord, invalidParents);
  }

  function testComputeBoundaryShards() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a 3x3x3 force field
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Expand the force field to create a 3x3x3 cube
    Vec3 refShardCoord = forceFieldCoord.toForceFieldShardCoord();
    Vec3 expandFromShardCoord = refShardCoord + vec3(1, 0, 0);
    Vec3 expandToShardCoord = expandFromShardCoord + vec3(2, 2, 2);

    vm.prank(alice);
    world.expandForceField(forceFieldEntityId, refShardCoord, expandFromShardCoord, expandToShardCoord);

    // Define a 1x1x1 cuboid in the center to remove
    Vec3 contractFromShardCoord = expandFromShardCoord + vec3(1, 1, 1);
    Vec3 contractToShardCoord = contractFromShardCoord;

    // Compute the boundary shards
    Vec3[] memory boundaryShards = TestForceFieldUtils.computeBoundaryShards(
      forceFieldEntityId,
      contractFromShardCoord,
      contractToShardCoord
    );

    // For a 1x1x1 cuboid, we expect 26 boundary shards (one on each face plus edges/corners)
    assertEq(boundaryShards.length, 26, "Expected 26 boundary shards for a 1x1x1 cuboid");

    // Verify that each boundary shard is part of the force field
    for (uint256 i = 0; i < boundaryShards.length; i++) {
      assertTrue(
        TestForceFieldUtils.isForceFieldShard(forceFieldEntityId, boundaryShards[i]),
        "Boundary shard is not part of the force field"
      );
    }

    // Define expected boundary shards to check
    Vec3[26] memory expectedBoundaries = contractFromShardCoord.neighbors26();

    // Check each expected boundary
    for (uint256 i = 0; i < expectedBoundaries.length; i++) {
      bool found = false;
      for (uint256 j = 0; j < boundaryShards.length; j++) {
        if (expectedBoundaries[i] == boundaryShards[j]) {
          found = true;
          break;
        }
      }
      assertTrue(found, "Missing boundary shard");
    }
  }

  function testExpandIntoExistingForceField() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create first force field
    Vec3 forceField1Coord = playerCoord + vec3(2, 0, 0);
    EntityId forceField1EntityId = setupForceField(
      forceField1Coord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Create second force field
    Vec3 forceField2Coord = forceField1Coord + vec3(FORCE_FIELD_SHARD_DIM, 0, 0);
    setupForceField(
      forceField2Coord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Try to expand first force field into second force field's area (should fail)
    Vec3 refShardCoord = forceField1Coord.toForceFieldShardCoord();
    vm.prank(alice);
    vm.expectRevert("Can't expand to existing forcefield");
    world.expandForceField(
      forceField1EntityId,
      refShardCoord,
      refShardCoord + vec3(1, 0, 0),
      refShardCoord + vec3(1, 0, 0)
    );
  }

  function testValidateSpanningTree() public pure {
    // Test case 1: Empty array (trivial case)
    {
      Vec3[] memory shards = new Vec3[](0);
      uint256[] memory parents = new uint256[](0);
      assertTrue(validateSpanningTree(shards, parents), "Empty array should be valid");
    }

    // Test case 2: Single node (trivial case)
    {
      Vec3[] memory shards = new Vec3[](1);
      shards[0] = vec3(0, 0, 0);
      uint256[] memory parents = new uint256[](1);
      parents[0] = 0; // Self-referential
      assertTrue(validateSpanningTree(shards, parents), "Single node should be valid");
    }

    // Test case 3: Simple line of 3 nodes
    {
      Vec3[] memory shards = new Vec3[](3);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0); // Adjacent to shards[0]
      shards[2] = vec3(2, 0, 0); // Adjacent to shards[1]

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0; // Root
      parents[1] = 0; // Parent is shards[0]
      parents[2] = 1; // Parent is shards[1]

      assertTrue(validateSpanningTree(shards, parents), "Line of 3 nodes should be valid");
    }

    // Test case 4: Star pattern (all nodes connected to root)
    {
      Vec3[] memory shards = new Vec3[](5);
      shards[0] = vec3(0, 0, 0); // Center
      shards[1] = vec3(1, 0, 0); // East
      shards[2] = vec3(0, 1, 0); // North
      shards[3] = vec3(-1, 0, 0); // West
      shards[4] = vec3(0, -1, 0); // South

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0; // Root
      parents[1] = 0; // All connected to root
      parents[2] = 0;
      parents[3] = 0;
      parents[4] = 0;

      assertTrue(validateSpanningTree(shards, parents), "Star pattern should be valid");
    }

    // Test case 5: Invalid - parents array length mismatch
    {
      Vec3[] memory shards = new Vec3[](3);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);

      uint256[] memory parents = new uint256[](2); // Missing one parent
      parents[0] = 0;
      parents[1] = 0;

      assertFalse(validateSpanningTree(shards, parents), "Invalid parents length");
    }

    // Test case 6: Invalid - non-adjacent nodes
    {
      Vec3[] memory shards = new Vec3[](3);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0); // Adjacent to shards[0]
      shards[2] = vec3(3, 0, 0); // NOT adjacent to shards[1] (distance = 2)

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1; // Claims shards[1] is parent, but they're not adjacent

      assertFalse(validateSpanningTree(shards, parents), "Non-adjacent shards");
    }

    // Test case 7: Invalid - disconnected graph
    {
      Vec3[] memory shards = new Vec3[](4);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0); // Adjacent to shards[0]
      shards[2] = vec3(5, 0, 0); // Disconnected from others
      shards[3] = vec3(6, 0, 0); // Adjacent to shards[2] but not to shards[0] or shards[1]

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 2; // Self-referential, creating a second "root"
      parents[3] = 2;

      assertFalse(validateSpanningTree(shards, parents), "Disconnected graph should be invalid");
    }

    // Test case 8: Invalid - cycle in the graph
    {
      Vec3[] memory shards = new Vec3[](3);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0); // Adjacent to shards[0]
      shards[2] = vec3(1, 1, 0); // Adjacent to shards[1]

      uint256[] memory parents = new uint256[](3);
      parents[0] = 2; // Creates a cycle: 0->2->1->0
      parents[1] = 0;
      parents[2] = 1;

      assertFalse(validateSpanningTree(shards, parents), "Root must be self-referential");
    }

    // Test case 9: Valid - complex tree with branches
    {
      Vec3[] memory shards = new Vec3[](7);
      shards[0] = vec3(0, 0, 0); // Root
      shards[1] = vec3(1, 0, 0); // Level 1, branch 1
      shards[2] = vec3(0, 1, 0); // Level 1, branch 2
      shards[3] = vec3(2, 0, 0); // Level 2, from branch 1
      shards[4] = vec3(1, 1, 0); // Level 2, from branch 2
      shards[5] = vec3(0, 2, 0); // Level 2, from branch 2
      shards[6] = vec3(3, 0, 0); // Level 3, from branch 1

      uint256[] memory parents = new uint256[](7);
      parents[0] = 0; // Root
      parents[1] = 0; // Connected to root
      parents[2] = 0; // Connected to root
      parents[3] = 1; // Connected to branch 1
      parents[4] = 2; // Connected to branch 2
      parents[5] = 2; // Connected to branch 2
      parents[6] = 3; // Connected to level 2 of branch 1

      assertTrue(validateSpanningTree(shards, parents), "Complex tree should be valid");
    }

    // Test case 10: Invalid - diagonal neighbors (not in Von Neumann neighborhood)
    {
      Vec3[] memory shards = new Vec3[](2);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 1, 0); // Diagonal to shards[0], not in Von Neumann neighborhood

      uint256[] memory parents = new uint256[](2);
      parents[0] = 0;
      parents[1] = 0;

      assertFalse(validateSpanningTree(shards, parents), "Non-adjacent shards");
    }

    // Test case 11: Invalid - parent index out of bounds
    {
      Vec3[] memory shards = new Vec3[](3);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 999; // Parent index out of bounds

      assertFalse(validateSpanningTree(shards, parents), "Parent index out of bounds");
    }

    // Test case 12: Invalid - cycle in the middle of the array
    {
      Vec3[] memory shards = new Vec3[](5);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      shards[3] = vec3(3, 0, 0);
      shards[4] = vec3(4, 0, 0);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0; // Root is valid
      parents[1] = 0; // Valid
      parents[2] = 3; // Creates a cycle with node 3
      parents[3] = 2; // Part of the cycle
      parents[4] = 3; // Valid connection to node 3

      assertFalse(validateSpanningTree(shards, parents), "Cycle in the middle of the array");
    }

    // Test case 13: Invalid - multiple nodes pointing to non-existent parent
    {
      Vec3[] memory shards = new Vec3[](5);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      shards[3] = vec3(3, 0, 0);
      shards[4] = vec3(4, 0, 0);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0;
      parents[1] = 10; // Invalid parent
      parents[2] = 10; // Same invalid parent
      parents[3] = 10; // Same invalid parent
      parents[4] = 0;

      assertFalse(validateSpanningTree(shards, parents), "Multiple nodes pointing to non-existent parent");
    }

    // Test case 14: Invalid - node is its own parent (except root)
    {
      Vec3[] memory shards = new Vec3[](4);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      shards[3] = vec3(3, 0, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0; // Valid root
      parents[1] = 0; // Valid
      parents[2] = 2; // Node is its own parent
      parents[3] = 2; // Valid

      assertFalse(validateSpanningTree(shards, parents), "Node cannot be its own parent");
    }

    // Test case 15: Invalid - complex cycle in a larger graph
    {
      Vec3[] memory shards = new Vec3[](8);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      shards[3] = vec3(3, 0, 0);
      shards[4] = vec3(4, 0, 0);
      shards[5] = vec3(3, 1, 0);
      shards[6] = vec3(2, 1, 0);
      shards[7] = vec3(1, 1, 0);

      uint256[] memory parents = new uint256[](8);
      parents[0] = 0; // Root
      parents[1] = 0; // Valid
      parents[2] = 1; // Valid
      parents[3] = 2; // Valid
      parents[4] = 3; // Valid
      parents[5] = 6; // Part of cycle
      parents[6] = 7; // Part of cycle
      parents[7] = 5; // Creates cycle: 5->6->7->5

      assertFalse(validateSpanningTree(shards, parents), "Complex cycle in larger graph");
    }

    // Test case 16: Invalid - root not at index 0
    {
      Vec3[] memory shards = new Vec3[](4);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      shards[3] = vec3(3, 0, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 1; // Not self-referential
      parents[1] = 1; // This is the root
      parents[2] = 1;
      parents[3] = 2;

      assertFalse(validateSpanningTree(shards, parents), "Root must be at index 0");
    }

    // Test case 17: Invalid - parent references later index (creating forward reference)
    {
      Vec3[] memory shards = new Vec3[](4);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(1, 1, 0);
      shards[3] = vec3(0, 1, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0; // Valid root
      parents[1] = 3; // Forward reference to node 3
      parents[2] = 1;
      parents[3] = 0;

      assertFalse(validateSpanningTree(shards, parents), "Forward reference creates invalid tree");
    }

    // Test case 18: Valid - zigzag pattern
    {
      Vec3[] memory shards = new Vec3[](5);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(1, 1, 0);
      shards[3] = vec3(0, 1, 0);
      shards[4] = vec3(0, 2, 0);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1;
      parents[3] = 2;
      parents[4] = 3;

      assertTrue(validateSpanningTree(shards, parents), "Zigzag pattern should be valid");
    }

    // Test case 19: Invalid - multiple roots
    {
      Vec3[] memory shards = new Vec3[](6);
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      shards[3] = vec3(10, 0, 0); // Disconnected section
      shards[4] = vec3(11, 0, 0);
      shards[5] = vec3(12, 0, 0);

      uint256[] memory parents = new uint256[](6);
      parents[0] = 0; // First root
      parents[1] = 0;
      parents[2] = 1;
      parents[3] = 3; // Second root
      parents[4] = 3;
      parents[5] = 4;

      assertFalse(validateSpanningTree(shards, parents), "Multiple roots should be invalid");
    }

    // Test case 20: Invalid - complex disconnected components
    {
      Vec3[] memory shards = new Vec3[](10);
      // Component 1
      shards[0] = vec3(0, 0, 0);
      shards[1] = vec3(1, 0, 0);
      shards[2] = vec3(2, 0, 0);
      // Component 2
      shards[3] = vec3(10, 0, 0);
      shards[4] = vec3(11, 0, 0);
      // Component 3
      shards[5] = vec3(20, 0, 0);
      shards[6] = vec3(21, 0, 0);
      shards[7] = vec3(22, 0, 0);
      shards[8] = vec3(23, 0, 0);
      shards[9] = vec3(24, 0, 0);

      uint256[] memory parents = new uint256[](10);
      // Component 1
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1;
      // Component 2
      parents[3] = 3;
      parents[4] = 3;
      // Component 3
      parents[5] = 5;
      parents[6] = 5;
      parents[7] = 6;
      parents[8] = 7;
      parents[9] = 8;

      assertFalse(validateSpanningTree(shards, parents), "Complex disconnected components should be invalid");
    }
  }
}
