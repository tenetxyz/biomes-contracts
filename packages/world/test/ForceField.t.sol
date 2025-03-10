// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

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
import { MACHINE_ENERGY_DRAIN_RATE, FORCE_FIELD_FRAGMENT_DIM } from "../src/Constants.sol";
import { IForceFieldChip } from "../src/prototypes/IForceFieldChip.sol";
import { IForceFieldFragmentChip } from "../src/prototypes/IForceFieldFragmentChip.sol";
import { TestForceFieldUtils, TestInventoryUtils, TestEnergyUtils } from "./utils/TestUtils.sol";

contract TestForceFieldChip is IForceFieldChip, System {
  // Just for testing, real chips should use tables
  bool revertOnBuild;
  bool revertOnMine;

  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory) external payable {}

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory) external payable {}

  function onChipAttached(EntityId callerEntityId, EntityId targetEntityId, EntityId, bytes memory) external {}

  function onChipDetached(EntityId callerEntityId, EntityId targetEntityId, EntityId, bytes memory) external {}

  function onBuild(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnBuild, "Not allowed by forcefield");
  }

  function onMine(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnMine, "Not allowed by forcefield");
  }

  function onPowered(EntityId callerEntityId, EntityId targetEntityId, uint16 numBattery) external {}

  function onForceFieldHit(EntityId callerEntityId, EntityId targetEntityId) external {}

  function onExpand(
    EntityId callerEntityId,
    EntityId targetEntityId,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord,
    bytes memory extraData
  ) external {}

  function onContract(
    EntityId callerEntityId,
    EntityId targetEntityId,
    Vec3 fromFragmentCoord,
    Vec3 toFragmentCoord,
    bytes memory extraData
  ) external {}

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

contract TestForceFieldFragmentChip is IForceFieldFragmentChip, System {
  // Just for testing, real chips should use tables
  bool revertOnBuild;
  bool revertOnMine;

  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onChipAttached(EntityId callerEntityId, EntityId targetEntityId, EntityId, bytes memory) external {}

  function onChipDetached(EntityId callerEntityId, EntityId targetEntityId, EntityId, bytes memory) external {}

  function onBuild(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnBuild, "Not allowed by forcefield fragment");
  }

  function onMine(EntityId, EntityId, ObjectTypeId, Vec3, bytes memory) external payable {
    require(!revertOnMine, "Not allowed by forcefield fragment");
  }

  function setRevertOnBuild(bool _revertOnBuild) external {
    revertOnBuild = _revertOnBuild;
  }

  function setRevertOnMine(bool _revertOnMine) external {
    revertOnMine = _revertOnMine;
  }

  function supportsInterface(bytes4 interfaceId) public pure override(IERC165, WorldContextConsumer) returns (bool) {
    return interfaceId == type(IForceFieldFragmentChip).interfaceId || super.supportsInterface(interfaceId);
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

  function testMineFailsIfNotAllowedByForceFieldFragment() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    TestForceFieldFragmentChip chip = new TestForceFieldFragmentChip();
    attachTestChip(fragmentEntityId, chip);
    chip.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block
    vm.prank(alice);
    vm.expectRevert("Not allowed by forcefield fragment");
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

  function testBuildFailsIfNotAllowedByForceFieldFragment() public {
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

    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    TestForceFieldFragmentChip chip = new TestForceFieldFragmentChip();
    attachTestChip(fragmentEntityId, chip);
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
    vm.expectRevert("Not allowed by forcefield fragment");
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

    // Verify that the fragment at the force field coordinate exists
    Vec3 fragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    assertTrue(
      TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, fragmentCoord),
      "Force field fragment not found"
    );

    // Verify that we can get the force field from the coordinate
    (EntityId retrievedForceFieldId, ) = TestForceFieldUtils.getForceField(forceFieldCoord);
    assertEq(
      EntityId.unwrap(retrievedForceFieldId),
      EntityId.unwrap(forceFieldEntityId),
      "Retrieved incorrect force field"
    );
  }

  function testFragmentChipIsNotUsedIfNoEnergy() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with NO energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 0, drainRate: 1, accDepletedTime: 0 })
    );

    // Get the fragment entity ID
    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    // Attach a chip to the fragment
    TestForceFieldFragmentChip chip = new TestForceFieldFragmentChip();
    attachTestChip(fragmentEntityId, chip);
    chip.setRevertOnMine(true);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block, should not revert since forcefield has no energy
    vm.prank(alice);
    world.mine(mineCoord);

    // Verify that the block was successfully mined (should be replaced with Air)
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");
  }

  function testFragmentChipIsNotUsedIfNotActive() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Get the fragment entity ID
    (, EntityId fragmentEntityId) = TestForceFieldUtils.getForceField(forceFieldCoord);

    // Attach a chip to the fragment
    TestForceFieldFragmentChip chip = new TestForceFieldFragmentChip();
    attachTestChip(fragmentEntityId, chip);
    chip.setRevertOnMine(true);

    // Destroy the forcefield
    TestForceFieldUtils.destroyForceField(forceFieldEntityId);

    // Mine a block within the force field's area
    Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

    ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
    setObjectAtCoord(mineCoord, mineObjectTypeId);

    // Prank as the player to mine the block, should not revert since forcefield is destroyed
    vm.prank(alice);
    world.mine(mineCoord);

    // Verify that the block was successfully mined (should be replaced with Air)
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");
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
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 fromFragmentCoord = refFragmentCoord + vec3(1, 0, 0);
    Vec3 toFragmentCoord = refFragmentCoord + vec3(2, 0, 1);

    // Expand the force field
    vm.prank(alice);
    startGasReport("Expand forcefield 2x2");
    world.expandForceField(forceFieldEntityId, refFragmentCoord, fromFragmentCoord, toFragmentCoord);
    endGasReport();

    // Calculate expected number of added fragments (2x1x2 = 4 new fragments)
    uint128 addedFragments = 4;

    // Verify that the energy drain rate has increased
    EnergyData memory afterEnergyData = Energy.get(forceFieldEntityId);
    assertEq(
      afterEnergyData.drainRate,
      initialEnergyData.drainRate + MACHINE_ENERGY_DRAIN_RATE * addedFragments,
      "Energy drain rate did not increase correctly"
    );

    // Verify that each new fragment exists
    for (int32 x = fromFragmentCoord.x(); x <= toFragmentCoord.x(); x++) {
      for (int32 y = fromFragmentCoord.y(); y <= toFragmentCoord.y(); y++) {
        for (int32 z = fromFragmentCoord.z(); z <= toFragmentCoord.z(); z++) {
          Vec3 fragmentCoord = vec3(x, y, z);
          assertTrue(
            TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, fragmentCoord),
            "Force field fragment not found at coordinate"
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

    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();

    // Expand the force field
    vm.prank(alice);
    startGasReport("Expand forcefield 3x3");
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(3, 0, 2)
    );
    endGasReport();

    // Get energy data after expansion
    EnergyData memory afterExpandEnergyData = Energy.get(forceFieldEntityId);

    // Contract a portion of the force field within a scope
    {
      Vec3 contractFrom = refFragmentCoord + vec3(2, 0, 0);
      Vec3 contractTo = refFragmentCoord + vec3(3, 0, 1);

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

    // Verify energy drain rate (4 fragments removed: 2x1x2)
    assertEq(
      afterContractEnergyData.drainRate,
      afterExpandEnergyData.drainRate - MACHINE_ENERGY_DRAIN_RATE * 4,
      "Energy drain rate did not decrease correctly"
    );

    // Verify removed fragments no longer exist
    for (int32 x = refFragmentCoord.x() + 2; x <= refFragmentCoord.x() + 3; x++) {
      for (int32 y = refFragmentCoord.y(); y <= refFragmentCoord.y(); y++) {
        for (int32 z = refFragmentCoord.z(); z <= refFragmentCoord.z() + 1; z++) {
          assertFalse(
            TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, vec3(x, y, z)),
            "Force field fragment still exists after contraction"
          );
        }
      }
    }

    // Verify original fragment still exists
    assertTrue(
      TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, refFragmentCoord),
      "Original force field fragment was removed"
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

    // Reference fragment coordinate
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();

    // Test with fromFragmentCoord > toFragmentCoord (invalid)
    Vec3 fromFragmentCoord = refFragmentCoord + vec3(2, 0, 0);
    Vec3 toFragmentCoord = refFragmentCoord + vec3(1, 0, 0);

    // Expand should fail with these invalid coordinates
    vm.prank(alice);
    vm.expectRevert("Invalid coordinates");
    world.expandForceField(forceFieldEntityId, refFragmentCoord, fromFragmentCoord, toFragmentCoord);
  }

  function testExpandForceFieldFailsIfRefFragmentNotAdjacent() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Reference fragment coordinate
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();

    // These coordinates are not adjacent to the reference fragment
    Vec3 fromFragmentCoord = refFragmentCoord + vec3(3, 0, 0);
    Vec3 toFragmentCoord = refFragmentCoord + vec3(4, 0, 0);

    // Expand should fail because new fragments not adjacent to reference fragment
    vm.prank(alice);
    vm.expectRevert("Reference fragment is not adjacent to new fragments");
    world.expandForceField(forceFieldEntityId, refFragmentCoord, fromFragmentCoord, toFragmentCoord);
  }

  function testExpandForceFieldFailsIfRefFragmentNotInForceField() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Invalid reference fragment coordinate (not part of the force field)
    Vec3 invalidRefFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord() + vec3(10, 0, 0);

    // Expansion area
    Vec3 fromFragmentCoord = invalidRefFragmentCoord + vec3(1, 0, 0);
    Vec3 toFragmentCoord = invalidRefFragmentCoord + vec3(2, 0, 0);

    // Expand should fail because reference fragment is not part of the force field
    vm.prank(alice);
    vm.expectRevert("Reference fragment is not part of forcefield");
    world.expandForceField(forceFieldEntityId, invalidRefFragmentCoord, fromFragmentCoord, toFragmentCoord);
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
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 expandFromFragmentCoord = refFragmentCoord + vec3(1, 0, 0);
    Vec3 expandToFragmentCoord = refFragmentCoord + vec3(3, 0, 2);

    // Expand the force field
    vm.prank(alice);
    world.expandForceField(forceFieldEntityId, refFragmentCoord, expandFromFragmentCoord, expandToFragmentCoord);

    // Try to contract with invalid coordinates (from > to)
    Vec3 contractFromFragmentCoord = refFragmentCoord + vec3(3, 0, 0);
    Vec3 contractToFragmentCoord = refFragmentCoord + vec3(1, 0, 0);
    uint256[] memory parents = new uint256[](0);

    // Contract should fail with invalid coordinates
    vm.prank(alice);
    vm.expectRevert("Invalid coordinates");
    world.contractForceField(forceFieldEntityId, contractFromFragmentCoord, contractToFragmentCoord, parents);
  }

  function testContractForceFieldFailsIfNoBoundaryFragments() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Try to contract an area that has no fragments or boundaries
    Vec3 contractFromFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord() + vec3(10, 0, 0);
    Vec3 contractToFragmentCoord = contractFromFragmentCoord + vec3(1, 0, 0);
    uint256[] memory parents = new uint256[](0);

    // Contract should fail because there are no boundary fragments
    vm.prank(alice);
    vm.expectRevert("No boundary fragments found");
    world.contractForceField(forceFieldEntityId, contractFromFragmentCoord, contractToFragmentCoord, parents);
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
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 expandFromFragmentCoord = refFragmentCoord + vec3(1, 0, 0);
    Vec3 expandToFragmentCoord = refFragmentCoord + vec3(3, 0, 2);

    // Expand the force field
    vm.prank(alice);
    world.expandForceField(forceFieldEntityId, refFragmentCoord, expandFromFragmentCoord, expandToFragmentCoord);

    // Try to contract with valid coordinates but invalid parent array
    Vec3 contractFromFragmentCoord = refFragmentCoord + vec3(2, 0, 0);
    Vec3 contractToFragmentCoord = refFragmentCoord + vec3(3, 0, 1);

    // Compute the boundary fragments that will remain after contraction
    (Vec3[] memory boundaryFragments, uint256 len) = world.computeBoundaryFragments(
      forceFieldEntityId,
      contractFromFragmentCoord,
      contractToFragmentCoord
    );

    // Create an INVALID parent array for the boundary fragments (all zeros)
    uint256[] memory invalidParents = new uint256[](len);
    for (uint256 i = 0; i < len; i++) {
      invalidParents[i] = 0; // This creates disconnected components
    }

    // Contract should fail because the parent array doesn't represent a valid spanning tree
    vm.prank(alice);
    vm.expectRevert("Invalid spanning tree");
    world.contractForceField(forceFieldEntityId, contractFromFragmentCoord, contractToFragmentCoord, invalidParents);
  }

  function testComputeBoundaryFragments() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a 3x3x3 force field
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Expand the force field to create a 3x3x3 cube
    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();
    Vec3 expandFromFragmentCoord = refFragmentCoord + vec3(1, 0, 0);
    Vec3 expandToFragmentCoord = expandFromFragmentCoord + vec3(2, 2, 2);

    vm.prank(alice);
    world.expandForceField(forceFieldEntityId, refFragmentCoord, expandFromFragmentCoord, expandToFragmentCoord);

    // Define a 1x1x1 cuboid in the center to remove
    Vec3 contractFromFragmentCoord = expandFromFragmentCoord + vec3(1, 1, 1);
    Vec3 contractToFragmentCoord = contractFromFragmentCoord;

    // Compute the boundary fragments
    (Vec3[] memory boundaryFragments, uint256 len) = world.computeBoundaryFragments(
      forceFieldEntityId,
      contractFromFragmentCoord,
      contractToFragmentCoord
    );

    // For a 1x1x1 cuboid, we expect 26 boundary fragments (one on each face plus edges/corners)
    assertEq(len, 26, "Expected 26 boundary fragments for a 1x1x1 cuboid");

    // Verify that each boundary fragment is part of the force field
    for (uint256 i = 0; i < len; i++) {
      assertTrue(
        TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, boundaryFragments[i]),
        "Boundary fragment is not part of the force field"
      );
    }

    // Define expected boundary fragments to check
    Vec3[26] memory expectedBoundaries = contractFromFragmentCoord.neighbors26();

    // Check each expected boundary
    for (uint256 i = 0; i < expectedBoundaries.length; i++) {
      bool found = false;
      for (uint256 j = 0; j < len; j++) {
        if (expectedBoundaries[i] == boundaryFragments[j]) {
          found = true;
          break;
        }
      }
      assertTrue(found, "Missing boundary fragment");
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
    Vec3 forceField2Coord = forceField1Coord + vec3(FORCE_FIELD_FRAGMENT_DIM, 0, 0);
    setupForceField(
      forceField2Coord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Try to expand first force field into second force field's area (should fail)
    Vec3 refFragmentCoord = forceField1Coord.toForceFieldFragmentCoord();
    vm.prank(alice);
    vm.expectRevert("Can't expand to existing forcefield");
    world.expandForceField(
      forceField1EntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(1, 0, 0)
    );
  }

  function testForceFieldEnergyDrainsOverTime() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 100, drainRate: 1, accDepletedTime: 0 })
    );

    // Fast forward time
    uint256 timeToAdvance = 50; // seconds
    vm.warp(vm.getBlockTimestamp() + timeToAdvance);

    TestEnergyUtils.updateEnergyLevel(forceFieldEntityId);

    // Check energy level (should be reduced)
    EnergyData memory currentEnergy = Energy.get(forceFieldEntityId);
    assertEq(currentEnergy.energy, 50, "Energy should be reduced after time passes");

    // Fast forward enough time to deplete all energy
    vm.warp(vm.getBlockTimestamp() + 60);

    TestEnergyUtils.updateEnergyLevel(forceFieldEntityId);

    // Check energy level (should be 0)
    currentEnergy = Energy.get(forceFieldEntityId);
    assertEq(currentEnergy.energy, 0, "Energy should be completely depleted");
    assertEq(currentEnergy.accDepletedTime, 10, "Accumulated depleted time should be tracked");
  }

  function testExpandAndContractForceFieldComplex() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();

    // Expand in multiple directions to create a complex shape
    vm.startPrank(alice);

    // Expand in the X direction
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(2, 0, 0)
    );

    // Expand in the Y direction
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(0, 1, 0),
      refFragmentCoord + vec3(0, 2, 0)
    );

    // Expand in the Z direction
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(0, 0, 1),
      refFragmentCoord + vec3(0, 0, 2)
    );

    // Expand diagonally from a different reference point
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord + vec3(2, 0, 0),
      refFragmentCoord + vec3(3, 0, 0),
      refFragmentCoord + vec3(3, 1, 1)
    );

    vm.stopPrank();

    // Now contract part of the force field (removing everything in x > 1)
    Vec3 contractFrom = refFragmentCoord + vec3(2, 0, 0);
    Vec3 contractTo = refFragmentCoord + vec3(4, 1, 1);

    // Compute boundary fragments
    (Vec3[] memory boundaryFragments, uint256 len) = world.computeBoundaryFragments(
      forceFieldEntityId,
      contractFrom,
      contractTo
    );

    // Ensure we have the correct number of boundary fragments
    assertEq(len, 1, "Expected 1 boundary fragment");

    // Create a valid spanning tree for the boundary
    uint256[] memory parents = new uint256[](len);
    parents[0] = 0; // Root

    vm.prank(alice);
    world.contractForceField(forceFieldEntityId, contractFrom, contractTo, parents);

    uint256 remainingFragments = 0;

    // Check all possible locations where fragments might be
    for (int32 x = refFragmentCoord.x(); x <= refFragmentCoord.x() + 3; x++) {
      for (int32 y = refFragmentCoord.y(); y <= refFragmentCoord.y() + 3; y++) {
        for (int32 z = refFragmentCoord.z(); z <= refFragmentCoord.z() + 3; z++) {
          if (TestForceFieldUtils.isForceFieldFragment(forceFieldEntityId, vec3(x, y, z))) {
            remainingFragments++;
          }
        }
      }
    }

    // Remaing fragments are the main fragment plus 4 fragments in x == 1 and 1 fragment in x == 2
    assertEq(remainingFragments, 6, "Expected 6 remaining fragments after contraction");

    // Check energy drain rate has been updated correctly
    EnergyData memory energyData = Energy.get(forceFieldEntityId);
    assertEq(
      energyData.drainRate,
      1 + MACHINE_ENERGY_DRAIN_RATE * 5, // 1 (base) + 5 (additional fragments)
      "Energy drain rate should be updated"
    );
  }

  function testOnBuildAndOnMineHooksForForceField() public {
    // Set up a flat chunk with a player
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Set up a force field
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Create and attach a test chip
    TestForceFieldChip chip = new TestForceFieldChip();
    attachTestChip(forceFieldEntityId, chip);

    // Test onBuild hook
    {
      // Set the chip to allow building
      chip.setRevertOnBuild(false);

      // Define build coordinates within force field
      Vec3 buildCoord = forceFieldCoord + vec3(1, 0, 1);

      // Set terrain at build coord to air
      setTerrainAtCoord(buildCoord, ObjectTypes.Air);

      // Add block to player's inventory
      ObjectTypeId buildObjectTypeId = ObjectTypes.Grass;
      TestInventoryUtils.addToInventory(aliceEntityId, buildObjectTypeId, 1);
      assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

      // Build should succeed
      vm.prank(alice);
      world.build(buildObjectTypeId, buildCoord);

      // Verify build succeeded
      EntityId buildEntityId = ReversePosition.get(buildCoord);
      assertTrue(ObjectType.get(buildEntityId) == buildObjectTypeId, "Block was not built correctly");

      // Now set the chip to disallow building
      chip.setRevertOnBuild(true);

      // Define new build coordinates
      Vec3 buildCoord2 = forceFieldCoord + vec3(-1, 0, 1);

      // Set terrain at build coord to air
      setTerrainAtCoord(buildCoord2, ObjectTypes.Air);

      // Add block to player's inventory
      TestInventoryUtils.addToInventory(aliceEntityId, buildObjectTypeId, 1);
      assertInventoryHasObject(aliceEntityId, buildObjectTypeId, 1);

      // Build should fail
      vm.prank(alice);
      vm.expectRevert("Not allowed by forcefield");
      world.build(buildObjectTypeId, buildCoord2);
    }

    // Test onMine hook
    {
      // Set the chip to allow mining
      chip.setRevertOnMine(false);

      // Mine a block within the force field's area
      Vec3 mineCoord = forceFieldCoord + vec3(1, 0, 0);

      ObjectTypeId mineObjectTypeId = ObjectTypes.Grass;
      ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(playerHandMassReduction - 1));
      setObjectAtCoord(mineCoord, mineObjectTypeId);

      // Mining should succeed
      vm.prank(alice);
      world.mine(mineCoord);

      // Verify mining succeeded
      EntityId mineEntityId = ReversePosition.get(mineCoord);
      assertTrue(ObjectType.get(mineEntityId) == ObjectTypes.Air, "Block was not mined");

      // Now set the chip to disallow mining
      chip.setRevertOnMine(true);

      // Define new mine coordinates
      Vec3 mineCoord2 = forceFieldCoord + vec3(-1, 0, 0);

      setObjectAtCoord(mineCoord2, mineObjectTypeId);

      // Mining should fail
      vm.prank(alice);
      vm.expectRevert("Not allowed by forcefield");
      world.mine(mineCoord2);
    }
  }

  function testOverlappingForceFieldBoundaries() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create first force field
    Vec3 forceField1Coord = playerCoord - vec3(10, 0, 0);
    EntityId forceField1EntityId = setupForceField(
      forceField1Coord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Create second force field
    Vec3 forceField2Coord = playerCoord + vec3(10, 0, 0);
    EntityId forceField2EntityId = setupForceField(
      forceField2Coord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1, accDepletedTime: 0 })
    );

    // Expand first force field towards second
    Vec3 refFragmentCoord1 = forceField1Coord.toForceFieldFragmentCoord();
    vm.prank(alice);
    world.expandForceField(
      forceField1EntityId,
      refFragmentCoord1,
      refFragmentCoord1 + vec3(1, 0, 0),
      refFragmentCoord1 + vec3(1, 0, 0)
    );

    // Expand second force field towards first
    Vec3 refFragmentCoord2 = forceField2Coord.toForceFieldFragmentCoord();
    vm.prank(alice);
    world.expandForceField(
      forceField2EntityId,
      refFragmentCoord2,
      refFragmentCoord2 - vec3(1, 0, 0),
      refFragmentCoord2 - vec3(1, 0, 0)
    );

    // Try to expand first force field into area occupied by second force field
    // This should fail
    vm.prank(alice);
    vm.expectRevert("Can't expand to existing forcefield");
    world.expandForceField(
      forceField1EntityId,
      refFragmentCoord1 + vec3(1, 0, 0),
      refFragmentCoord1 + vec3(2, 0, 0),
      refFragmentCoord1 + vec3(2, 0, 0)
    );

    // Try to expand second force field into area occupied by first force field
    // This should fail
    vm.prank(alice);
    vm.expectRevert("Can't expand to existing forcefield");
    world.expandForceField(
      forceField2EntityId,
      refFragmentCoord2 - vec3(1, 0, 0),
      refFragmentCoord2 - vec3(2, 0, 0),
      refFragmentCoord2 - vec3(2, 0, 0)
    );
  }

  function testForceFieldExpandGasUsage() public {
    // Set up a flat chunk with a player
    (address alice, , Vec3 playerCoord) = setupFlatChunkWithPlayer();

    // Create a force field with energy
    Vec3 forceFieldCoord = playerCoord + vec3(2, 0, 0);
    EntityId forceFieldEntityId = setupForceField(
      forceFieldCoord,
      EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 10000, drainRate: 1, accDepletedTime: 0 })
    );

    Vec3 refFragmentCoord = forceFieldCoord.toForceFieldFragmentCoord();

    uint256 snapshotId = vm.snapshotState();

    // Test expanding with different cuboid sizes
    vm.startPrank(alice);

    // 1x1x1 expansion (single fragment)
    startGasReport("Expand forcefield 1x1x1");
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(1, 0, 0)
    );
    endGasReport();

    vm.revertToState(snapshotId);

    // 2x2x1 expansion (4 fragments)
    startGasReport("Expand forcefield 2x2x1 = 4");
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(2, 1, 0)
    );
    endGasReport();

    vm.revertToState(snapshotId);

    // 2x2x2 expansion (8 fragments)
    startGasReport("Expand forcefield 2x2x2 = 8");
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(2, 1, 1)
    );
    endGasReport();

    vm.revertToState(snapshotId);

    // 3x3x1 expansion (9 fragments)
    startGasReport("Expand forcefield 3x3x1 = 9");
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(3, 2, 0)
    );
    endGasReport();

    vm.revertToState(snapshotId);

    // 3x3x3 expansion (27 fragments)
    startGasReport("Expand forcefield 3x3x3 = 27");
    world.expandForceField(
      forceFieldEntityId,
      refFragmentCoord,
      refFragmentCoord + vec3(1, 0, 0),
      refFragmentCoord + vec3(3, 2, 2)
    );
    endGasReport();

    vm.stopPrank();
  }

  function testValidateSpanningTree() public {
    // Test case 1: Empty array (trivial case)
    {
      Vec3[] memory fragments = new Vec3[](0);
      uint256[] memory parents = new uint256[](0);
      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Empty array should not be valid");
    }

    // Test case 2: Single node (trivial case)
    {
      Vec3[] memory fragments = new Vec3[](1);
      fragments[0] = vec3(0, 0, 0);
      uint256[] memory parents = new uint256[](1);
      parents[0] = 0; // Self-referential
      assertTrue(world.validateSpanningTree(fragments, fragments.length, parents), "Single node should be valid");
    }

    // Test case 3: Simple line of 3 nodes
    {
      Vec3[] memory fragments = new Vec3[](3);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(2, 0, 0); // Adjacent to fragments[1]

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0; // Root
      parents[1] = 0; // Parent is fragments[0]
      parents[2] = 1; // Parent is fragments[1]

      assertTrue(world.validateSpanningTree(fragments, fragments.length, parents), "Line of 3 nodes should be valid");
    }

    // Test case 4: Star pattern (all nodes connected to root)
    {
      Vec3[] memory fragments = new Vec3[](5);
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

      assertTrue(world.validateSpanningTree(fragments, fragments.length, parents), "Star pattern should be valid");
    }

    // Test case 5: Invalid - parents array length mismatch
    {
      Vec3[] memory fragments = new Vec3[](3);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);

      uint256[] memory parents = new uint256[](2); // Missing one parent
      parents[0] = 0;
      parents[1] = 0;

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Invalid parents length");
    }

    // Test case 6: Invalid - non-adjacent nodes
    {
      Vec3[] memory fragments = new Vec3[](3);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(3, 0, 0); // NOT adjacent to fragments[1] (distance = 2)

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 1; // Claims fragments[1] is parent, but they're not adjacent

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Non-adjacent fragments");
    }

    // Test case 7: Invalid - disconnected graph
    {
      Vec3[] memory fragments = new Vec3[](4);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(5, 0, 0); // Disconnected from others
      fragments[3] = vec3(6, 0, 0); // Adjacent to fragments[2] but not to fragments[0] or fragments[1]

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 2; // Self-referential, creating a second "root"
      parents[3] = 2;

      assertFalse(
        world.validateSpanningTree(fragments, fragments.length, parents),
        "Disconnected graph should be invalid"
      );
    }

    // Test case 8: Invalid - cycle in the graph
    {
      Vec3[] memory fragments = new Vec3[](3);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0); // Adjacent to fragments[0]
      fragments[2] = vec3(1, 1, 0); // Adjacent to fragments[1]

      uint256[] memory parents = new uint256[](3);
      parents[0] = 2; // Creates a cycle: 0->2->1->0
      parents[1] = 0;
      parents[2] = 1;

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Root must be self-referential");
    }

    // Test case 9: Valid - complex tree with branches
    {
      Vec3[] memory fragments = new Vec3[](7);
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

      assertTrue(world.validateSpanningTree(fragments, fragments.length, parents), "Complex tree should be valid");
    }

    // Test case 10: Invalid - diagonal neighbors (not in Von Neumann neighborhood)
    {
      Vec3[] memory fragments = new Vec3[](2);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 1, 0); // Diagonal to fragments[0], not in Von Neumann neighborhood

      uint256[] memory parents = new uint256[](2);
      parents[0] = 0;
      parents[1] = 0;

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Non-adjacent fragments");
    }

    // Test case 11: Invalid - parent index out of bounds
    {
      Vec3[] memory fragments = new Vec3[](3);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);

      uint256[] memory parents = new uint256[](3);
      parents[0] = 0;
      parents[1] = 0;
      parents[2] = 999; // Parent index out of bounds

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Parent index out of bounds");
    }

    // Test case 12: Invalid - cycle in the middle of the array
    {
      Vec3[] memory fragments = new Vec3[](5);
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

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Cycle in the middle of the array");
    }

    // Test case 13: Invalid - multiple nodes pointing to non-existent parent
    {
      Vec3[] memory fragments = new Vec3[](5);
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

      assertFalse(
        world.validateSpanningTree(fragments, fragments.length, parents),
        "Multiple nodes pointing to non-existent parent"
      );
    }

    // Test case 14: Invalid - node is its own parent (except root)
    {
      Vec3[] memory fragments = new Vec3[](4);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0; // Valid root
      parents[1] = 0; // Valid
      parents[2] = 2; // Node is its own parent
      parents[3] = 2; // Valid

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Node cannot be its own parent");
    }

    // Test case 15: Invalid - complex cycle in a larger graph
    {
      Vec3[] memory fragments = new Vec3[](8);
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

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Complex cycle in larger graph");
    }

    // Test case 16: Invalid - root not at index 0
    {
      Vec3[] memory fragments = new Vec3[](4);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(2, 0, 0);
      fragments[3] = vec3(3, 0, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 1; // Not self-referential
      parents[1] = 1; // This is the root
      parents[2] = 1;
      parents[3] = 2;

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Root must be at index 0");
    }

    // Test case 17: Invalid - parent references later index (creating forward reference)
    {
      Vec3[] memory fragments = new Vec3[](4);
      fragments[0] = vec3(0, 0, 0);
      fragments[1] = vec3(1, 0, 0);
      fragments[2] = vec3(1, 1, 0);
      fragments[3] = vec3(0, 1, 0);

      uint256[] memory parents = new uint256[](4);
      parents[0] = 0; // Valid root
      parents[1] = 3; // Forward reference to node 3
      parents[2] = 1;
      parents[3] = 0;

      assertFalse(
        world.validateSpanningTree(fragments, fragments.length, parents),
        "Forward reference creates invalid tree"
      );
    }

    // Test case 18: Valid - zigzag pattern
    {
      Vec3[] memory fragments = new Vec3[](5);
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

      assertTrue(world.validateSpanningTree(fragments, fragments.length, parents), "Zigzag pattern should be valid");
    }

    // Test case 19: Invalid - multiple roots
    {
      Vec3[] memory fragments = new Vec3[](6);
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

      assertFalse(world.validateSpanningTree(fragments, fragments.length, parents), "Multiple roots should be invalid");
    }

    // Test case 20: Invalid - complex disconnected components
    {
      Vec3[] memory fragments = new Vec3[](10);
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
        world.validateSpanningTree(fragments, fragments.length, parents),
        "Complex disconnected components should be invalid"
      );
    }
  }
}
