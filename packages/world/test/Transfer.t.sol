// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ExploredChunk } from "../src/codegen/tables/ExploredChunk.sol";
import { ExploredChunkCount } from "../src/codegen/tables/ExploredChunkCount.sol";
import { ExploredChunkByIndex } from "../src/codegen/tables/ExploredChunkByIndex.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { WorldStatus } from "../src/codegen/tables/WorldStatus.sol";
import { ForceField } from "../src/codegen/tables/ForceField.sol";
import { LocalEnergyPool } from "../src/codegen/tables/LocalEnergyPool.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerPosition } from "../src/codegen/tables/PlayerPosition.sol";
import { ReversePlayerPosition } from "../src/codegen/tables/ReversePlayerPosition.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { OreCommitment } from "../src/codegen/tables/OreCommitment.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
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
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, ChestObjectID, TextSignObjectID, WoodenPickObjectID, WoodenAxeObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract TransferTest is BiomesTest {
  function testTransferToChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    uint16 numToTransfer = 10;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("transfer to chest");
    world.transfer(chestEntityId, true, transferObjectTypeId, numToTransfer);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTransferToolToChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);

    ObjectTypeId transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId = addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("transfer tool to chest");
    world.transferTool(chestEntityId, true, toolEntityId);
    endGasReport();

    assertInventoryHasTool(chestEntityId, toolEntityId, 1);
    assertInventoryHasTool(aliceEntityId, toolEntityId, 0);
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTransferFromChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = ChestObjectID;
    uint16 numToTransfer = 10;
    TestUtils.addToInventoryCount(chestEntityId, ChestObjectID, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("transfer from chest");
    world.transfer(chestEntityId, false, transferObjectTypeId, numToTransfer);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, numToTransfer);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);
    assertEq(InventorySlots.get(aliceEntityId), numToTransfer, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 0, "Inventory slots is not 0");
    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTransferToolFromChest() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);

    ObjectTypeId transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId1 = addToolToInventory(chestEntityId, transferObjectTypeId);
    EntityId toolEntityId2 = addToolToInventory(chestEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 2);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("transfer tools from chest");
    EntityId[] memory toolEntityIds = new EntityId[](2);
    toolEntityIds[0] = toolEntityId1;
    toolEntityIds[1] = toolEntityId2;
    world.transferTools(chestEntityId, false, toolEntityIds);
    endGasReport();

    assertInventoryHasTool(aliceEntityId, toolEntityId1, 2);
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 2);
    assertInventoryHasTool(chestEntityId, toolEntityId1, 0);
    assertInventoryHasTool(chestEntityId, toolEntityId2, 0);
    assertEq(InventorySlots.get(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 0, "Inventory slots is not 0");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTransferToChestFailsIfChestFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    uint16 maxChestInventorySlots = ObjectTypeMetadata.getMaxInventorySlots(ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(
      chestEntityId,
      ChestObjectID,
      transferObjectTypeId,
      ObjectTypeMetadata.getStackable(transferObjectTypeId) * maxChestInventorySlots
    );
    assertEq(InventorySlots.get(chestEntityId), maxChestInventorySlots, "Inventory slots is not max");

    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
  }

  function testTransferFromChestFailsIfPlayerFull() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    uint16 maxPlayerInventorySlots = ObjectTypeMetadata.getMaxInventorySlots(PlayerObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(
      aliceEntityId,
      PlayerObjectID,
      transferObjectTypeId,
      ObjectTypeMetadata.getStackable(transferObjectTypeId) * maxPlayerInventorySlots
    );
    assertEq(InventorySlots.get(aliceEntityId), maxPlayerInventorySlots, "Inventory slots is not max");

    TestUtils.addToInventoryCount(chestEntityId, ChestObjectID, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(chestEntityId, false, transferObjectTypeId, 1);
  }

  function testTransferFailsIfInvalidObject() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId nonChestEntityId = setObjectAtCoord(chestCoord, DirtObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(nonChestEntityId, transferObjectTypeId, 0);

    assertEq(ObjectTypeMetadata.getMaxInventorySlots(transferObjectTypeId), 0, "Max inventory slots is not 0");

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(nonChestEntityId, true, transferObjectTypeId, 1);
  }

  function testTransferFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(chestEntityId, true, transferObjectTypeId, 2);

    vm.prank(alice);
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(chestEntityId, false, transferObjectTypeId, 2);

    vm.prank(alice);
    world.transfer(chestEntityId, false, transferObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId = addToolToInventory(chestEntityId, transferObjectTypeId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 0);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.transferTool(chestEntityId, true, toolEntityId);

    vm.prank(alice);
    world.transferTool(chestEntityId, false, toolEntityId);
    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.transferTool(chestEntityId, false, toolEntityId);
  }

  function testTransferFailsIfInvalidArgs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    EntityId toolEntityId1 = addToolToInventory(aliceEntityId, WoodenPickObjectID);
    EntityId toolEntityId2 = addToolToInventory(aliceEntityId, WoodenAxeObjectID);

    vm.prank(alice);
    vm.expectRevert("Object type is not a block or item");
    world.transfer(chestEntityId, true, WoodenPickObjectID, 1);

    vm.prank(alice);
    vm.expectRevert("Amount must be greater than 0");
    world.transfer(chestEntityId, true, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Must transfer at least one tool");
    world.transferTools(chestEntityId, true, new EntityId[](0));

    EntityId[] memory toolEntityIds = new EntityId[](2);
    toolEntityIds[0] = toolEntityId1;
    toolEntityIds[1] = toolEntityId2;

    vm.prank(alice);
    vm.expectRevert("All tools must be of the same type");
    world.transferTools(chestEntityId, true, toolEntityIds);
  }

  function testTransferFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    Energy.setEnergy(aliceEntityId, 1);

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
  }

  function testTransferFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.prank(alice);
    vm.expectRevert("Destination too far");
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);

    vm.prank(alice);
    vm.expectRevert("Destination too far");
    world.transfer(chestEntityId, false, transferObjectTypeId, 1);
  }

  function testTransferFailsIfNoPlayer() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    vm.expectRevert("Player does not exist");
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
  }

  function testTransferFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 chestCoord = playerCoord + vec3(0, 0, 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    assertInventoryHasObject(aliceEntityId, transferObjectTypeId, 1);
    assertInventoryHasObject(chestEntityId, transferObjectTypeId, 0);

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
  }
}
