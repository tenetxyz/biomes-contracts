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

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { PlayerObjectID, AirObjectID, WaterObjectID, DirtObjectID, SpawnTileObjectID, GrassObjectID, ForceFieldObjectID, ChestObjectID, TextSignObjectID, OakLogObjectID, OakLumberObjectID } from "../src/ObjectTypeIds.sol";
import { ObjectTypeId } from "../src/ObjectTypeIds.sol";
import { CHUNK_SIZE, MAX_PLAYER_INFLUENCE_HALF_WIDTH, WORLD_BORDER_LOW_X } from "../src/Constants.sol";
import { VoxelCoord, VoxelCoordLib } from "../src/VoxelCoord.sol";
import { TestUtils } from "./utils/TestUtils.sol";

contract CraftTest is BiomesTest {
  using VoxelCoordLib for *;

  function testHandcraftSingleInput() public {
    (address alice, EntityId aliceEntityId, VoxelCoord memory playerCoord) = setupAirChunkWithPlayer();

    ObjectTypeId inputObjectTypeId = OakLogObjectID;
    TestUtils.addToInventoryCount(aliceEntityId, PlayerObjectID, inputObjectTypeId, 1);
    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 1);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    ObjectTypeId expectedOutputObjectTypeId = OakLumberObjectID;
    uint16 expectedOutputAmount = 4;

    vm.prank(alice);
    startGasReport("handcraft single input");
    ObjectTypeId[] memory inputTypes = new ObjectTypeId[](1);
    inputTypes[0] = inputObjectTypeId;
    uint16[] memory inputAmounts = new uint16[](1);
    inputAmounts[0] = 1;
    world.craft(inputTypes, inputAmounts);
    endGasReport();

    assertInventoryHasObject(aliceEntityId, inputObjectTypeId, 0);
    assertInventoryHasObject(aliceEntityId, expectedOutputObjectTypeId, expectedOutputAmount);

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testHandcraftMultipleInputs() public {}

  function testHandcraftAnyInput() public {}

  function testCraftWithStation() public {}

  function testCraftTool() public {}

  function testCraftFailsIfNotEnoughInputs() public {}

  function testCraftFailsIfNotEnoughAnyInputs() public {}

  function testCraftFailsIfInvalidRecipe() public {}

  function testCraftFailsIfInvalidStation() public {}

  function testCraftFailsIfStationTooFar() public {}

  function testCraftFailsIfFullInventory() public {}

  function testCraftFailsIfNotEnoughEnergy() public {}

  function testCraftFailsIfNoPlayer() public {}

  function testCraftFailsIfSleeping() public {}
}
