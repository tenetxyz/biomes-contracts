// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { Program } from "../src/codegen/tables/Program.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { MinedOrePosition, PlayerPosition, Position, ReversePosition, OreCommitment } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract EquipTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function testEquip() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    startGasReport("equip tool");
    world.equip(toolEntityId);
    endGasReport();

    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
  }

  function testUnequip() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.equip(toolEntityId);

    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    vm.prank(alice);
    startGasReport("unequip tool");
    world.unequip();
    endGasReport();

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
  }

  function testEquipAlreadyEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId1 = ObjectTypes.WoodenPick;
    EntityId toolEntityId1 = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId1);
    assertInventoryHasTool(aliceEntityId, toolEntityId1, 1);

    ObjectTypeId toolObjectTypeId2 = ObjectTypes.WoodenAxe;
    EntityId toolEntityId2 = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId2);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.equip(toolEntityId1);

    assertEq(Equipped.get(aliceEntityId), toolEntityId1, "Equipped entity is not tool entity id");
    assertInventoryHasTool(aliceEntityId, toolEntityId1, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 1);

    vm.prank(alice);
    world.equip(toolEntityId2);

    assertEq(Equipped.get(aliceEntityId), toolEntityId2, "Equipped entity is not tool entity id");
    assertInventoryHasTool(aliceEntityId, toolEntityId1, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 1);
  }

  function testUnequipNothingEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.unequip();

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
  }

  function testDropEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dropCoord = playerCoord + vec3(0, 1, 0);
    setObjectAtCoord(dropCoord, ObjectTypes.Air);
    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    EntityId airEntityId = ReversePosition.get(dropCoord);
    assertTrue(airEntityId.exists(), "Drop entity already exists");

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.equip(toolEntityId);

    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");

    vm.prank(alice);
    world.dropTool(toolEntityId, dropCoord);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertInventoryHasTool(airEntityId, toolEntityId, 1);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertEq(InventoryEntity.get(toolEntityId), airEntityId, "Inventory entity is not air");
  }

  function testTransferEquippedToChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ObjectTypes.Chest);

    ObjectTypeId transferObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.equip(toolEntityId);

    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");

    vm.prank(alice);
    world.transferTool(chestEntityId, true, toolEntityId, "");

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    assertInventoryHasTool(chestEntityId, toolEntityId, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
  }

  function testMineWithEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    Vec3 mineCoord = vec3(playerCoord.x() + 1, FLAT_CHUNK_GRASS_LEVEL, playerCoord.z());

    ObjectTypeId mineObjectTypeId = TerrainLib.getBlockType(mineCoord);
    uint128 expectedMassReductionFromTool = 50;
    ObjectTypeMetadata.setMass(mineObjectTypeId, uint32(expectedMassReductionFromTool));
    EntityId mineEntityId = ReversePosition.get(mineCoord);
    assertFalse(mineEntityId.exists(), "Mine entity already exists");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 0);

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    vm.prank(alice);
    world.equip(toolEntityId);
    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");

    uint128 toolMassBefore = Mass.getMass(toolEntityId);

    vm.prank(alice);
    startGasReport("mine terrain with tool, entirely mined");
    world.mineUntilDestroyed(mineCoord, "");
    endGasReport();

    uint128 toolMassAfter = Mass.getMass(toolEntityId);
    assertEq(
      toolMassAfter,
      toolMassBefore - expectedMassReductionFromTool,
      "Tool mass is not reduced by expected amount"
    );
    mineEntityId = ReversePosition.get(mineCoord);
    assertEq(ObjectType.get(mineEntityId), ObjectTypes.Air, "Mine entity is not air");
    assertInventoryHasObject(aliceEntityId, mineObjectTypeId, 1);
  }

  function testMineWithEquippedZeroDurability() public {
    vm.skip(true, "TODO");
  }

  function testHitWithEquipped() public {
    vm.skip(true, "TODO");
  }

  function testHitWithEquippedZeroDurability() public {
    vm.skip(true, "TODO");
  }

  function testEquipFailsIfNotOwned() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    (address bob, EntityId bobEntityId, Vec3 bobCoord) = spawnPlayerOnAirChunk(aliceCoord + vec3(0, 0, 1));

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    vm.prank(bob);
    vm.expectRevert("Player does not own inventory item");
    world.equip(toolEntityId);
  }

  function testEquipFailsIfInvalidTool() public {
    (address alice, EntityId aliceEntityId, Vec3 aliceCoord) = setupAirChunkWithPlayer();

    vm.prank(alice);
    vm.expectRevert("Player does not own inventory item");
    world.equip(randomEntityId());
  }

  function testEquipFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.expectRevert("Player does not exist");
    world.equip(toolEntityId);
  }

  function testEquipFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.equip(toolEntityId);
  }

  function testUnequipFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.equip(toolEntityId);

    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");

    vm.expectRevert("Player does not exist");
    world.unequip();
  }

  function testUnequipFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupFlatChunkWithPlayer();

    ObjectTypeId toolObjectTypeId = ObjectTypes.WoodenPick;
    EntityId toolEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, toolObjectTypeId);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);

    assertEq(Equipped.get(aliceEntityId), EntityId.wrap(bytes32(0)), "Equipped entity is not 0");

    vm.prank(alice);
    world.equip(toolEntityId);

    assertEq(Equipped.get(aliceEntityId), toolEntityId, "Equipped entity is not tool entity id");

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.unequip();
  }
}
