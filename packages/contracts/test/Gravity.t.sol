// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "../src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../src/codegen/tables/Stamina.sol";
import { Inventory } from "../src/codegen/tables/Inventory.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@everlonxyz/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, addToInventoryCount } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID } from "../src/ObjectTypeIds.sol";

contract GravityTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
  }

  function setupPlayer() public returns (bytes32) {
    spawnCoord = VoxelCoord(197, 27, 203);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    return world.spawnPlayer(spawnCoord);
  }

  function testMineGravitySingle() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    startGasReport("gravity via mine, fall one block");
    world.mine(terrainObjectTypeId, mineCoord);
    endGasReport();

    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");
    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord), "Player position not set");

    vm.stopPrank();
  }

  function testMineGravityMultiple() public {
     vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    VoxelCoord memory mineCoord = VoxelCoord(spawnCoord.x, spawnCoord.y - 2, spawnCoord.z);
    bytes32 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    world.mine(terrainObjectTypeId, mineCoord);

    VoxelCoord memory mineCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y - 1, spawnCoord.z);
    terrainObjectTypeId = world.getTerrainBlock(mineCoord2);
    assertTrue(terrainObjectTypeId != AirObjectID, "Terrain block is air");

    startGasReport("gravity via mine, fall two blocks");
    world.mine(terrainObjectTypeId, mineCoord2);
    endGasReport();

    bytes32 newEntityId = ReversePosition.get(spawnCoord.x, spawnCoord.y, spawnCoord.z);
    assertTrue(newEntityId != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId) == AirObjectID, "Player didnt fall, air not set");

    bytes32 newEntityId2 = ReversePosition.get(mineCoord2.x, mineCoord2.y, mineCoord2.z);
    assertTrue(newEntityId2 != bytes32(0), "Mine entity not found");
    assertTrue(ObjectType.get(newEntityId2) == AirObjectID, "Player didnt fall, air not set");

    assertTrue(ObjectType.get(playerEntityId) == PlayerObjectID, "Player didnt fall, player object not found");
    assertTrue(voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(playerEntityId)), mineCoord), "Player position not set");

    vm.stopPrank();
  }

  function testMineGravityFatal() public {}

  function testMoveGravitySingle() public {}

  function testMoveGravityMultiple() public {}

  function testMoveGravityFatal() public {}
}
