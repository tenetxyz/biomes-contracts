// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
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
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID } from "../src/ObjectTypeIds.sol";

contract MoveTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal alice;
  VoxelCoord spawnCoord;

  function setUp() public override {
    super.setUp();

    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    world = IWorld(worldAddress);
  }

  function setupPlayer() public returns (bytes32) {
    spawnCoord = VoxelCoord(197, 27, 203);
    return world.spawnPlayer(spawnCoord);
  }

  function testMine() public {
    vm.startPrank(alice, alice);

    setupPlayer();

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);

    startGasReport("move to new entity");
    world.move(newCoords);
    endGasReport();

    vm.roll(block.number + 1);

    startGasReport("move");
    newCoords[0] = spawnCoord;
    world.move(newCoords);
    endGasReport();

    vm.stopPrank();
  }
}
