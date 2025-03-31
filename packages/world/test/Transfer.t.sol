// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";

import { revertWithBytes } from "@latticexyz/world/src/revertWithBytes.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { WorldContextConsumer } from "@latticexyz/world/src/WorldContext.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { EnergyData } from "../src/codegen/tables/Energy.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { MovablePosition } from "../src/codegen/tables/MovablePosition.sol";
import { ReverseMovablePosition } from "../src/codegen/tables/ReverseMovablePosition.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { Position } from "../src/utils/Vec3Storage.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectAmount, ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { CHUNK_SIZE, MAX_ENTITY_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { ProgramId } from "../src/ProgramId.sol";

import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract TestChestProgram is System {
  // Control revert behavior
  bool revertOnTransfer;

  function onTransfer(
    EntityId,
    EntityId,
    EntityId,
    EntityId,
    ObjectAmount[] memory,
    EntityId[] memory,
    bytes memory
  ) external view {
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

  fallback() external {}
}

contract TransferTest is BiomesTest {
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
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    startGasReport("transfer to chest");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, numToTransfer, "");
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
  }

  function testTransferToolToChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    startGasReport("transfer tool to chest");
    world.transferTool(aliceEntityId, aliceEntityId, chestEntityId, toolEntityId, "");
    endGasReport();

    assertInventoryHasTool(chestEntityId, toolEntityId, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
  }

  function testTransferFromChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Chest;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    startGasReport("transfer from chest");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, transferObjectTypeId, numToTransfer, "");
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);
    assertEq(InventorySlots.get(aliceEntityId), numToTransfer, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 0, "Inventory slots is not 0");
  }

  function testTransferToolFromChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId1 = TestInventoryUtils.addToolToInventory(chestEntityId, transferObjectTypeId);
    EntityId toolEntityId2 = TestInventoryUtils.addToolToInventory(chestEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 2);

    vm.prank(alice);
    startGasReport("transfer tools from chest");
    EntityId[] memory toolEntityIds = new EntityId[](2);
    toolEntityIds[0] = toolEntityId1;
    toolEntityIds[1] = toolEntityId2;
    world.transferTools(aliceEntityId, chestEntityId, aliceEntityId, toolEntityIds, "");
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId1, 2);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 2);
    assertInventoryHasTool(chestEntityId, toolEntityId1, 0);
    assertInventoryHasTool(chestEntityId, toolEntityId2, 0);
    assertEq(InventorySlots.get(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 0, "Inventory slots is not 0");
  }

  function testTransferToChestFailsIfChestFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    uint16 maxChestInventorySlots = ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(
      chestEntityId,
      transferObjectTypeId,
      ObjectTypeMetadata.getStackable(transferObjectTypeId) * maxChestInventorySlots
    );
    assertEq(InventorySlots.get(chestEntityId), maxChestInventorySlots, "Inventory slots is not max");

    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 1, "");
  }

  function testTransferFromChestFailsIfPlayerFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    uint16 maxPlayerInventorySlots = ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(
      aliceEntityId,
      transferObjectTypeId,
      ObjectTypeMetadata.getStackable(transferObjectTypeId) * maxPlayerInventorySlots
    );
    assertEq(InventorySlots.get(aliceEntityId), maxPlayerInventorySlots, "Inventory slots is not max");

    TestInventoryUtils.addToInventory(chestEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, transferObjectTypeId, 1, "");
  }

  function testTransferFailsIfInvalidObject() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId nonChestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Dirt);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(nonChestEntityId, transferObjectTypeId, 0);

    assertEq(ObjectTypeMetadata.getMaxInventorySlots(transferObjectTypeId), 0, "Max inventory slots is not 0");

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(aliceEntityId, aliceEntityId, nonChestEntityId, transferObjectTypeId, 1, "");
  }

  function testTransferFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 2, "");

    vm.prank(alice);
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 1, "");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, transferObjectTypeId, 2, "");

    vm.prank(alice);
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, transferObjectTypeId, 1, "");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(chestEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.transferTool(aliceEntityId, aliceEntityId, chestEntityId, toolEntityId, "");

    vm.prank(alice);
    world.transferTool(aliceEntityId, chestEntityId, aliceEntityId, toolEntityId, "");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.transferTool(aliceEntityId, chestEntityId, aliceEntityId, toolEntityId, "");
  }

  function testTransferFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);

    TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenPick);
    TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenAxe);

    vm.prank(alice);
    vm.expectRevert("Object type is not a block or item");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, ObjectTypes.WoodenPick, 1, "");

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 0, "");

    vm.prank(alice);
    vm.expectRevert("Must transfer at least one tool");
    world.transferTools(aliceEntityId, aliceEntityId, chestEntityId, new EntityId[](0), "");
  }

  function testTransferFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 1, "");

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.transfer(aliceEntityId, chestEntityId, aliceEntityId, transferObjectTypeId, 1, "");
  }

  function testTransferFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.expectRevert("Caller not allowed");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 1, "");
  }

  function testTransferFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, 1, "");
  }

  function testTransferFailsIfProgramReverts() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.SmartChest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    setupForceField(chestCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }));

    TestChestProgram program = new TestChestProgram();
    attachTestProgram(chestEntityId, program, "namespace");
    program.setRevertOnTransfer(true);

    vm.prank(alice);
    vm.expectRevert("Transfer not allowed by chest");
    world.transfer(aliceEntityId, aliceEntityId, chestEntityId, transferObjectTypeId, numToTransfer, "");
  }

  function testTransferBetweenChests() public {
    Vec3 chestCoord = vec3(0, 0, 0);

    setupAirChunk(chestCoord);

    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.SmartChest);
    EntityId otherChestEntityId = setObjectAtCoord(chestCoord + vec3(1, 0, 0), ObjectTypes.SmartChest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(otherChestEntityId, transferObjectTypeId, 0);

    setupForceField(chestCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }));

    TestChestProgram program = new TestChestProgram();
    attachTestProgram(chestEntityId, program, "namespace");

    program.call(
      world,
      abi.encodeCall(
        world.transfer,
        (chestEntityId, chestEntityId, otherChestEntityId, transferObjectTypeId, numToTransfer, "")
      )
    );

    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(otherChestEntityId, transferObjectTypeId, numToTransfer);
  }

  function testTransferBetweenChestsFailIfTooFar() public {
    Vec3 chestCoord = vec3(0, 0, 0);
    Vec3 otherChestCoord = chestCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 0, 0);

    setupAirChunk(chestCoord);

    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.SmartChest);
    EntityId otherChestEntityId = setObjectAtCoord(otherChestCoord, ObjectTypes.SmartChest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(otherChestEntityId, transferObjectTypeId, 0);

    setupForceField(chestCoord, EnergyData({ lastUpdatedTime: uint128(block.timestamp), energy: 1000, drainRate: 1 }));

    TestChestProgram program = new TestChestProgram();
    attachTestProgram(chestEntityId, program, "namespace");

    vm.expectRevert("Entity is too far");
    program.call(
      world,
      abi.encodeCall(
        world.transfer,
        (chestEntityId, chestEntityId, otherChestEntityId, transferObjectTypeId, numToTransfer, "")
      )
    );
  }
}
