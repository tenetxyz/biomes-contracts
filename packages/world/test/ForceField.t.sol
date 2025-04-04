// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { TestEnergyUtils, TestForceFieldUtils, TestInventoryUtils } from "./utils/TestUtils.sol";

import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";

import { EntityProgram } from "../src/codegen/tables/EntityProgram.sol";
import { Machine } from "../src/codegen/tables/Machine.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { DustTest, console } from "./DustTest.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { MovablePosition, Position, ReversePosition } from "../src/utils/Vec3Storage.sol";

import { FRAGMENT_SIZE, MACHINE_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ProgramId } from "../src/ProgramId.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";

contract TestForceFieldProgram is System {
  // Just for testing, real programs should use tables
  bool revertOnValidateProgram;
  bool revertOnBuild;
  bool revertOnMine;

  function validateProgram(EntityId, EntityId, EntityId, ProgramId, bytes memory) external view {
    require(!revertOnValidateProgram, "Not allowed by forcefield");
    // Function is now empty since we use vm.expectCall to verify it was called with correct parameters
  }

  function onBuild(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external view {
    require(!revertOnBuild, "Not allowed by forcefield");
  }

  function onMine(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external view {
    require(!revertOnMine, "Not allowed by forcefield");
  }

  function setRevertOnBuild(bool _revertOnBuild) external {
    revertOnBuild = _revertOnBuild;
  }

  function setRevertOnMine(bool _revertOnMine) external {
    revertOnMine = _revertOnMine;
  }

  function setRevertOnValidateProgram(bool _revert) external {
    revertOnValidateProgram = _revert;
  }

  fallback() external { }
}

contract TestForceFieldFragmentProgram is System {
  // Just for testing, real programs should use tables
  bool revertOnValidateProgram;
  bool revertOnBuild;
  bool revertOnMine;

  function validateProgram(EntityId, EntityId, EntityId, ProgramId, bytes memory) external view {
    require(!revertOnValidateProgram, "Not allowed by forcefield fragment");
    // Function is now empty since we use vm.expectCall to verify it was called with correct parameters
  }

  function onBuild(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external view {
    require(!revertOnBuild, "Not allowed by forcefield fragment");
  }

  function onMine(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external view {
    require(!revertOnMine, "Not allowed by forcefield fragment");
  }

  function setRevertOnBuild(bool _revertOnBuild) external {
    revertOnBuild = _revertOnBuild;
  }

  function setRevertOnMine(bool _revertOnMine) external {
    revertOnMine = _revertOnMine;
  }

  function setRevertOnValidateProgram(bool _revert) external {
    revertOnValidateProgram = _revert;
  }

  fallback() external { }
}

contract TestChestProgram is System {
  fallback() external { }
}

contract ForceFieldTest is DustTest {
  function attachTestProgram(EntityId entityId, System programSystem) internal returns (ProgramId) {
    bytes14 namespace = bytes14(keccak256(abi.encode(programSystem)));
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId programSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "programName");
    world.registerNamespace(namespaceId);
    world.registerSystem(programSystemId, programSystem, false);

    Vec3 coord = Position.get(entityId);
    ProgramId program = ProgramId.wrap(programSystemId.unwrap());
    // Attach program with test player
    (address bob, EntityId bobEntityId) = createTestPlayer(coord - vec3(1, 0, 0));
    vm.prank(bob);
    world.attachProgram(bobEntityId, entityId, program, "");
    return program;
  }

  function testMineWithForceFieldWithNoEnergy() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1 })
    );

    TestForceFieldProgram program = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, program);
    program.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction - 1);
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    world.mine(aliceEntityId, mineCoord, "");

    // Verify that the block was successfully mined (should be replaced with Air)
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");
  }

  function testMineFailsIfNotAllowedByForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    TestForceFieldProgram program = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, program);
    program.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction - 1);
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testMineFailsIfNotAllowedByForceFieldFragment() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    TestForceFieldFragmentProgram program = new TestForceFieldFragmentProgram();
    attachTestProgram(fragmentEntityId, program);
    program.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction - 1);
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield fragment");
    world.mine(aliceEntityId, mineCoord, "");
  }

  function testBuildWithForceFieldWithNoEnergy() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1 })
    );

    TestForceFieldProgram program = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, program);
    program.setRevertOnBuild(true);

    // Define build coordinates within force field
    Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

    // Set terrain at build coord to air
    setTerrainAtCoord(buildCoord, ObjectTypes.Air);

    // Add block to player's inventory
    ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    // Build the block
    vm.prank(alice);
    world.build(aliceEntityId, buildObjectTypeId, buildCoord, "");

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
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }),
      100 // Depleted time
    );

    TestForceFieldProgram program = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, program);
    program.setRevertOnBuild(true);

    // Define build coordinates within force field
    Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

    // Set terrain at build coord to air
    setTerrainAtCoord(buildCoord, ObjectTypes.Air);

    // Add block to player's inventory
    ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    // Try to build the block, should fail
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield");
    world.build(aliceEntityId, buildObjectTypeId, buildCoord, "");
  }

  function testBuildFailsIfNotAllowedByForceFieldFragment() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with NO energy (depleted)
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }),
      100 // depletedTime
    );

    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    TestForceFieldFragmentProgram program = new TestForceFieldFragmentProgram();
    attachTestProgram(fragmentEntityId, program);
    program.setRevertOnBuild(true);

    // Define build coordinates within force field
    Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

    // Set terrain at build coord to air
    setTerrainAtCoord(buildCoord, ObjectTypes.Air);

    // Add block to player's inventory
    ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, buildObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

    // Try to build the block, should fail
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield fragment");
    world.build(aliceEntityId, buildObjectTypeId, buildCoord, "");
  }

  function testSetupForceField() public {
    // Set up a flat chunk with a player
    (,, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(forceFieldCoord);

    // Verify that the force field is active
    assertTrue(TestForceFieldUtils.isForceFieldActive(forceFieldEntityId), "Force field not active");

    // Verify that the fragment at the force field coordinate exists
    Vec3 fragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    assertTrue(
      TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, fragmentCoord), "Force field fragment not found"
    );

    // Verify that we can get the force field from the coordinate
    (EntityId retrievedForceFieldId,) = TestForceFieldUtils.getForceField(forceFieldCoord);
    assertEq(
      EntityId.unwrap(retrievedForceFieldId), EntityId.unwrap(forceFieldEntityId), "Retrieved incorrect force field"
    );
  }

  function testFragmentProgramIsNotUsedIfNoEnergy() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with NO energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    setupForceField(forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1 }));

    // Get the fragment entity ID
    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    // Attach a program to the fragment
    TestForceFieldFragmentProgram program = new TestForceFieldFragmentProgram();
    attachTestProgram(fragmentEntityId, program);
    program.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction - 1);
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block, should not revert since forcefield has no energy
    vm.prank(alice);
    world.mine(aliceEntityId, mineCoord, "");

    // Verify that the block was successfully mined (should be replaced with Air)
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");
  }

  function testFragmentProgramIsNotUsedIfNotActive() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Get the fragment entity ID
    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    // Attach a program to the fragment
    TestForceFieldFragmentProgram program = new TestForceFieldFragmentProgram();
    attachTestProgram(fragmentEntityId, program);
    program.setRevertOnMine(true);

    // Destroy the forcefield
    TestForceFieldUtils.destroyForceField(forceFieldEntityId);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction - 1);
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block, should not revert since forcefield is destroyed
    vm.prank(alice);
    world.mine(aliceEntityId, mineCoord, "");

    // Verify that the block was successfully mined (should be replaced with Air)
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");
  }

  function testAddFragment() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    EnergyData memory initialEnergyData =
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 });

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(forceFieldCoord, initialEnergyData);

    // Define expansion area
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 newFragmentCoord = refFragmentCoord + vec3(1, 0, 0);

    // Expand the force field
    vm.prank(alice);
    startGasReport("Add single fragment");
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, newFragmentCoord, "");
    endGasReport();

    // Verify that the energy drain rate has increased
    EnergyData memory afterEnergyData = Energy.get(forceFieldEntityId);
    assertEq(
      afterEnergyData.drainRate,
      initialEnergyData.drainRate + MACHINE_ENERGY_DRAIN_RATE,
      "Energy drain rate did not increase correctly"
    );

    // Verify that each new fragment exists
    assertTrue(
      TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, newFragmentCoord),
      "Force field fragment not found at coordinate"
    );
  }

  function testRemoveFragment() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 newFragmentCoord = refFragmentCoord + vec3(1, 0, 0);

    // Add a fragment
    vm.prank(alice);
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, newFragmentCoord, "");

    // Get energy data after addition
    EnergyData memory afterAddEnergyData = Energy.get(forceFieldEntityId);

    // Compute boundary fragments
    (Vec3[26] memory boundary, uint256 len) = world.computeBoundaryFragments(forceFieldEntityId, newFragmentCoord);

    // Create a valid parent array for the boundary
    uint256[] memory parents = new uint256[](len);
    parents[0] = 0; // Root

    // Remove the fragment
    vm.prank(alice);
    startGasReport("Remove forcefield fragment");
    world.removeFragment(aliceEntityId, forceFieldEntityId, newFragmentCoord, parents, "");
    endGasReport();

    // Get energy data after removal
    EnergyData memory afterRemoveEnergyData = Energy.get(forceFieldEntityId);

    // Verify energy drain rate decreased
    assertEq(
      afterRemoveEnergyData.drainRate,
      afterAddEnergyData.drainRate - MACHINE_ENERGY_DRAIN_RATE,
      "Energy drain rate did not decrease correctly"
    );

    // Verify fragment no longer exists
    assertFalse(
      TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, newFragmentCoord),
      "Force field fragment still exists after removal"
    );

    // Verify original fragment still exists
    assertTrue(
      TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, refFragmentCoord),
      "Original force field fragment was removed"
    );
  }

  function testAddFragmentFailsIfRefFragmentNotAdjacent() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Reference fragment coordinate
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();

    // This coordinate is not adjacent to the reference fragment
    Vec3 newFragmentCoord = refFragmentCoord + vec3(2, 0, 0);

    // Add should fail because new fragment is not adjacent to reference fragment
    vm.prank(alice);
    vm.expectRevert("Reference fragment is not adjacent to new fragment");
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, newFragmentCoord, "");
  }

  function testAddFragmentFailsIfRefFragmentNotInForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Invalid reference fragment coordinate (not part of the force field)
    Vec3 invalidRefFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord() + vec3(10, 0, 0);

    // Expansion area
    Vec3 newFragmentCoord = invalidRefFragmentCoord + vec3(1, 0, 0);

    // Expand should fail because reference fragment is not part of the force field
    vm.prank(alice);
    vm.expectRevert("Reference fragment is not part of forcefield");
    world.addFragment(aliceEntityId, forceFieldEntityId, invalidRefFragmentCoord, newFragmentCoord, "");
  }

  function testRemoveFragmentFailsIfInvalidSpanningTree() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Add a fragment to the force field
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 newFragmentCoord = refFragmentCoord + vec3(1, 0, 0);

    vm.prank(alice);
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, newFragmentCoord, "");

    // Create an INVALID parent array for the boundary fragments (all zeros)
    uint256[] memory invalidParents = new uint256[](2);
    for (uint256 i = 0; i < 2; i++) {
      invalidParents[i] = 0;
    }

    // Remove should fail because the parent array doesn't represent a valid spanning tree
    vm.prank(alice);
    vm.expectRevert("Invalid spanning tree");
    world.removeFragment(aliceEntityId, forceFieldEntityId, newFragmentCoord, invalidParents, "");
  }

  function testComputeBoundaryFragments() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Expand the force field
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 fragment1 = refFragmentCoord + vec3(1, 0, 0);
    Vec3 fragment2 = refFragmentCoord + vec3(0, 1, 0);
    Vec3 fragment3 = refFragmentCoord + vec3(1, 1, 0);

    vm.startPrank(alice);
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, fragment1, "");
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, fragment2, "");
    world.addFragment(aliceEntityId, forceFieldEntityId, fragment1, fragment3, "");
    vm.stopPrank();

    // Compute the boundary fragments for fragment3
    (Vec3[26] memory boundaryFragments, uint256 len) = world.computeBoundaryFragments(forceFieldEntityId, fragment3);

    // We expect 2 boundary fragments (fragment1 and fragment2)
    assertEq(len, 3, "Expected 3 boundary fragments");

    // Verify that each boundary fragment is part of the force field
    for (uint256 i = 0; i < len; i++) {
      assertTrue(
        TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, boundaryFragments[i]),
        "Boundary fragment is not part of the force field"
      );
    }

    // Check that fragment1 and fragment2 are in the boundary
    bool foundRefFragment = false;
    bool foundFragment1 = false;
    bool foundFragment2 = false;
    for (uint256 i = 0; i < len; i++) {
      if (boundaryFragments[i] == refFragmentCoord) foundRefFragment = true;
      if (boundaryFragments[i] == fragment1) foundFragment1 = true;
      if (boundaryFragments[i] == fragment2) foundFragment2 = true;
    }
    assertTrue(foundRefFragment, "Fragment1 should be in the boundary");
    assertTrue(foundFragment1, "Fragment1 should be in the boundary");
    assertTrue(foundFragment2, "Fragment2 should be in the boundary");
  }

  function testAddIntoExistingForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create first force field
    Vec3 forceField1Coord = playerCoord + vec3(2, 0, 0);
    EntityId forceField1EntityId = setupForceField(
      forceField1Coord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Create second force field
    Vec3 forceField2Coord = forceField1Coord + vec3(FRAGMENT_SIZE, 0, 0);
    setupForceField(
      forceField2Coord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Try to expand first force field into second force field's area (should fail)
    Vec3 refFragmentCoord = forceField1Coord.toForceFieldFragmentCoord();
    Vec3 newFragmentCoord = forceField2Coord.toForceFieldFragmentCoord();
    vm.prank(alice);
    vm.expectRevert("Fragment already belongs to a forcefield");
    world.addFragment(aliceEntityId, forceField1EntityId, refFragmentCoord, newFragmentCoord, "");
  }

  function testForceFieldEnergyDrainsOverTime() public {
    // Set up a flat chunk with a player
    (address alice,, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 100, drainRate: 1 })
    );

    // Fast forward time
    uint256 timeToAdvance = 50; // seconds
    vm.warp(vm.getBlockTimestamp() + timeToAdvance);

    TestEnergyUtils.updateMachineEnergy(forceFieldEntityId);

    // Check energy level (should be reduced)
    EnergyData memory currentEnergy = Energy.get(forceFieldEntityId);
    assertEq(currentEnergy.energy, 50, "Energy should be reduced after time passes");

    // Fast forward enough time to deplete all energy
    vm.warp(vm.getBlockTimestamp() + 60);

    TestEnergyUtils.updateMachineEnergy(forceFieldEntityId);

    // Check energy level (should be 0)
    currentEnergy = Energy.get(forceFieldEntityId);
    assertEq(currentEnergy.energy, 0, "Energy should be completely depleted");
    assertEq(Machine.getDepletedTime(forceFieldEntityId), 10, "Accumulated depleted time should be tracked");
  }

  function testOnBuildAndOnMineHooksForForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Create and attach a test program
    TestForceFieldProgram program = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, program);

    // Test onBuild hook
    {
      // Set the program to allow building
      program.setRevertOnBuild(false);

      // Define build coordinates within force field
      Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

      // Set terrain at build coord to air
      setTerrainAtCoord(buildCoord, ObjectTypes.Air);

      // Add block to player's inventory
      ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
      TestInventoryUtils.addObject(aliceEntityId, buildObjectTypeId, 1);
      assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

      // Build should succeed
      vm.prank(alice);
      world.build(aliceEntityId, buildObjectTypeId, buildCoord, "");

      // Verify build succeeded
      EntityId buildEntityId = ReversePosition.get(buildCoord);
      assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Block was not built correctly");

      // Now set the program to disallow building
      program.setRevertOnBuild(true);

      // Define new build coordinates
      Vec3 buildCoord2 = forceFieldCoord + vec3(-1, 0, 1);

      // Set terrain at build coord to air
      setTerrainAtCoord(buildCoord2, ObjectTypes.Air);

      // Add block to player's inventory
      TestInventoryUtils.addObject(aliceEntityId, buildObjectTypeId, 1);
      assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

      // Build should fail
      vm.prank(alice);
      vm.expectRevert("Not allowed by forcefield");
      world.build(aliceEntityId, buildObjectTypeId, buildCoord2, "");
    }

    // Test onMine hook
    {
      // Set the program to allow mining
      program.setRevertOnMine(false);

      // Mine a block within the force field's area
      Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

      ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
      ObjectTypeMetadata.setMass(mineObjectTypeId, playerHandMassReduction - 1);
      setObjectAtCoord(mineCoord, mineObjectTypeId);

      // Mining should succeed
      vm.prank(alice);
      world.mine(aliceEntityId, mineCoord, "");

      // Verify mining succeeded
      EntityId mineEntityId = ReversePosition.get(mineCoord);
      assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");

      // Now set the program to disallow mining
      program.setRevertOnMine(true);

      // Define new mine coordinates
      Vec3 mineCoord2 = forceFieldCoord + vec3(-1, 0, 0);

      setObjectAtCoord(mineCoord2, mineObjectTypeId);

      // Mining should fail
      vm.prank(alice);
      vm.expectRevert("Not allowed by forcefield");
      world.mine(aliceEntityId, mineCoord2, "");
    }
  }

  function testOverlappingForceFieldBoundaries() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create first force field
    Vec3 forceField1Coord = playerCoord - vec3(10, 0, 0);
    EntityId forceField1EntityId = setupForceField(
      forceField1Coord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Create second force field
    Vec3 forceField2Coord = playerCoord + vec3(10, 0, 0);
    EntityId forceField2EntityId = setupForceField(
      forceField2Coord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Add fragment to first force field
    Vec3 refFragmentCoord1 = forceField1Coord.toForceFieldFragmentCoord();
    Vec3 newFragment1 = refFragmentCoord1 + vec3(1, 0, 0);
    vm.prank(alice);
    world.addFragment(aliceEntityId, forceField1EntityId, refFragmentCoord1, newFragment1, "");

    // Add fragment to second force field
    Vec3 refFragmentCoord2 = forceField2Coord.toForceFieldFragmentCoord();
    Vec3 newFragment2 = refFragmentCoord2 - vec3(1, 0, 0);
    vm.prank(alice);
    world.addFragment(aliceEntityId, forceField2EntityId, refFragmentCoord2, newFragment2, "");

    // Try to add fragment to first force field in area occupied by second force field
    // This should fail
    vm.prank(alice);
    vm.expectRevert("Fragment already belongs to a forcefield");
    world.addFragment(aliceEntityId, forceField1EntityId, newFragment1, newFragment2, "");

    // Try to add fragment to second force field in area occupied by first force field
    // This should fail
    vm.prank(alice);
    vm.expectRevert("Fragment already belongs to a forcefield");
    world.addFragment(aliceEntityId, forceField2EntityId, newFragment2, newFragment1, "");
  }

  function testForceFieldFragmentGasUsage() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000, drainRate: 1 })
    );

    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 newFragmentCoord = refFragmentCoord + vec3(1, 0, 0);

    // Test adding a fragment
    vm.startPrank(alice);

    startGasReport("Add forcefield fragment");
    world.addFragment(aliceEntityId, forceFieldEntityId, refFragmentCoord, newFragmentCoord, "");
    endGasReport();

    // Compute boundary fragments for removal
    (, uint256 len) = world.computeBoundaryFragments(forceFieldEntityId, newFragmentCoord);
    uint256[] memory parents = new uint256[](len);
    parents[0] = 0; // Root

    startGasReport("Remove forcefield fragment");
    world.removeFragment(aliceEntityId, forceFieldEntityId, newFragmentCoord, parents, "");
    endGasReport();

    vm.stopPrank();
  }

  function testAttachProgramToObjectInForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Create forcefield program and attach it
    TestForceFieldProgram forceFieldProgram = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, forceFieldProgram);

    // Set up a chest inside the forcefield
    Vec3 chestCoord = forceFieldCoord + vec3(1, 0, 0);
    setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    // Create a chest program
    TestChestProgram chestProgram = new TestChestProgram();

    // Register the chest program
    bytes14 namespace = "chestProgramNS";
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId programSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "chestProgram");
    world.registerNamespace(namespaceId);
    world.registerSystem(programSystemId, chestProgram, false);

    // Expect the forcefield program's onProgramAttached to be called with the correct parameters
    bytes memory expectedCallData = abi.encodeCall(
      TestForceFieldProgram.validateProgram,
      (aliceEntityId, forceFieldEntityId, chestEntityId, ProgramId.wrap(programSystemId.unwrap()), bytes(""))
    );
    vm.expectCall(address(forceFieldProgram), expectedCallData);

    // Attach program with test player
    vm.prank(alice);
    world.attachProgram(aliceEntityId, chestEntityId, ProgramId.wrap(programSystemId.unwrap()), "");
  }

  function testAttachProgramToObjectInForceFieldFailsWhenDisallowed() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 })
    );

    // Create forcefield program, attach it, and configure it to disallow program attachments
    TestForceFieldProgram forceFieldProgram = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, forceFieldProgram);
    forceFieldProgram.setRevertOnValidateProgram(true);

    // Set up a chest inside the forcefield
    Vec3 chestCoord = forceFieldCoord + vec3(1, 0, 0);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    // Create the chest program
    TestChestProgram chestProgram = new TestChestProgram();
    bytes14 namespace = bytes14(vm.randomBytes(14));
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId programSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "programName");
    world.registerNamespace(namespaceId);
    world.registerSystem(programSystemId, chestProgram, false);

    // Attach program with test player
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield");
    // Attempt to attach program with test player, should fail
    world.attachProgram(aliceEntityId, chestEntityId, ProgramId.wrap(programSystemId.unwrap()), "");
  }

  function testAttachProgramToObjectWithNoForceFieldEnergy() public {
    // Set up a flat chunk with a player
    (,, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with NO energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1 })
    );

    // Create forcefield program and attach it
    TestForceFieldProgram forceFieldProgram = new TestForceFieldProgram();
    attachTestProgram(forceFieldEntityId, forceFieldProgram);
    forceFieldProgram.setRevertOnValidateProgram(true); // Should not matter since forcefield has no energy

    // Set up a chest inside the forcefield
    Vec3 chestCoord = forceFieldCoord + vec3(1, 0, 0);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    // Register the chest program
    TestChestProgram chestProgram = new TestChestProgram();

    // We explicitly do NOT use vm.expectCall here since we're testing that
    // the hook is NOT called when there's no energy

    // Attach the program
    ProgramId program = attachTestProgram(chestEntityId, chestProgram);
    assertEq(EntityProgram.get(chestEntityId), program, "Program not atached to chest");
  }

  function testValidateSpanningTree() public view {
    // Test case 1: Empty array (trivial case)
    {
      Vec3[26] memory fragments;
      uint256[] memory parents = new uint256[](0);
      assertFalse(world.validateSpanningTree(fragments, 0, parents), "Empty array should not be valid");
    }

    // Test case 2: Single node (trivial case)
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      uint256[] memory parents = new uint256[](1);
      parents[0] = 0; // Self-referential
      assertTrue(world.validateSpanningTree(fragments, 1, parents), "Single node should be valid");
    }

    // Test case 3: Simple line of 3 nodes
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(2, 0, 0); // Adjacent to fragments[1]

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0; // Root
      parents[1] = 0; // Parent is fragments[0]
      parents[2] = 1; // Parent is fragments[1]

      assertTrue(world.validateSpanningTree(fragments, 3, parents), "Line of 3 nodes should be valid");
    }

    // Test case 4: Star pattern (all nodes connected to root)
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0); // Center
      fragments[1] = vec3(1, 0, 0); // East
      fragments[2] = vec3(0, 1, 0); // North
      fragments[3] = vec3(-1, 0, 0); // West
      fragments[4] = vec3(0, -1, 0); // South

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0; // Root
      parents[1] = 0; // All connected to root
      parents[2] = 0;
      parents[3] = 0;
      parents[4] = 0;

      assertTrue(world.validateSpanningTree(fragments, 5, parents), "Star pattern should be valid");
    }

    // Test case 5: Invalid - parents array length mismatch
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);

      uint256[] memory parents = new uint256[](2); // Missing one parent
      parents[0] = 0;
      parents[1] = 0;

      assertFalse(world.validateSpanningTree(fragments, 3, parents), "Invalid parents length");
    }

    // Test case 6: Invalid - non-adjacent nodes
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(3, 0, 0); // NOT adjacent to fragments[1] (distance = 2)

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1; // Claims fragments[1] is parent, but they're not adjacent

      assertFalse(world.validateSpanningTree(fragments, 3, parents), "Non-adjacent fragments");
    }

    // Test case 7: Invalid - disconnected graph
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(5, 0, 0); // Disconnected from others
      fragments[3] = vec3(6, 0, 0); // Adjacent to fragments[2] but not to fragments[0] or fragments[1]

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 2; // Self-referential, creating a second "root"
      parents[3] = 2;

      assertFalse(world.validateSpanningTree(fragments, 4, parents), "Disconnected graph should be invalid");
    }

    // Test case 8: Invalid - cycle in the graph
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(1, 1, 0); // Adjacent to fragments[1]

      uint256[] memory parents = new uint256[](3);
      parents[0] = 2; // Creates a cycle: 0->2->1->0
      parents[1] = 0;
      parents[2] = 1;

      assertFalse(world.validateSpanningTree(fragments, 3, parents), "Root must be self-referential");
    }

    // Test case 9: Valid - complex tree with branches
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0); // Root
      fragments[1] = vec3(1, 0, 0); // Level 1, branch 1
      fragments[2] = vec3(0, 1, 0); // Level 1, branch 2
      fragments[3] = vec3(2, 0, 0); // Level 2, from branch 1
      fragments[4] = vec3(1, 1, 0); // Level 2, from branch 2
      fragments[5] = vec3(0, 2, 0); // Level 2, from branch 2
      fragments[6] = vec3(3, 0, 0); // Level 3, from branch 1

      uint256[] memory parents = new uint256[](7);
      parents[0] = 0; // Root
      parents[1] = 0; // Connected to root
      parents[2] = 0; // Connected to root
      parents[3] = 1; // Connected to branch 1
      parents[4] = 2; // Connected to branch 2
      parents[5] = 2; // Connected to branch 2
      parents[6] = 3; // Connected to level 2 of branch 1

      assertTrue(world.validateSpanningTree(fragments, 7, parents), "Complex tree should be valid");
    }

    // Test case 10: Invalid - diagonal neighbors (not in Von Neumann neighborhood)
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 1, 0); // Diagonal to fragments[0], not in Von Neumann neighborhood

      uint256[] memory parents = new uint256[](2);
      parents[0] = 0;
      parents[1] = 0;

      assertFalse(world.validateSpanningTree(fragments, 2, parents), "Non-adjacent fragments");
    }

    // Test case 11: Invalid - parent index out of bounds
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 999; // Parent index out of bounds

      assertFalse(world.validateSpanningTree(fragments, 3, parents), "Parent index out of bounds");
    }

    // Test case 12: Invalid - cycle in the middle of the array
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);
      fragments[4] = vec3(4, 0, 0);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0; // Root is valid
      parents[1] = 0; // Valid
      parents[2] = 3; // Creates a cycle with node 3
      parents[3] = 2; // Part of the cycle
      parents[4] = 3; // Valid connection to node 3

      assertFalse(world.validateSpanningTree(fragments, 5, parents), "Cycle in the middle of the array");
    }

    // Test case 13: Invalid - multiple nodes pointing to non-existent parent
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);
      fragments[4] = vec3(4, 0, 0);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0;
      parents[1] = 10; // Invalid parent
      parents[2] = 10; // Same invalid parent
      parents[3] = 10; // Same invalid parent
      parents[4] = 0;

      assertFalse(world.validateSpanningTree(fragments, 5, parents), "Multiple nodes pointing to non-existent parent");
    }

    // Test case 14: Invalid - node is its own parent (except root)
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0; // Valid root
      parents[1] = 0; // Valid
      parents[2] = 2; // Node is its own parent
      parents[3] = 2; // Valid

      assertFalse(world.validateSpanningTree(fragments, 4, parents), "Node cannot be its own parent");
    }

    // Test case 15: Invalid - complex cycle in a larger graph
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);
      fragments[4] = vec3(4, 0, 0);
      fragments[5] = vec3(3, 1, 0);
      fragments[6] = vec3(2, 1, 0);
      fragments[7] = vec3(1, 1, 0);

      uint256[] memory parents = new uint256[](8);
      parents[0] = 0; // Root
      parents[1] = 0; // Valid
      parents[2] = 1; // Valid
      parents[3] = 2; // Valid
      parents[4] = 3; // Valid
      parents[5] = 6; // Part of cycle
      parents[6] = 7; // Part of cycle
      parents[7] = 5; // Creates cycle: 5->6->7->5

      assertFalse(world.validateSpanningTree(fragments, 8, parents), "Complex cycle in larger graph");
    }

    // Test case 16: Invalid - root not at index 0
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 1; // Not self-referential
      parents[1] = 1; // This is the root
      parents[2] = 1;
      parents[3] = 2;

      assertFalse(world.validateSpanningTree(fragments, 4, parents), "Root must be at index 0");
    }

    // Test case 17: Invalid - parent references later index (creating forward reference)
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(1, 1, 0);
      fragments[3] = vec3(0, 1, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0; // Valid root
      parents[1] = 3; // Forward reference to node 3
      parents[2] = 1;
      parents[3] = 0;

      assertFalse(world.validateSpanningTree(fragments, 4, parents), "Forward reference creates invalid tree");
    }

    // Test case 18: Valid - zigzag pattern
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(1, 1, 0);
      fragments[3] = vec3(0, 1, 0);
      fragments[4] = vec3(0, 2, 0);

      uint256[] memory parents = new uint256[](5);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1;
      parents[3] = 2;
      parents[4] = 3;

      assertTrue(world.validateSpanningTree(fragments, 5, parents), "Zigzag pattern should be valid");
    }

    // Test case 19: Invalid - multiple roots
    {
      Vec3[26] memory fragments;
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(10, 0, 0); // Disconnected section
      fragments[4] = vec3(11, 0, 0);
      fragments[5] = vec3(12, 0, 0);

      uint256[] memory parents = new uint256[](6);
      parents[0] = 0; // First root
      parents[1] = 0;
      parents[2] = 1;
      parents[3] = 3; // Second root
      parents[4] = 3;
      parents[5] = 4;

      assertFalse(world.validateSpanningTree(fragments, 6, parents), "Multiple roots should be invalid");
    }

    // Test case 20: Invalid - complex disconnected components
    {
      Vec3[26] memory fragments;
      // Component 1
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      // Component 2
      fragments[3] = vec3(10, 0, 0);
      fragments[4] = vec3(11, 0, 0);
      // Component 3
      fragments[5] = vec3(20, 0, 0);
      fragments[6] = vec3(21, 0, 0);
      fragments[7] = vec3(22, 0, 0);
      fragments[8] = vec3(23, 0, 0);
      fragments[9] = vec3(24, 0, 0);

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

      assertFalse(
        world.validateSpanningTree(fragments, 10, parents), "Complex disconnected components should be invalid"
      );
    }
  }
}
