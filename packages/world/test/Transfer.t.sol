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

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, ChestObjectID, TextSignObjectID, WoodenPickObjectID, WoodenAxeObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract TransferTest is BiomesTest {
  using VoxelCoordLib for *;

  function testTransferToChest() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    uint16 numToTransfer = 10;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, numToTransfer);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 1");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("transfer to chest");
    world.transfer(chestEntityId, true, transferObjectTypeId, numToTransfer);
    endGasReport();

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(chestEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testTransferToolToChest() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);

    ObjectTypeId transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId = addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("transfer tool to chest");
    world.transferTool(chestEntityId, true, toolEntityId);
    endGasReport();

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 1, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 1, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(chestEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(InventoryEntity.get(toolEntityId) == chestEntityId, "Inventory entity is not chest");
    assertFalse(
      TestUtils.reverseInventoryEntityHasEntity(aliceEntityId, toolEntityId),
      "Inventory entity is not chest"
    );
    assertTrue(TestUtils.reverseInventoryEntityHasEntity(chestEntityId, toolEntityId), "Inventory entity is not chest");

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testTransferFromChest() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = ChestObjectID;
    uint16 numToTransfer = 10;
    TestUtils.addToInventoryCount(chestEntityId, ChestObjectID, transferObjectTypeId, numToTransfer);
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 1");
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("transfer from chest");
    world.transfer(chestEntityId, false, transferObjectTypeId, numToTransfer);
    endGasReport();

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), numToTransfer, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 0, "Inventory slots is not 0");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(chestEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testTransferToolFromChest() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);

    ObjectTypeId transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId1 = addToolToInventory(chestEntityId, transferObjectTypeId);
    EntityId toolEntityId2 = addToolToInventory(chestEntityId, transferObjectTypeId);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 2, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("transfer tools from chest");
    EntityId[] memory toolEntityIds = new EntityId[](2);
    toolEntityIds[0] = toolEntityId1;
    toolEntityIds[1] = toolEntityId2;
    world.transferTools(chestEntityId, false, toolEntityIds);
    endGasReport();

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 2, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(InventorySlots.get(chestEntityId), 0, "Inventory slots is not 0");
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(chestEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    for (uint256 i = 0; i < toolEntityIds.length; i++) {
      assertTrue(InventoryEntity.get(toolEntityIds[i]) == aliceEntityId, "Inventory entity is not chest");
      assertTrue(
        TestUtils.reverseInventoryEntityHasEntity(aliceEntityId, toolEntityIds[i]),
        "Inventory entity is not chest"
      );
      assertFalse(
        TestUtils.reverseInventoryEntityHasEntity(chestEntityId, toolEntityIds[i]),
        "Inventory entity is not chest"
      );
    }

    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testTransferToChestFailsIfChestFull() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
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
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 1");

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
  }

  function testTransferFromChestFailsIfPlayerFull() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
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
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 1, "Inventory count is not 1");

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(chestEntityId, false, transferObjectTypeId, 1);
  }

  function testTransferFailsIfInvalidObject() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId nonChestEntityId = setObjectAtCoord(chestCoord, DirtObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventoryCount.get(nonChestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    assertEq(ObjectTypeMetadata.getMaxInventorySlots(transferObjectTypeId), 0, "Max inventory slots is not 0");

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.transfer(nonChestEntityId, true, transferObjectTypeId, 1);
  }

  function testTransferFailsIfDoesntHaveBlock() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, 1);

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 1");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(chestEntityId, true, transferObjectTypeId, 2);

    vm.prank(alice);
    world.transfer(chestEntityId, true, transferObjectTypeId, 1);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 1, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.transfer(chestEntityId, false, transferObjectTypeId, 2);

    vm.prank(alice);
    world.transfer(chestEntityId, false, transferObjectTypeId, 1);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId = addToolToInventory(chestEntityId, transferObjectTypeId);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 1, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.transferTool(chestEntityId, true, toolEntityId);

    vm.prank(alice);
    world.transferTool(chestEntityId, false, toolEntityId);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 0");
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    vm.prank(alice);
    vm.expectRevert("Entity does not own inventory item");
    world.transferTool(chestEntityId, false, toolEntityId);
  }

  function testTransferFailsIfNoEnergy() public {}

  function testTransferFailsIfTooFar() public {}

  function testTransferFailsIfNoPlayer() public {}

  function testTransferFailsIfLoggedOut() public {}
}
