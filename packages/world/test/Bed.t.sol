// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

import { BiomesTest, console } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { ExploredChunk } from "../src/codegen/tables/ExploredChunk.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex } from "../src/codegen/tables/ExploredChunkByIndex.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";

import { IBedChip } from "../src/prototypes/IBedChip.sol";
import { ChunkCoord } from "../src/Types.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, DirtObjectID, BedObjectID, ChipObjectID } from "../src/ObjectTypeIds.sol";
import { VoxelCoord } from "../src/VoxelCoord.sol";
import { CHUNK_SIZE, MAX_PLAYER_ENERGY, MACHINE_ENERGY_DRAIN_RATE } from "../src/Constants.sol";
import { TestUtils } from "./utils/TestUtils.sol";

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
  function testSleep() public {
    (address alice, , VoxelCoord memory coord) = setupAirChunkWithPlayer();

    VoxelCoord memory bedCoord = VoxelCoord(coord.x - 2, coord.y, coord.z);

    // Set forcefield
    EntityId forceFieldEntityId = setupForceField(bedCoord);
    Energy.set(
      forceFieldEntityId,
      EnergyData({
        energy: 1000,
        lastUpdatedTime: uint128(block.timestamp),
        drainRate: MACHINE_ENERGY_DRAIN_RATE,
        accDepletedTime: 0
      })
    );

    // Set entity to bed
    EntityId bedEntityId = randomEntityId();
    Position.set(bedEntityId, bedCoord.x, bedCoord.y, bedCoord.z);
    ReversePosition.set(bedCoord.x, bedCoord.y, bedCoord.z, bedEntityId);
    ObjectType.set(bedEntityId, BedObjectID);

    TestBedChip chip = new TestBedChip();
    bytes14 namespace = "chipNamespace";
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId chipSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "chipName");
    world.registerNamespace(namespaceId);
    world.registerSystem(chipSystemId, chip, false);
    world.transferOwnership(namespaceId, address(0));

    // Attach chip with test player
    (address bob, EntityId bobEntityId) = createTestPlayer(VoxelCoord(bedCoord.x - 1, bedCoord.y, bedCoord.z));
    TestUtils.addToInventoryCount(bobEntityId, PlayerObjectID, ChipObjectID, 1);
    vm.prank(bob);
    world.attachChip(bedEntityId, chipSystemId);

    vm.prank(alice);
    world.sleep(bedEntityId, "");
    // assertTrue(playerEntityId.exists());
  }

  function testSleepFailsIfNoBed() public {
    (address alice, , ) = setupAirChunkWithPlayer();

    // Use a random entity for (non) bed
    EntityId bedEntityId = randomEntityId();

    vm.prank(alice);
    vm.expectRevert("Not a bed");
    world.sleep(bedEntityId, "");
  }

  function testSleepFailsIfNotInPlayerInfluence() public {
    (address alice, , VoxelCoord memory coord) = setupAirChunkWithPlayer();

    VoxelCoord memory bedCoord = VoxelCoord(coord.x - 500, coord.y, coord.z);

    // Set forcefield
    setupForceField(bedCoord);

    // Set entity to bed
    EntityId bedEntityId = randomEntityId();
    Position.set(bedEntityId, bedCoord.x, bedCoord.y, bedCoord.z);
    ReversePosition.set(bedCoord.x, bedCoord.y, bedCoord.z, bedEntityId);
    ObjectType.set(bedEntityId, BedObjectID);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.sleep(bedEntityId, "");
  }

  function testSleepFailsIfNoForceField() public {
    (address alice, , VoxelCoord memory coord) = setupAirChunkWithPlayer();

    VoxelCoord memory bedCoord = VoxelCoord(coord.x - 2, coord.y, coord.z);

    // Set entity to bed
    EntityId bedEntityId = randomEntityId();
    Position.set(bedEntityId, bedCoord.x, bedCoord.y, bedCoord.z);
    ReversePosition.set(bedCoord.x, bedCoord.y, bedCoord.z, bedEntityId);
    ObjectType.set(bedEntityId, BedObjectID);

    vm.prank(alice);
    vm.expectRevert("Bed is not inside a forcefield");
    world.sleep(bedEntityId, "");
  }

  function testSleepFailsIfNotEnoughForceFieldEnergy() public {
    // TODO: should we implement this check?
  }

  function testWakeup() public {}
}
