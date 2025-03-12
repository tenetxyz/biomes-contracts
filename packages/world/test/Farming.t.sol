// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { console } from "forge-std/console.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { ResourceId, WorldResourceIdLib } from "@latticexyz/world/src/WorldResourceId.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";
import { Energy, EnergyData } from "../src/codegen/tables/Energy.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";

import { ReversePosition, PlayerPosition } from "../src/utils/Vec3Storage.sol";

import { TerrainLib } from "../src/systems/libraries/TerrainLib.sol";
import { massToEnergy } from "../src/utils/EnergyUtils.sol";
import { ObjectTypeId } from "../src/ObjectTypeId.sol";
import { ObjectTypes } from "../src/ObjectTypes.sol";
import { ObjectTypeLib } from "../src/ObjectTypeLib.sol";
import { PLAYER_TILL_ENERGY_COST, MAX_PLAYER_INFLUENCE_HALF_WIDTH } from "../src/Constants.sol";
import { Vec3, vec3 } from "../src/Vec3.sol";
import { EntityId } from "../src/EntityId.sol";

import { BiomesTest } from "./BiomesTest.sol";
import { TestInventoryUtils } from "./utils/TestUtils.sol";

contract FarmingTest is BiomesTest {
  using ObjectTypeLib for ObjectTypeId;

  function testTillDirt() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);
    EntityId dirtEntityId = ReversePosition.get(dirtCoord);
    assertFalse(dirtEntityId.exists(), "Dirt entity already exists");

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("till dirt");
    world.till(dirtCoord);
    endGasReport();

    dirtEntityId = ReversePosition.get(dirtCoord);
    assertTrue(dirtEntityId.exists(), "Dirt entity doesn't exist after tilling");
    assertEq(ObjectType.get(dirtEntityId), ObjectTypes.Farmland, "Dirt was not converted to farmland");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTillGrass() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 grassCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(grassCoord, ObjectTypes.Grass);
    EntityId grassEntityId = ReversePosition.get(grassCoord);
    assertFalse(grassEntityId.exists(), "Grass entity already exists");

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    EnergyDataSnapshot memory beforeEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);

    vm.prank(alice);
    startGasReport("till grass");
    world.till(grassCoord);
    endGasReport();

    grassEntityId = ReversePosition.get(grassCoord);
    assertTrue(grassEntityId.exists(), "Grass entity doesn't exist after tilling");
    assertEq(ObjectType.get(grassEntityId), ObjectTypes.Farmland, "Grass was not converted to farmland");

    EnergyDataSnapshot memory afterEnergyDataSnapshot = getEnergyDataSnapshot(aliceEntityId, playerCoord);
    assertEnergyFlowedFromPlayerToLocalPool(beforeEnergyDataSnapshot, afterEnergyDataSnapshot);
  }

  function testTillWithDifferentHoes() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    ObjectTypeId[] memory hoeTypes = new ObjectTypeId[](1);
    hoeTypes[0] = ObjectTypes.WoodenHoe;

    for (uint256 i = 0; i < hoeTypes.length; i++) {
      Vec3 testCoord = dirtCoord + vec3(int32(int256(i)), 0, 0);
      setObjectAtCoord(testCoord, ObjectTypes.Dirt);

      EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, hoeTypes[i]);
      vm.prank(alice);
      world.equip(hoeEntityId);

      vm.prank(alice);
      world.till(testCoord);

      EntityId farmlandEntityId = ReversePosition.get(testCoord);
      assertTrue(farmlandEntityId.exists(), "Farmland entity doesn't exist after tilling");
      assertEq(ObjectType.get(farmlandEntityId), ObjectTypes.Farmland, "Dirt was not converted to farmland");
    }
  }

  function testTillFailsIfNotDirtOrGrass() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 nonDirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(nonDirtCoord, ObjectTypes.Stone);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Not dirt or grass");
    world.till(nonDirtCoord);
  }

  function testTillFailsIfNoHoeEquipped() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    // No hoe equipped

    vm.prank(alice);
    vm.expectRevert("Must equip a hoe");
    world.till(dirtCoord);

    // Equipped but not a hoe
    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.SilverPick);
    vm.prank(alice);
    world.equip(hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Must equip a hoe");
    world.till(dirtCoord);
  }

  function testTillFailsIfTooFar() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + MAX_PLAYER_INFLUENCE_HALF_WIDTH + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    vm.prank(alice);
    vm.expectRevert("Player is too far");
    world.till(dirtCoord);
  }

  function testTillFailsIfNotEnoughEnergy() public {
    (address alice, EntityId aliceEntityId, Vec3 playerCoord) = setupAirChunkWithPlayer();

    Vec3 dirtCoord = vec3(playerCoord.x() + 1, 0, playerCoord.z());
    setTerrainAtCoord(dirtCoord, ObjectTypes.Dirt);

    EntityId hoeEntityId = TestInventoryUtils.addToolToInventory(aliceEntityId, ObjectTypes.WoodenHoe);
    vm.prank(alice);
    world.equip(hoeEntityId);

    // Set player energy to less than required
    uint128 toolMass = 0; // Assuming tool mass is 0 for simplicity
    uint128 energyCost = PLAYER_TILL_ENERGY_COST + massToEnergy(toolMass);
    Energy.set(
      aliceEntityId,
      EnergyData({
        lastUpdatedTime: uint128(block.timestamp),
        energy: energyCost - 1,
        drainRate: 0,
        accDepletedTime: 0
      })
    );

    vm.prank(alice);
    vm.expectRevert("Not enough energy");
    world.till(dirtCoord);
  }
}
