// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { EntityId } from "../src/EntityId.sol";
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
import { Mass } from "../src/codegen/tables/Mass.sol";
import { ReverseInventoryEntity } from "../src/codegen/tables/ReverseInventoryEntity.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";

import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract CraftTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function hashRecipe(
    ObjectTypeId stationObjectTypeId,
    ObjectTypeId[] memory inputTypes,
    uint16[] memory inputAmounts,
    ObjectTypeId[] memory outputTypes,
    uint16[] memory outputAmounts
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(stationObjectTypeId, inputTypes, inputAmounts, outputTypes, outputAmounts));
  }

  function testCraftSingleInputSingleOutput() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.OakPlanks;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("handcraft single input");
    world.craft(recipeId);
    endGasReport();

    for (uint256 i = 0; i < inputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, inputTypes[i], 0);
    }
    for (uint256 i = 0; i < outputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, outputTypes[i], outputAmounts[i]);
    }

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testCraftMultipleInputsSingleOutput() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](2);
    inputTypes[0] = ObjectTypes.Clay;
    inputTypes[1] = ObjectTypes.Sand;
    uint16[] memory inputAmounts = new uint16[](2);
    inputAmounts[0] = 4;
    inputAmounts[1] = 4;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.Dyeomatic;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("handcraft multiple inputs");
    world.craft(recipeId);
    endGasReport();

    for (uint256 i = 0; i < inputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, inputTypes[i], 0);
    }
    for (uint256 i = 0; i < outputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, outputTypes[i], outputAmounts[i]);
    }

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testCraftWithStation() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.SilverOre;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.SilverBar;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    bytes32 recipeId = hashRecipe(ObjectTypes.Thermoblaster, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    Vec3 stationCoord = playerCoord + vec3(1, 0, 0);
    EntityId stationEntityId = setObjectAtCoord(stationCoord, ObjectTypes.Thermoblaster);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("craft with station");
    world.craftWithStation(recipeId, stationEntityId);
    endGasReport();

    for (uint256 i = 0; i < inputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, inputTypes[i], 0);
    }
    for (uint256 i = 0; i < outputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, outputTypes[i], outputAmounts[i]);
    }

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testCraftAnyInput() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.AnyPlanks;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 8;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.Chest;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    bytes32 recipeId = hashRecipe(ObjectTypes.Workbench, inputTypes, inputAmounts, outputTypes, outputAmounts);

    ObjectTypeId inputObjectTypeId1 = ObjectTypes.OakPlanks;
    ObjectTypeId inputObjectTypeId2 = ObjectTypes.BirchPlanks;
    ObjectTypeId inputObjectTypeId3 = ObjectTypes.JunglePlanks;
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId1, 2);
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId2, 3);
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId3, 3);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId1, 2);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId2, 3);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId3, 3);
    Vec3 stationCoord = playerCoord + vec3(1, 0, 0);
    EntityId stationEntityId = setObjectAtCoord(stationCoord, ObjectTypes.Workbench);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("craft with any input");
    world.craftWithStation(recipeId, stationEntityId);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, inputObjectTypeId1, 0);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId2, 0);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId3, 0);
    for (uint256 i = 0; i < outputTypes.length; i++) {
      assertInventoryHasObject(aliceEntityId, outputTypes[i], outputAmounts[i]);
    }

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testCraftTool() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.AnyLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 4;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.WoodenPick;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    ObjectTypeId inputObjectTypeId = ObjectTypes.SakuraLog;
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId, 4);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 4);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("craft tool");
    world.craft(recipeId);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 0);
    bytes32[] memory toolEntityIds = ReverseInventoryEntity.get(aliceEntityId);
    assertEq(toolEntityIds.length, 1, "should have 1 tool");
    EntityId toolEntityId = EntityId.wrap(toolEntityIds[0]);
    assertTrue(toolEntityId.exists(), "tool entity id should exist");
    ObjectTypeId toolObjectTypeId = ObjectType.get(toolEntityId);
    assertEq(toolObjectTypeId, outputTypes[0], "tool object type should be equal to expected output object type");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
    assertEq(Mass.get(toolEntityId), ObjectTypeMetadata.getMass(outputTypes[0]), "mass should be equal to tool mass");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testCraftSameInputsMultipleOutputs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.AnyLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 4;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.WoodenPick;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    ObjectTypeId inputObjectTypeId = ObjectTypes.SakuraLog;
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId, 8);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 8);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.craft(recipeId);

    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 4);
    bytes32[] memory toolEntityIds = ReverseInventoryEntity.get(aliceEntityId);
    assertEq(toolEntityIds.length, 1, "should have 1 tool");
    EntityId toolEntityId = EntityId.wrap(toolEntityIds[0]);
    assertTrue(toolEntityId.exists(), "tool entity id should exist");
    ObjectTypeId toolObjectTypeId = ObjectType.get(toolEntityId);
    assertEq(toolObjectTypeId, outputTypes[0], "tool object type should be equal to expected output object type");
    assertInventoryHasTool(aliceEntityId, toolEntityId, 1);
    assertEq(Mass.get(toolEntityId), ObjectTypeMetadata.getMass(outputTypes[0]), "mass should be equal to tool mass");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);

    outputTypes[0] = ObjectTypes.WoodenAxe;
    recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    world.craft(recipeId);

    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 0);
    toolEntityIds = ReverseInventoryEntity.get(aliceEntityId);
    assertEq(toolEntityIds.length, 2, "should have 2 tools");
    EntityId toolEntityId2 = EntityId.wrap(toolEntityIds[1]);
    assertTrue(toolEntityId2.exists(), "tool entity id should exist");
    ObjectTypeId toolObjectTypeId2 = ObjectType.get(toolEntityId2);
    assertEq(toolObjectTypeId2, outputTypes[0], "tool object type should be equal to expected output object type");
    assertInventoryHasTool(aliceEntityId, toolEntityId2, 1);
    assertEq(Mass.get(toolEntityId2), ObjectTypeMetadata.getMass(outputTypes[0]), "mass should be equal to tool mass");

    afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testCraftMultipleOutputs() public {
    // TODO: implement
  }

  function testCraftFailsIfNotEnoughInputs() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.OakPlanks;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.craft(recipeId);

    inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.AnyPlanks;
    inputAmounts = new uint16[](1);
    inputAmounts[0] = 8;
    outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.Chest;
    outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    recipeId = hashRecipe(ObjectTypes.Workbench, inputTypes, inputAmounts, outputTypes, outputAmounts);

    ObjectTypeId inputObjectTypeId1 = ObjectTypes.OakPlanks;
    ObjectTypeId inputObjectTypeId2 = ObjectTypes.BirchPlanks;
    ObjectTypeId inputObjectTypeId3 = ObjectTypes.JunglePlanks;
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId1, 1);
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId2, 1);
    TestInventoryUtils.addToInventory(aliceEntityId, inputObjectTypeId3, 1);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId1, 1);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId2, 1);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId3, 1);
    Vec3 stationCoord = playerCoord + vec3(1, 0, 0);
    EntityId stationEntityId = setObjectAtCoord(stationCoord, ObjectTypes.Workbench);

    vm.prank(alice);
    vm.expectRevert("Not enough objects in the inventory");
    world.craftWithStation(recipeId, stationEntityId);
  }

  function testCraftFailsIfInvalidRecipe() public {
    (address alice, , ) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.Diamond;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    vm.prank(alice);
    vm.expectRevert("Recipe not found");
    world.craft(recipeId);
  }

  function testCraftFailsIfInvalidStation() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.SilverOre;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.SilverBar;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 1;
    bytes32 recipeId = hashRecipe(ObjectTypes.Thermoblaster, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    Vec3 stationCoord = playerCoord + vec3(1, 0, 0);
    EntityId stationEntityId = setObjectAtCoord(stationCoord, ObjectTypes.Workbench);

    vm.prank(alice);
    vm.expectRevert("This recipe requires a station");
    world.craft(recipeId);

    vm.prank(alice);
    vm.expectRevert("Invalid station");
    world.craftWithStation(recipeId, stationEntityId);

    stationCoord = playerCoord + vec3(MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, 0, 0);
    stationEntityId = setObjectAtCoord(stationCoord, ObjectTypes.Thermoblaster);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.craftWithStation(recipeId, stationEntityId);
  }

  function testCraftFailsIfFullInventory() public {
    (address alice, EntityId aliceEntityId, ) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.OakPlanks;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    TestInventoryUtils.addToInventory(
      aliceEntityId,
      ObjectTypes.OakLog,
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player) * ObjectTypeMetadata.getStackable(ObjectTypes.OakLog)
    );
    assertEq(
      InventorySlots.get(aliceEntityId),
      ObjectTypeMetadata.getMaxInventorySlots(ObjectTypes.Player),
      "Inventory slots is not max"
    );

    vm.prank(alice);
    vm.expectRevert("Inventory is full");
    world.craft(recipeId);
  }

  function testCraftFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, ) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.OakPlanks;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    Energy.setEnergy(aliceEntityId, 1);

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.craft(recipeId);
  }

  function testCraftFailsIfNoPlayer() public {
    (, EntityId aliceEntityId, ) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.OakPlanks;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    vm.expectRevert("Player does not exist");
    world.craft(recipeId);
  }

  function testCraftFailsIfSleeping() public {
    (address alice, EntityId aliceEntityId, ) = setupAirChunkWithPlayer();

    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = ObjectTypes.OakLog;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    ObjectTypeId[] memory outputTypes = new ObjectTypeId[](1);
    outputTypes[0] = ObjectTypes.OakPlanks;
    uint16[] memory outputAmounts = new uint16[](1);
    outputAmounts[0] = 4;
    bytes32 recipeId = hashRecipe(ObjectTypes.Null, inputTypes, inputAmounts, outputTypes, outputAmounts);

    for (uint256 i = 0; i < inputTypes.length; i++) {
      TestInventoryUtils.addToInventory(aliceEntityId, inputTypes[i], inputAmounts[i]);
      assertInventoryHasObject(aliceEntityId, inputTypes[i], inputAmounts[i]);
    }

    PlayerStatus.setBedEntityId(aliceEntityId, randomEntityId());

    vm.prank(alice);
    vm.expectRevert("Player is sleeping");
    world.craft(recipeId);
  }
}
