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
import { TotalMinedOreCount } from "../src/codegen/tables/TotalMinedOreCount.sol";
import { MinedOreCount } from "../src/codegen/tables/MinedOreCount.sol";
import { TotalBurnedOreCount } from "../src/codegen/tables/TotalBurnedOreCount.sol";
import { MinedOrePosition } from "../src/codegen/tables/MinedOrePosition.sol";
import { InventoryEntity } from "../src/codegen/tables/InventoryEntity.sol";
import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";

import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, ChestObjectID, TextSignObjectID, WoodenPickObjectID, WoodenAxeObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract DropTest is BiomesTest {
  using VoxelCoordLib for *;

  function testDropTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory dropCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    setTerrainAtCoord(dropCoord, AirObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    uint16 numToTransfer = 10;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, numToTransfer);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 1");
    EntityId airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertFalse(airEntityId.exists(), "Drop entity already exists");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("drop terrain");
    world.drop(transferObjectTypeId, numToTransfer, dropCoord);
    endGasReport();

    airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(airEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(airEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testDropNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory dropCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    setObjectAtCoord(dropCoord, AirObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    uint16 numToTransfer = 10;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, transferObjectTypeId, numToTransfer);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 1");
    EntityId airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId.exists(), "Drop entity doesn't exist");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("drop non-terrain");
    world.drop(transferObjectTypeId, numToTransfer, dropCoord);
    endGasReport();

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(airEntityId, transferObjectTypeId), numToTransfer, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(airEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testDropToolTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory dropCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    setTerrainAtCoord(dropCoord, AirObjectID);
    ObjectTypeId transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId = addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 1");
    EntityId airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertFalse(airEntityId.exists(), "Drop entity already exists");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("drop tool terrain");
    world.dropTool(toolEntityId, dropCoord);
    endGasReport();

    airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(airEntityId, transferObjectTypeId), 1, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertTrue(InventoryEntity.get(toolEntityId) == airEntityId, "Inventory entity is not air");
    assertFalse(
      TestUtils.reverseInventoryEntityHasEntity(aliceEntityId, toolEntityId),
      "Inventory entity is not chest"
    );
    assertTrue(TestUtils.reverseInventoryEntityHasEntity(airEntityId, toolEntityId), "Inventory entity is not air");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(airEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testDropToolNonTerrain() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory dropCoord = VoxelCoord(playerCoord.x, playerCoord.y + 1, playerCoord.z);
    setObjectAtCoord(dropCoord, AirObjectID);
    ObjectTypeId transferObjectTypeId = WoodenPickObjectID;
    EntityId toolEntityId = addToolToInventory(aliceEntityId, transferObjectTypeId);
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 1, "Inventory count is not 1");
    EntityId airEntityId = ReversePosition.get(dropCoord.x, dropCoord.y, dropCoord.z);
    assertTrue(airEntityId.exists(), "Drop entity already exists");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    startGasReport("drop tool non-terrain");
    world.dropTool(toolEntityId, dropCoord);
    endGasReport();

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventoryCount.get(airEntityId, transferObjectTypeId), 1, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 0, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 1, "Inventory slots is not 0");
    assertTrue(InventoryEntity.get(toolEntityId) == airEntityId, "Inventory entity is not air");
    assertFalse(
      TestUtils.reverseInventoryEntityHasEntity(aliceEntityId, toolEntityId),
      "Inventory entity is not chest"
    );
    assertTrue(TestUtils.reverseInventoryEntityHasEntity(airEntityId, toolEntityId), "Inventory entity is not air");
    assertFalse(
      TestUtils.inventoryObjectsHasObjectType(aliceEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    assertTrue(
      TestUtils.inventoryObjectsHasObjectType(airEntityId, transferObjectTypeId),
      "Inventory objects still has build object type"
    );
    uint128 energyGainedInPool = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z) - localEnergyPoolBefore;
    assertTrue(energyGainedInPool > 0, "Local energy pool did not gain energy");
    assertEq(Energy.getEnergy(aliceEntityId), aliceEnergyBefore - energyGainedInPool, "Player did not lose energy");
  }

  function testPickup() public {}

  function testPickupMultiple() public {}

  function testPickupAll() public {}

  function testPickupMinedChestDrops() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    VoxelCoord memory chestCoord = VoxelCoord(playerCoord.x, playerCoord.y, playerCoord.z + 1);
    ObjectTypeMetadata.setMass(ChestObjectID, uint32(playerHandMassReduction - 1));
    EntityId chestEntityId = setObjectAtCoord(chestCoord, ChestObjectID);
    ObjectTypeId transferObjectTypeId = GrassObjectID;
    uint16 numToPickup = 10;
    TestUtils.addToInventoryCount(chestEntityId, ChestObjectID, transferObjectTypeId, numToPickup);
    assertEq(InventoryCount.get(chestEntityId, transferObjectTypeId), numToPickup, "Inventory count is not 1");
    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), 0, "Inventory count is not 0");

    vm.prank(alice);
    world.mine(chestCoord);

    EntityId airEntityId = ReversePosition.get(chestCoord.x, chestCoord.y, chestCoord.z);
    assertTrue(airEntityId.exists(), "Drop entity does not exist");
    assertTrue(ObjectType.get(airEntityId) == AirObjectID, "Drop entity is not air");
    assertEq(InventoryCount.get(airEntityId, transferObjectTypeId), numToPickup, "Inventory count is not 0");

    uint128 aliceEnergyBefore = Energy.getEnergy(aliceEntityId);
    VoxelCoord memory shardCoord = playerCoord.toLocalEnergyPoolShardCoord();
    uint128 localEnergyPoolBefore = LocalEnergyPool.get(shardCoord.x, 0, shardCoord.z);

    vm.prank(alice);
    world.pickupAll(chestCoord);

    assertEq(InventoryCount.get(aliceEntityId, transferObjectTypeId), numToPickup, "Inventory count is not 0");
    assertEq(InventoryCount.get(airEntityId, transferObjectTypeId), 0, "Inventory count is not 0");
    assertEq(InventorySlots.get(aliceEntityId), 2, "Inventory slots is not 0");
    assertEq(InventorySlots.get(airEntityId), 0, "Inventory slots is not 0");
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

  function testPickupTool() public {}

  function testPickupFailsIfInventoryFull() public {}

  function testPickupFailsIfInvalidCoord() public {}

  function testDropFailsIfInvalidCoord() public {}

  function testDropFailsIfNonAirBlock() public {}

  function testPickupFailsIfNonAirBlock() public {}

  function testPickupFailsIfInvalidArgs() public {}

  function testDropFailsIfInvalidArgs() public {}

  function testPickupFailsIfNotEnoughEnergy() public {}

  function testDropFailsIfNotEnoughEnergy() public {}

  function testPickupFailsIfNoPlayer() public {}

  function testDropFailsIfNoPlayer() public {}

  function testPickupFailsIfSleeping() public {}

  function testDropFailsIfSleeping() public {}
}
