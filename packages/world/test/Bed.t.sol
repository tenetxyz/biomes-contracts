// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

import { BiomesTest, console } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";

import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { BedPlayer, BedPlayerData } from "../src/codegen/tables/BedPlayer.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";

import { ExploredChunk, ExploredChunkByIndex, LocalEnergyPool, ReversePosition, Position } from "../src/utils/Vec3Storage.sol";

import { IBedChip } from "../src/prototypes/IBedChip.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { CHUNK_SIZE, MAX_PLAYER_ENERGY, MACHINE_ENERGY_DRAIN_RATE, PLAYER_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { TestEnergyUtils } from "./utils/TestUtils.sol";

contract TestBedChip is IBedChip, System {
  function onAttached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onDetached(EntityId callerEntityId, EntityId targetEntityId, bytes memory extraData) external payable {}

  function onSleep(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable {}

  function onWakeup(EntityId callerEntityId, EntityId bedEntityId, bytes memory extraData) external payable {}

  function supportsInterface(bytes4 interfaceId) public pure override(IERC165, WorldContextConsumer) returns (bool) {
    return interfaceId == type(IBedChip).interfaceId || super.supportsInterface(interfaceId);
  }
}

contract BedTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function createBed(Vec3 bedCoord) internal returns (EntityId) {
    // Set entity to bed
    EntityId bedEntityId = randomEntityId();
    Position.set(bedEntityId, bedCoord);
    ReversePosition.set(bedCoord, bedEntityId);
    ObjectType.set(bedEntityId, ObjectTypes.Bed);
    return bedEntityId;
  }

  function attachTestChip(EntityId bedEntityId) internal {
    TestBedChip chip = new TestBedChip();
    bytes14 namespace = "chipNamespace";
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId chipSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "chipName");
    world.registerNamespace(namespaceId);
    world.registerSystem(chipSystemId, chip, false);
    world.transferOwnership(namespaceId, address(0));

    Vec3 bedCoord = Position.get(bedEntityId);

    // Attach chip with test player
    (address bob, ) = createTestPlayer(bedCoord - vec3(1, 0, 0));
    vm.prank(bob);
    world.attachChip(bedEntityId, chipSystemId);
  }

  function testSleep() public {
    (address alice, EntityId aliceEntityId, Vec3 coord) = setupAirChunkWithPlayer();

    Vec3 bedCoord = coord - vec3(2, 0, 0);

    // Set forcefield
    setupForceField(
      bedCoord,
      EnergyData({
        energy: 1000,
        lastUpdatedTime: uint128(vm.getBlockTimestamp()),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    EntityId bedEntityId = createBed(bedCoord);

    attachTestChip(bedEntityId);

    vm.prank(alice);
    world.sleep(bedEntityId);

    // Checks
    BedPlayerData memory bedPlayerData = BedPlayer.get(bedEntityId);
    assertEq(bedPlayerData.playerEntityId.unwrap(), aliceEntityId.unwrap(), "Bed's player entity is not alice");
    assertEq(bedPlayerData.lastAccDepletedTime, 0, "Wrong lastAccDepletedTime");
    assertEq(
      PlayerStatus.getBedEntityId(aliceEntityId).unwrap(),
      bedEntityId.unwrap(),
      "Player's bed entity is not the bed"
    );
  }

  function testSleepFailsIfNoBed() public {
    (address alice, , ) = setupAirChunkWithPlayer();

    // Use a random entity for (non) bed
    EntityId bedEntityId = randomEntityId();

    vm.prank(alice);
    vm.expectRevert("Not a bed");
    world.sleep(bedEntityId);
  }

  function testSleepFailsIfNotInPlayerInfluence() public {
    (address alice, , Vec3 coord) = setupAirChunkWithPlayer();

    Vec3 bedCoord = coord + vec3(500, 0, 0);

    // Set forcefield
    setupForceField(bedCoord);

    // Set entity to bed
    EntityId bedEntityId = createBed(bedCoord);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.sleep(bedEntityId);
  }

  function testSleepFailsIfNoForceField() public {
    (address alice, , Vec3 coord) = setupAirChunkWithPlayer();

    Vec3 bedCoord = coord - vec3(2, 0, 0);

    // Set entity to bed
    EntityId bedEntityId = createBed(bedCoord);

    vm.prank(alice);
    vm.expectRevert("Bed is not inside a forcefield");
    world.sleep(bedEntityId);
  }

  function testSleepFailsIfNotEnoughForceFieldEnergy() public {
    // TODO: should we implement this check?
  }

  function testWakeup() public {
    (address alice, EntityId aliceEntityId, Vec3 coord) = setupFlatChunkWithPlayer();

    Vec3 bedCoord = coord - vec3(2, 0, 0);

    uint128 initialPlayerEnergy = Energy.getEnergy(aliceEntityId);

    uint128 initialForcefieldEnergy = 1_000_000;
    // Set forcefield
    EntityId forcefieldEntityId = setupForceField(
      bedCoord,
      EnergyData({
        energy: initialForcefieldEnergy,
        lastUpdatedTime: uint128(vm.getBlockTimestamp()),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    EntityId bedEntityId = createBed(bedCoord);

    attachTestChip(bedEntityId);

    vm.prank(alice);
    world.sleep(bedEntityId);

    uint128 timeDelta = 1000 seconds;
    vm.warp(vm.getBlockTimestamp() + timeDelta);

    // Wakeup in the original coord
    vm.prank(alice);
    world.wakeup(coord);

    EnergyData memory ffEnergyData = Energy.get(forcefieldEntityId);
    assertEq(
      ffEnergyData.energy,
      initialForcefieldEnergy - timeDelta * (MACHINE_ENERGY_DRAIN_RATE + PLAYER_ENERGY_DRAIN_RATE),
      "Forcefield energy wasn't drained correctly"
    );

    assertEq(ffEnergyData.drainRate, MACHINE_ENERGY_DRAIN_RATE, "Forcefield drain rate was not restored");

    assertEq(Energy.getEnergy(aliceEntityId), initialPlayerEnergy, "Player energy was drained while sleeping");
  }

  function testWakeupWithDepletedForcefield() public {
    (address alice, EntityId aliceEntityId, Vec3 coord) = setupFlatChunkWithPlayer();

    Vec3 bedCoord = coord - vec3(2, 0, 0);

    uint128 initialPlayerEnergy = Energy.getEnergy(aliceEntityId);

    // Set the forcefield's energy to fully deplete after 1000 seconds (with 1 sleeping player)
    uint128 initialForcefieldEnergy = (MACHINE_ENERGY_DRAIN_RATE + PLAYER_ENERGY_DRAIN_RATE) * 1000;

    // Set forcefield
    EntityId forcefieldEntityId = setupForceField(
      bedCoord,
      EnergyData({
        energy: initialForcefieldEnergy,
        lastUpdatedTime: uint128(vm.getBlockTimestamp()),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    EntityId bedEntityId = createBed(bedCoord);

    attachTestChip(bedEntityId);

    vm.prank(alice);
    world.sleep(bedEntityId);

    // After 1000 seconds, the forcefield should be depleted
    // We wait for 500 more seconds so the player's energy is also depleted in this period
    uint128 timeDelta = 1000 seconds + 500 seconds;
    vm.warp(vm.getBlockTimestamp() + timeDelta);

    // Wakeup in the original coord
    vm.prank(alice);
    world.wakeup(coord);

    EnergyData memory ffEnergyData = Energy.get(forcefieldEntityId);
    assertEq(ffEnergyData.energy, 0, "Forcefield energy wasn't drained correctly");
    assertEq(ffEnergyData.drainRate, MACHINE_ENERGY_DRAIN_RATE, "Forcefield drain rate was not restored");
    // The forcefield had 0 energy for 500 seconds
    assertEq(ffEnergyData.accDepletedTime, 500, "Forcefield accDepletedTime was not computed correctly");

    // Check that the player energy was drained during the 1000 seconds that the forcefield was off
    assertEq(
      Energy.getEnergy(aliceEntityId),
      initialPlayerEnergy - PLAYER_ENERGY_DRAIN_RATE * 500 seconds,
      "Player energy was not drained"
    );
  }

  function testWakeupWithDepletedAndRechargedForcefield() public {
    (address alice, EntityId aliceEntityId, Vec3 coord) = setupFlatChunkWithPlayer();

    Vec3 bedCoord = coord - vec3(2, 0, 0);

    uint128 initialPlayerEnergy = Energy.getEnergy(aliceEntityId);

    // Set the forcefield's energy to fully deplete after 1000 seconds (with 1 sleeping player)
    uint128 initialForcefieldEnergy = (MACHINE_ENERGY_DRAIN_RATE + PLAYER_ENERGY_DRAIN_RATE) * 1000;

    // Set forcefield
    EntityId forcefieldEntityId = setupForceField(
      bedCoord,
      EnergyData({
        energy: initialForcefieldEnergy,
        lastUpdatedTime: uint128(vm.getBlockTimestamp()),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    EntityId bedEntityId = createBed(bedCoord);

    attachTestChip(bedEntityId);

    vm.prank(alice);
    world.sleep(bedEntityId);

    // After 1000 seconds, the forcefield should be depleted
    // We wait for 500 more seconds so the player's energy is also depleted in this period
    vm.warp(vm.getBlockTimestamp() + 1000 seconds + 500 seconds);

    // Then we charge it again with the initial charge
    TestEnergyUtils.updateEnergyLevel(forcefieldEntityId);
    Energy.setEnergy(forcefieldEntityId, initialForcefieldEnergy);

    // Then we wait for another 1000 seconds so the forcefield is fully depleted again
    vm.warp(vm.getBlockTimestamp() + 1000 seconds);

    // Wakeup in the original coord
    vm.prank(alice);
    world.wakeup(coord);

    EnergyData memory ffEnergyData = Energy.get(forcefieldEntityId);
    assertEq(ffEnergyData.energy, 0, "Forcefield energy wasn't drained correctly");
    assertEq(ffEnergyData.drainRate, MACHINE_ENERGY_DRAIN_RATE, "Forcefield drain rate was not restored");
    // The forcefield had 0 energy for 500 seconds
    assertEq(ffEnergyData.accDepletedTime, 500, "Forcefield accDepletedTime was not computed correctly");

    // Check that the player energy was drained during the 1000 seconds that the forcefield was off,
    // but not after recharging
    assertEq(
      Energy.getEnergy(aliceEntityId),
      initialPlayerEnergy - PLAYER_ENERGY_DRAIN_RATE * 500 seconds,
      "Player energy was not drained"
    );
  }

  function testWakeupFailsIfPlayerDied() public {
    (address alice, EntityId aliceEntityId, Vec3 coord) = setupFlatChunkWithPlayer();

    Vec3 bedCoord = coord - vec3(2, 0, 0);

    uint128 initialPlayerEnergy = Energy.getEnergy(aliceEntityId);

    // Set the forcefield's energy to fully deplete after 1000 seconds (with 1 sleeping player)
    uint128 initialForcefieldEnergy = (MACHINE_ENERGY_DRAIN_RATE + PLAYER_ENERGY_DRAIN_RATE) * 1000;

    // Set forcefield
    EntityId forcefieldEntityId = setupForceField(
      bedCoord,
      EnergyData({
        energy: initialForcefieldEnergy,
        lastUpdatedTime: uint128(vm.getBlockTimestamp()),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    EntityId bedEntityId = createBed(bedCoord);

    attachTestChip(bedEntityId);

    vm.prank(alice);
    world.sleep(bedEntityId);

    // After 1000 seconds, the forcefield should be depleted
    // We wait for the player to also get fully depleted
    uint128 playerDrainTime = initialPlayerEnergy * PLAYER_ENERGY_DRAIN_RATE;
    vm.warp(vm.getBlockTimestamp() + 1000 seconds + playerDrainTime);

    // Wakeup in the original coord
    vm.prank(alice);
    vm.expectRevert("Player died while sleeping");
    world.wakeup(coord);

    TestEnergyUtils.updateEnergyLevel(forcefieldEntityId);

    EnergyData memory ffEnergyData = Energy.get(forcefieldEntityId);
    assertEq(ffEnergyData.energy, 0, "Forcefield energy wasn't drained correctly");
    assertEq(
      ffEnergyData.drainRate,
      MACHINE_ENERGY_DRAIN_RATE + PLAYER_ENERGY_DRAIN_RATE,
      "Forcefield drain rate does not include player"
    );
    // The forcefield had 0 energy for 500 seconds
    assertEq(ffEnergyData.accDepletedTime, playerDrainTime, "Forcefield accDepletedTime was not computed correctly");
  }

  function testRemoveDeadPlayerFromBed() public {
    (address alice, EntityId aliceEntityId, Vec3 coord) = setupFlatChunkWithPlayer();

    Vec3 bedCoord = coord + vec3(2, 0, 0);

    uint128 initialPlayerEnergy = Energy.getEnergy(aliceEntityId);

    // Set the forcefield's energy to fully deplete after 1000 seconds (with 1 sleeping player)
    uint128 initialForcefieldEnergy = (MACHINE_ENERGY_DRAIN_RATE + PLAYER_ENERGY_DRAIN_RATE) * 1000;

    // Set forcefield
    EntityId forcefieldEntityId = setupForceField(
      bedCoord,
      EnergyData({
        energy: initialForcefieldEnergy,
        lastUpdatedTime: uint128(vm.getBlockTimestamp()),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    EntityId bedEntityId = createBed(bedCoord);

    attachTestChip(bedEntityId);

    vm.prank(alice);
    world.sleep(bedEntityId);

    // After 1000 seconds, the forcefield should be depleted
    // We wait more time so the player's energy is FULLY depleted in this period
    uint128 playerDrainTime = initialPlayerEnergy / PLAYER_ENERGY_DRAIN_RATE;
    uint128 timeDelta = 1000 seconds + playerDrainTime;
    vm.warp(vm.getBlockTimestamp() + timeDelta);

    // Remove alice and drop inventory in the original coord
    world.removeDeadPlayerFromBed(aliceEntityId, coord);

    EnergyData memory ffEnergyData = Energy.get(forcefieldEntityId);
    assertEq(ffEnergyData.energy, 0, "Forcefield energy wasn't drained correctly");
    assertEq(ffEnergyData.drainRate, MACHINE_ENERGY_DRAIN_RATE, "Forcefield drain rate was not restored");
    // The forcefield had 0 energy for playerDrainTime seconds
    assertEq(ffEnergyData.accDepletedTime, playerDrainTime, "Forcefield accDepletedTime was not computed correctly");

    // Check that the player energy was drained during the playerDrainTime seconds that the forcefield was off
    assertEq(Energy.getEnergy(aliceEntityId), 0, "Player energy was not drained");
  }
}
