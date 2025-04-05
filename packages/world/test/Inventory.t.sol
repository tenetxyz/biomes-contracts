// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { console } from "forge-std/console.sol";

import { Direction } from "../src/codegen/common.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";

import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";

import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import {
  MinedOrePosition,
  MovablePosition,
  OreCommitment,
  Position,
  ReverseMovablePosition,
  ReversePosition
} from "../src/utils/Vec3Storage.sol";

import { CHUNK_SIZE, MAX_ENTITY_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { EntityId } from "../src/EntityId.sol";

import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectAmount, ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { SlotTransfer } from "../src/utils/InventoryUtils.sol";

import { Vec3, vec3 } from "../src/Vec3.sol";

import { DustTest } from "./DustTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract InventoryTest is DustTest {
  using ObjectTypeLib for ObjectTypeId;

  function testDropTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord.getNeighbor(Direction.PositiveY);
    setTerrainAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertFalse(airEntityId.exists(), "Drop entity already exists");

    vm.prank(alice);
    startGasReport("drop terrain");
    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: numToTransfer });
    world.drop(aliceEntityId, drops, dropCoord);
    endGasReport();

    airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToTransfer);
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 1, "Inventory slots is not 0");
  }

  function testDropNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity doesn't exist");

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: numToTransfer });

    vm.prank(alice);
    startGasReport("drop non-terrain");
    world.drop(aliceEntityId, drops, dropCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToTransfer);
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 1, "Inventory slots is not 0");
  }

  function testDropToolTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setTerrainAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addEntity(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertFalse(airEntityId.exists(), "Drop entity already exists");

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    startGasReport("drop tool terrain");
    world.drop(aliceEntityId, drops, dropCoord);
    endGasReport();

    airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 1, "Inventory slots is not 0");
  }

  function testDropToolNonTerrain() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addEntity(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity already exists");

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    startGasReport("drop tool non-terrain");
    world.drop(aliceEntityId, drops, dropCoord);
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 1, "Inventory slots is not 0");
  }

  function testDropNonAirButPassable() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.FescueGrass);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToTransfer = 10;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity doesn't exist");

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: numToTransfer });

    vm.prank(alice);
    world.drop(aliceEntityId, drops, dropCoord);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToTransfer);
    assertEq(Inventory.length(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 1, "Inventory slots is not 0");
  }

  function testPickup() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: numToPickup });

    vm.prank(alice);
    startGasReport("pickup");
    world.pickup(aliceEntityId, drops, pickupCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 0);
    assertEq(Inventory.length(aliceEntityId), 1, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupTool() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addEntity(airEntityId, transferObjectTypeId);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    startGasReport("pickup tool");
    world.pickup(aliceEntityId, pickup, pickupCoord);
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
    assertInventoryHasTool(airEntityId, toolEntityId, 0);
    assertEq(Inventory.length(aliceEntityId), 1, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupMultiple() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId objectObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    TestInventoryUtils.addObject(airEntityId, objectObjectTypeId, numToPickup);
    EntityId toolEntityId = TestInventoryUtils.addEntity(airEntityId, toolObjectTypeId);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertInventoryHasObject(aliceEntityId, toolObjectTypeId, 0);
    assertInventoryHasObject(airEntityId, objectObjectTypeId, numToPickup);

    SlotTransfer[] memory pickup = new SlotTransfer[](2);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: numToPickup });
    pickup[1] = SlotTransfer({ slotFrom: 1, slotTo: 1, amount: 1 });

    vm.prank(alice);
    startGasReport("pickup multiple");

    world.pickup(aliceEntityId, pickup, pickupCoord);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, objectObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, objectObjectTypeId, 0);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
    assertEq(Inventory.length(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupAll() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId objectObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    ObjectTypeId toolObjectTypeId1 = ObjectTypes.WoodenPick;
    TestInventoryUtils.addObject(airEntityId, objectObjectTypeId, numToPickup);
    EntityId toolEntityId1 = TestInventoryUtils.addEntity(airEntityId, toolObjectTypeId1);
    ObjectTypeId toolObjectTypeId2 = ObjectTypes.WoodenAxe;
    EntityId toolEntityId2 = TestInventoryUtils.addEntity(airEntityId, toolObjectTypeId2);
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
    assertEq(Inventory.length(aliceEntityId), 3, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupMinedChestDrops() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    ObjectTypeMetadata.setMass(ObjectTypes.Chest, playerHandMassReduction - 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    TestInventoryUtils.addObject(chestEntityId, transferObjectTypeId, numToPickup);
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
    assertEq(Inventory.length(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupFromNonAirButPassable() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.FescueGrass);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    uint16 numToPickup = 10;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: numToPickup });

    vm.prank(alice);
    world.pickup(aliceEntityId, pickup, pickupCoord);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToPickup);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 0);
    assertEq(Inventory.length(aliceEntityId), 1, "Inventory slots is not 0");
    assertEq(Inventory.length(airEntityId), 0, "Inventory slots is not 0");
  }

  function testPickupFailsIfInventoryFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    TestInventoryUtils.addObject(
      aliceEntityId,
      transferObjectTypeId,
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player)
        * ObjectTypeMetadata.getStackable(transferObjectTypeId)
    );
    assertEq(
      Inventory.length(aliceEntityId),
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player),
      "Inventory slots is not max"
    );

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("All slots used");
    world.pickup(aliceEntityId, pickup, pickupCoord);
  }

  function testDropFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 0, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);

    SlotTransfer[] memory drop = new SlotTransfer[](1);
    drop[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Not enough objects in slot");
    world.drop(aliceEntityId, drop, dropCoord);
  }

  function testPickupFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 0, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });
    vm.prank(alice);
    vm.expectRevert("Not enough objects in slot");
    world.pickup(aliceEntityId, pickup, dropCoord);
  }

  function testPickupFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 1, 0);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.pickup(aliceEntityId, pickup, pickupCoord);
  }

  function testDropFailsIfInvalidCoord() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(int32(MAX_ENTITY_INFLUENCE_HALF_WIDTH) + 1, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    SlotTransfer[] memory drop = new SlotTransfer[](1);
    drop[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Entity is too far");
    world.drop(aliceEntityId, drop, dropCoord);

    dropCoord = playerCoord - vec3(CHUNK_SIZE / 2 + 1, 1, 0);

    vm.prank(alice);
    vm.expectRevert("Chunk not explored yet");
    world.drop(aliceEntityId, drop, dropCoord);
  }

  function testDropFailsIfNonAirBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Dirt);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Cannot drop on a non-passable block");
    world.drop(aliceEntityId, drops, dropCoord);
  }

  function testPickupFailsIfNonAirBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    setTerrainAtCoord(pickupCoord, ObjectTypes.Air);
    EntityId airEntityId = ReversePosition.get(pickupCoord);
    assertFalse(airEntityId.exists(), "Drop entity doesn't exists");

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });
    vm.prank(alice);
    vm.expectRevert("No entity at pickup location");
    world.pickup(aliceEntityId, pickup, pickupCoord);

    EntityId chestEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Chest);
    TestInventoryUtils.addObject(chestEntityId, ObjectTypes.Grass, 1);

    vm.prank(alice);
    vm.expectRevert("Cannot pickup from a non-passable block");
    world.pickup(aliceEntityId, pickup, pickupCoord);
  }

  function testPickupFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 0 });

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.pickup(aliceEntityId, pickup, pickupCoord);
  }

  function testDropFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    TestInventoryUtils.addEntity(aliceEntityId, ObjectTypes.WoodenPick);

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 0 });

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.drop(aliceEntityId, drops, dropCoord);

    drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 1, slotTo: 0, amount: 0 });

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.drop(aliceEntityId, drops, dropCoord);
  }

  function testPickupFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.expectRevert("Caller not allowed");
    world.pickup(aliceEntityId, pickup, pickupCoord);
  }

  function testDropFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.expectRevert("Caller not allowed");
    world.drop(aliceEntityId, drops, dropCoord);
  }

  function testPickupFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 pickupCoord = playerCoord + vec3(0, 1, 1);
    EntityId airEntityId = setObjectAtCoord(pickupCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(airEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    SlotTransfer[] memory pickup = new SlotTransfer[](1);
    pickup[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.pickup(aliceEntityId, pickup, pickupCoord);
  }

  function testDropFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 1);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.Grass;
    TestInventoryUtils.addObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    SlotTransfer[] memory drops = new SlotTransfer[](1);
    drops[0] = SlotTransfer({ slotFrom: 0, slotTo: 0, amount: 1 });

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.drop(aliceEntityId, drops, dropCoord);
  }
}
