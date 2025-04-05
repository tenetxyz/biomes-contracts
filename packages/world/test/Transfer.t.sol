// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";

import { EntityId } from "../src/EntityId.sol";

import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { EnergyData } from "../src/codegen/tables/Energy.sol";

import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { InventorySlot } from "../src/codegen/tables/InventorySlot.sol";
import { InventoryTypeSlots } from "../src/codegen/tables/InventoryTypeSlots.sol";

import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";

import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";
import { MovablePosition } from "../src/codegen/tables/MovablePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Player } from "../src/codegen/tables/Player.sol";

import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { ReverseMovablePosition } from "../src/codegen/tables/ReverseMovablePosition.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { DustTest } from "./DustTest.sol";

import { CHUNK_SIZE, MAX_ENTITY_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { ProgramId } from "../src/ProgramId.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { SlotAmount } from "../src/utils/InventoryUtils.sol";
import { Position } from "../src/utils/Vec3Storage.sol";

import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract TestChestProgram is System {
  // Control revert behavior
  bool revertOnTransfer;

  function onTransfer(EntityId, EntityId, EntityId, EntityId, ObjectAmount[] memory, EntityId[] memory, bytes memory)
    external
    view
  {
    require(!revertOnTransfer, "Transfer not allowed by chest");
  }

  function setRevertOnTransfer(bool _revertOnTransfer) external {
    revertOnTransfer = _revertOnTransfer;
  }

  // Function to test calling the world from an entity
  function call(IWorld world, bytes memory data) external {
    (bool success, bytes memory returnData) = address(world).call(data);
    if (!success) {
      revertWithBytes(returnData);
    }
  }

  fallback() external { }
}

contract TransferTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function attachTestProgram(EntityId entityId, System program, bytes14 namespace) internal {
    ResourceId namespaceId = WorldResourceIdLib.encodeNamespace(namespace);
    ResourceId programSystemId = WorldResourceIdLib.encode(RESOURCE_SYSTEM, namespace, "programName");
    world.registerNamespace(namespaceId);
    world.registerSystem(programSystemId, program, false);
    world.transferOwnership(namespaceId, address(0));

    Vec3 coord = Position.get(entityId);

    // Attach program with test player
    (address bob, EntityId bobEntityId) = createTestPlayer(coord - vec3(1, 0, 0));
    vm.prank(bob);
    world.attachProgram(bobEntityId, entityId, ProgramId.wrap(programSystemId.unwrap()), "");
  }

  function testTransferToChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: numToTransfer });

    vm.prank(alice);
    startGasReport("transfer to chest");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(Inventory.length(chestEntityId), 1, "Inventory slots is not 0");
  }

  function testTransferToolToChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addEntity(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.prank(alice);
    startGasReport("transfer tool to chest");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
    endGasReport();

    assertInventoryHasTool(chestEntityId, toolEntityId, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertEq(Inventory.length(chestEntityId), 1, "Inventory slots is not 0");
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
  }

  function testTransferFromChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Dirt;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: numToTransfer });

    vm.prank(alice);
    startGasReport("transfer from chest");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);
    assertEq(Inventory.length(aliceEntityId), 1, "Inventory not set");
    assertEq(Inventory.length(chestEntityId), 0, "Inventory slots is not 0");
  }

  function testTransferToolFromChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId1 = TestInventoryUtils.addEntity(chestEntityId, transferObjectTypeId);
    EntityId toolEntityId2 = TestInventoryUtils.addEntity(chestEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 2);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](2);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });
    slotsToTransfer[1] = SlotAmount({ slot: 1, amount: 1 });

    vm.prank(alice);
    startGasReport("transfer tools from chest");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId1, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 1);
    assertInventoryHasTool(chestEntityId, toolEntityId1, 0);
    assertInventoryHasTool(chestEntityId, toolEntityId2, 0);
    assertEq(Inventory.length(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(Inventory.length(chestEntityId), 0, "Inventory slots is not 0");
  }

  function testTransferToChestFailsIfChestFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    uint16 maxChestInventorySlots = ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(
      chestEntityId,
      transferObjectTypeId,
      ObjectTypeMetadata.getStackable(transferObjectTypeId) * maxChestInventorySlots
    );
    assertEq(Inventory.length(chestEntityId), maxChestInventorySlots, "Inventory slots is not max");

    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("All slots used");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
  }

  function testTransferFromChestFailsIfPlayerFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    uint16 maxPlayerInventorySlots = ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(
      aliceEntityId,
      transferObjectTypeId,
      ObjectTypeMetadata.getStackable(transferObjectTypeId) * maxPlayerInventorySlots
    );
    assertEq(Inventory.length(aliceEntityId), maxPlayerInventorySlots, "Inventory slots is not max");

    TestInventoryUtils.addObject(chestEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("All slots used");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfInvalidObject() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId nonChestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Dirt);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(nonChestEntityId, transferObjectTypeId, 0);

    assertEq(ObjectTypeMetadata.getMaxInventorySlots(transferObjectTypeId), 0, "Max inventory slots is not 0");

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("All slots used");
    world.transfer(aliceEntityId, aliceEntityId, nonChestEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 2 });

    vm.prank(alice);
    vm.expectRevert("Not enough objects in slot");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");

    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    // Transfer grass from alice to chest
    vm.prank(alice);
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 2 });

    vm.prank(alice);
    vm.expectRevert("Not enough objects in slot");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");

    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    // Transfer grass from chest to alice
    vm.prank(alice);
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    transferObjectTypeId = ObjectTypes.WoodenPick;
    TestInventoryUtils.addEntity(chestEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    slotsToTransfer[0] = SlotAmount({ slot: 1, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Not enough objects in slot");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");

    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    // Transfer tool from chest to alice
    vm.prank(alice);
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in slot");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);

    TestInventoryUtils.addEntity(aliceEntityId, ObjectTypes.WoodenPick);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 0 });

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");

    slotsToTransfer[0] = SlotAmount({ slot: 1, amount: 0 });

    vm.prank(alice);
    vm.expectRevert("Invalid amount for entity slot");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.expectRevert("Caller not allowed");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
  }

  function testTransferFailsIfProgramReverts() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    setupForceField(chestCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }));

    TestChestProgram program = new TestChestProgram();
    attachTestProgram(chestEntityId, program, "namespace");
    program.setRevertOnTransfer(true);

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: numToTransfer });

    vm.prank(alice);
    vm.expectRevert("Transfer not allowed by chest");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, slotsToTransfer, "");
  }

  function testTransferBetweenChests() public {
    Vec3 chestCoord = vec3(0, 0, 0);

    setupAirChunk(chestCoord);

    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    EntityId otherChestEntityId = setObjectAtCoord(chestCoord + vec3(1, 0, 0), ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(otherChestEntityId, transferObjectTypeId, 0);

    setupForceField(
      chestCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000 * 10 ** 14, drainRate: 1 })
    );

    TestChestProgram program = new TestChestProgram();
    attachTestProgram(chestEntityId, program, "namespace");

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: numToTransfer });

    program.call(
      world, abi.encodeCall(world.transfer, (chestEntityId, chestEntityId, otherChestEntityId, slotsToTransfer, ""))
    );

    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(otherChestEntityId, transferObjectTypeId, numToTransfer);
  }

  function testTransferBetweenChestsFailIfTooFar() public {
    Vec3 chestCoord = vec3(0, 0, 0);
    Vec3 otherChestCoord = chestCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, 0);

    setupAirChunk(chestCoord);

    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    EntityId otherChestEntityId = setObjectAtCoord(otherChestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(otherChestEntityId, transferObjectTypeId, 0);

    setupForceField(chestCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }));

    TestChestProgram program = new TestChestProgram();
    attachTestProgram(chestEntityId, program, "namespace");

    SlotAmount[] memory slotsToTransfer = new SlotAmount[](1);
    slotsToTransfer[0] = SlotAmount({ slot: 0, amount: numToTransfer });

    vm.expectRevert("Entity is too far");
    program.call(
      world, abi.encodeCall(world.transfer, (chestEntityId, chestEntityId, otherChestEntityId, slotsToTransfer, ""))
    );
  }
}
