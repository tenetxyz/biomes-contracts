// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { console } from "forge-std/console.sol";

import { Direction } from "../src/codegen/common.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";

import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";

import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";

import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { MovablePosition, Position, ReverseMovablePosition, ReversePosition } from "../src/utils/Vec3Storage.sol";

import { CHUNK_SIZE, MAX_ENTITY_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { EntityId } from "../src/EntityId.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";

import { Vec3, vec3 } from "../src/Vec3.sol";
import { DustTest } from "./DustTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract DropTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testDropTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord.getNeighbor(Direction.PositiveY);
    setTerrainAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertFalse(airEntityId.exists(), "Drop entity already exists");

    vm.prank(alice);
    startGasReport("drop terrain");
    world.drop(aliceEntityId, transferObjectTypeId, numToTransfer, dropCoord);
    endGasReport();

    airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToTransfer);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
  }

  function testDropNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity doesn't exist");

    vm.prank(alice);
    startGasReport("drop non-terrain");
    world.drop(aliceEntityId, transferObjectTypeId, numToTransfer, dropCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToTransfer);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
  }

  function testDropToolTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setTerrainAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertFalse(airEntityId.exists(), "Drop entity already exists");

    vm.prank(alice);
    startGasReport("drop tool terrain");
    world.dropTool(aliceEntityId, toolEntityId, dropCoord);
    endGasReport();

    airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertEq(InventoryEntity.get(toolEntityId), airEntityId, "Inventory entity is not air");
  }

  function testDropToolNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity already exists");

    vm.prank(alice);
    startGasReport("drop tool non-terrain");
    world.dropTool(aliceEntityId, toolEntityId, dropCoord);
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertEq(InventoryEntity.get(toolEntityId), airEntityId, "Inventory entity is not air");
  }

  function testDropNonAirButPassable() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.FescueGrass);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity doesn't exist");

    vm.prank(alice);
    world.drop(aliceEntityId, transferObjectTypeId, numToTransfer, dropCoord);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToTransfer);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
  }

  function testPickup() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    startGasReport("pickup");
    world.pickup(aliceEntityId, transferObjectTypeId, numToPickup, pickupCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 0);
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupTool() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(airEntityId, transferObjectTypeId);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    startGasReport("pickup tool");
    world.pickupTool(aliceEntityId, toolEntityId, pickupCoord);
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
    assertInventoryHasTool(airEntityId, toolEntityId, 0);
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupMultiple() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId objectObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    TestInventoryUtils.addToInventory(airEntityId, objectObjectTypeId, numToPickup);
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(airEntityId, toolObjectTypeId);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertInventoryHasObject(aliceEntityId, toolObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, objectObjectTypeId, numToPickup);

    vm.prank(alice);
    startGasReport("pickup multiple");
    ObjectAmount[] memory pickupObjects = new ObjectAmount[](1);
    pickupObjects[0] = ObjectAmount({ objectTypeId: objectObjectTypeId, amount: numToPickup });
    EntityId[] memory pickupTools = new EntityId[](1);
    pickupTools[0] = toolEntityId;
    world.pickupMultiple(aliceEntityId, pickupObjects, pickupTools, pickupCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, objectObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, objectObjectTypeId, 0);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
    assertEq(InventorySlots.get(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupAll() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId objectObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    ObjectTypeId toolObjectTypeId1 = ObjectTypes.WoodenPick;
    TestInventoryUtils.addToInventory(airEntityId, objectObjectTypeId, numToPickup);
    EntityId toolEntityId1 = TestInventoryUtils.addToolToInventory(airEntityId, toolObjectTypeId1);
    ObjectTypeId toolObjectTypeId2 = ObjectTypes.WoodenAxe;
    EntityId toolEntityId2 = TestInventoryUtils.addToolToInventory(airEntityId, toolObjectTypeId2);
    assertInventoryHasTool(airEntityId, toolEntityId1, 1);
    assertInventoryHasTool(airEntityId, toolEntityId2, 1);
    assertInventoryHasObject(airEntityId, objectObjectTypeId, numToPickup);

    vm.prank(alice);
    startGasReport("pickup all");
    world.pickupAll(aliceEntityId, pickupCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, objectObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, objectObjectTypeId, 0);
    assertInventoryHasTool(aliceEntityId, toolEntityId1, 1);
    assertInventoryHasTool(airEntityId, toolEntityId1, 0);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 1);
    assertInventoryHasTool(airEntityId, toolEntityId2, 0);
    assertEq(InventorySlots.get(aliceEntityId), 3, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupMinedChestDrops() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    ObjectTypeMetadata.setMass(ObjectTypes.Chest, playerHandMassReduction - 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    TestInventoryUtils.addToInventory(chestEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    world.mine(aliceEntityId, chestCoord, "");

    EntityId airEntityId = ReversePosition.get(chestCoord);
    assertEq(airEntityId.exists(), true, "Drop entity does not exist");
    assertEq(ObjectType.get(airEntityId), ObjectTypes.Air, "Drop entity is not air");
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToPickup);

    vm.prank(alice);
    world.pickupAll(aliceEntityId, chestCoord);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 0);
    assertEq(InventorySlots.get(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupFromNonAirButPassable() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.FescueGrass);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    world.pickup(aliceEntityId, transferObjectTypeId, numToPickup, pickupCoord);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 0);
    assertEq(InventorySlots.get(aliceEntityId), 1, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupFailsIfInventoryFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    TestInventoryUtils.addToInventory(
      aliceEntityId,
      transferObjectTypeId,
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player)
        * ObjectTypeMetadata.getStackable(transferObjectTypeId)
    );
    assertEq(
      InventorySlots.get(aliceEntityId),
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player),
      "Inventory slots is not max"
    );

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.pickup(aliceEntityId, transferObjectTypeId, 1, pickupCoord);
  }

  function testDropFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 0, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);

    EntityId toolEntityId = randomEntityId();

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.drop(aliceEntityId, ObjectTypes.Grass, 1, dropCoord);

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.dropTool(aliceEntityId, toolEntityId, dropCoord);
  }

  function testPickupFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 0, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);

    EntityId toolEntityId = randomEntityId();

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.pickup(aliceEntityId, ObjectTypes.Grass, 1, dropCoord);

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.pickupTool(aliceEntityId, toolEntityId, dropCoord);
  }

  function testPickupFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.pickup(aliceEntityId, transferObjectTypeId, 1, pickupCoord);
  }

  function testDropFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.drop(aliceEntityId, transferObjectTypeId, 1, dropCoord);

    dropCoord = playerCoord - vec3(CHUNK_SIZE / 2 + 1, 1, 0);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.drop(aliceEntityId, transferObjectTypeId, 1, dropCoord);
  }

  function testDropFailsIfNonAirBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Dirt);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot drop on a non-passable block");
    world.drop(aliceEntityId, transferObjectTypeId, 1, dropCoord);
  }

  function testPickupFailsIfNonAirBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    setTerrainAtCoord(pickupCoord, ObjectTypes.Air);
    EntityId airEntityId = ReversePosition.get(pickupCoord);
    assertFalse(airEntityId.exists(), "Drop entity doesn't exists");

    vm.prank(alice);
    vm.expectRevert("No entity at pickup location");
    world.pickup(aliceEntityId, ObjectTypes.Grass, 1, pickupCoord);

    EntityId chestEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Chest);
    TestInventoryUtils.addToInventory(chestEntityId, ObjectTypes.Grass, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot pickup from a non-passable block");
    world.pickup(aliceEntityId, ObjectTypes.Grass, 1, pickupCoord);
  }

  function testPickupFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Object type is not a block or item");
    world.pickup(aliceEntityId, ObjectTypes.WoodenPick, 1, pickupCoord);

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.pickup(aliceEntityId, transferObjectTypeId, 0, pickupCoord);
  }

  function testDropFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    EntityId toolEntityId1 = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenPick);
    EntityId toolEntityId2 = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenAxe);

    vm.prank(alice);
    vm.expectRevert("Object type is not a block or item");
    world.drop(aliceEntityId, ObjectTypes.WoodenPick, 1, dropCoord);

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.drop(aliceEntityId, transferObjectTypeId, 0, dropCoord);

    vm.prank(alice);
    vm.expectRevert("Must drop at least one tool");
    world.dropTools(aliceEntityId, new EntityId[](0), dropCoord);

    vm.prank(alice);
    EntityId[] memory toolEntityIds = new EntityId[](2);
    toolEntityIds[0] = toolEntityId1;
    toolEntityIds[1] = toolEntityId2;
    vm.expectRevert("All tools must be of the same type");
    world.dropTools(aliceEntityId, toolEntityIds, dropCoord);
  }

  function testPickupFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    vm.expectRevert("Caller not allowed");
    world.pickup(aliceEntityId, transferObjectTypeId, 1, pickupCoord);
  }

  function testDropFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    vm.expectRevert("Caller not allowed");
    world.drop(aliceEntityId, transferObjectTypeId, 1, dropCoord);
  }

  function testPickupFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.pickup(aliceEntityId, transferObjectTypeId, 1, pickupCoord);
  }

  function testDropFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addToInventory(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.drop(aliceEntityId, transferObjectTypeId, 1, dropCoord);
  }
}
