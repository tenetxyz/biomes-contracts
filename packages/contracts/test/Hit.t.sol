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
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_BUILD_MINE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, BLOCKS_BEFORE_INCREASE_STAMINA, BLOCKS_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID } from "../src/ObjectTypeIds.sol";

contract HitTest is MudTest, GasReporter {
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

  function setupPlayer2(int32 zOffset) public returns (bytes32) {
    vm.startPrank(bob, bob);
    VoxelCoord memory spawnCoord2 = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z + zOffset);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);
    vm.stopPrank();
    return playerEntityId2;
  }

  function testHit() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    uint16 player1HealthBefore = Health.getHealth(playerEntityId);
    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    uint16 player2HealthBefore = Health.getHealth(playerEntityId2);
    uint32 player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    startGasReport("hit player");
    world.hit(bob);
    endGasReport();

    assertTrue(Health.getHealth(playerEntityId) == player1HealthBefore, "Player 1 health changed");
    assertTrue(Health.getHealth(playerEntityId2) < player2HealthBefore, "Player 2 health did not decrease");

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.stopPrank();
  }

  function testHitWithEquipped() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    uint16 player1HealthBefore = Health.getHealth(playerEntityId);
    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    uint16 player2HealthBefore = Health.getHealth(playerEntityId2);
    uint32 player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    world.hit(bob);

    assertTrue(Health.getHealth(playerEntityId) == player1HealthBefore, "Player 1 health changed");
    assertTrue(Health.getHealth(playerEntityId2) < player2HealthBefore, "Player 2 health did not decrease");

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.startPrank(worldDeployer, worldDeployer);
    bytes32 newInventoryId = getUniqueEntity();
    ObjectType.set(newInventoryId, WoodenPickObjectID);
    Inventory.set(newInventoryId, playerEntityId);
    addToInventoryCount(playerEntityId, PlayerObjectID, WoodenPickObjectID, 1);
    uint16 durability = 10;
    ItemMetadata.set(newInventoryId, durability);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    uint16 equippedDamage = 50;
    ObjectTypeMetadata.setDamage(WoodenPickObjectID, equippedDamage);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.equip(newInventoryId);
    assertTrue(Equipped.get(playerEntityId) == newInventoryId, "Equipped not set");

    player1HealthBefore = Health.getHealth(playerEntityId);
    player1StaminaBefore = Stamina.getStamina(playerEntityId);

    player2HealthBefore = Health.getHealth(playerEntityId2);
    player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    startGasReport("hit player with equipped");
    world.hit(bob);
    endGasReport();

    assertTrue(Health.getHealth(playerEntityId) == player1HealthBefore, "Player 1 health changed");
    assertTrue(
      Health.getHealth(playerEntityId2) == player2HealthBefore - equippedDamage,
      "Player 2 health did not decrease"
    );

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.stopPrank();
  }

  function testHitNonPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    assertTrue(Player.get(bob) == bytes32(0), "Player already exists");

    vm.expectRevert();
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);
    vm.stopPrank();

    vm.expectRevert();
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitSelf() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.expectRevert();
    world.hit(alice);

    vm.stopPrank();
  }

  function testHitTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(2);
    vm.startPrank(alice, alice);

    vm.expectRevert();
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitNotEnoughStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 0);
    Stamina.setLastUpdateBlock(playerEntityId, block.number);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    vm.expectRevert();
    world.hit(bob);

    vm.stopPrank();
  }

  function testHitFatal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);
    vm.startPrank(alice, alice);

    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    vm.startPrank(worldDeployer, worldDeployer);
    Health.setHealth(playerEntityId2, 1);
    Health.setLastUpdateBlock(playerEntityId2, block.number);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    startGasReport("hit player fatal");
    world.hit(bob);
    endGasReport();

    assertTrue(Stamina.getStamina(playerEntityId) < player1StaminaBefore, "Player 1 stamina did not decrease");

    assertTrue(Equipped.get(playerEntityId2) == bytes32(0), "Equipped not removed");
    assertTrue(Player.get(bob) == bytes32(0), "Player not removed from world");
    assertTrue(ObjectType.get(playerEntityId2) == AirObjectID, "Player object not removed");
    assertTrue(Health.getHealth(playerEntityId2) == 0, "Player health not reduced to 0");
    assertTrue(Stamina.getStamina(playerEntityId2) == 0, "Player stamina not reduced to 0");

    vm.stopPrank();
  }

  function testHitRegenHealthAndStamina() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);
    Stamina.setStamina(playerEntityId, 1);
    Stamina.setLastUpdateBlock(playerEntityId, block.number);

    Health.setHealth(playerEntityId, 1);
    Health.setLastUpdateBlock(playerEntityId, block.number);
    vm.stopPrank();

    vm.startPrank(alice, alice);

    uint256 newBlockNumber = block.number + BLOCKS_BEFORE_INCREASE_STAMINA + BLOCKS_BEFORE_INCREASE_HEALTH + 1;
    vm.roll(newBlockNumber);

    uint16 player1HealthBefore = Health.getHealth(playerEntityId);
    uint32 player1StaminaBefore = Stamina.getStamina(playerEntityId);

    uint16 player2HealthBefore = Health.getHealth(playerEntityId2);
    uint32 player2StaminaBefore = Stamina.getStamina(playerEntityId2);

    startGasReport("hit player w/ health and stamina regen");
    world.hit(bob);
    endGasReport();

    assertTrue(Health.getHealth(playerEntityId) > player1HealthBefore, "Player 1 health not changed");
    assertTrue(Health.getHealth(playerEntityId2) < player2HealthBefore, "Player 2 health did not decrease");
    assertTrue(Stamina.getStamina(playerEntityId2) == player2StaminaBefore, "Player 2 stamina changed");

    vm.stopPrank();
  }
}
