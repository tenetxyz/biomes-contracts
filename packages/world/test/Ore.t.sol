// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import "forge-std/Test.sol";
import { IStore } from "@latticexyz/store/src/IStore.sol";
import { MudTest } from "@latticexyz/world/test/MudTest.t.sol";
import { GasReporter } from "@latticexyz/gas-report/src/GasReporter.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { BaseEntity } from "../src/codegen/tables/BaseEntity.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Health, HealthData } from "../src/codegen/tables/Health.sol";
import { Stamina, StaminaData } from "../src/codegen/tables/Stamina.sol";
import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { ExperiencePoints } from "../src/codegen/tables/ExperiencePoints.sol";
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { TerrainCommitment } from "../src/codegen/tables/TerrainCommitment.sol";
import { Commitment } from "../src/codegen/tables/Commitment.sol";
import { BlockHash } from "../src/codegen/tables/BlockHash.sol";
import { BlockPrevrandao } from "../src/codegen/tables/BlockPrevrandao.sol";

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, GrassObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, NeptuniumCubeObjectID, TextSignObjectID, AnyOreObjectID, LavaObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";

contract OreTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;
  VoxelCoord spawnCoord2;
  VoxelCoord oreCoord;
  VoxelCoord oreCoord2;
  VoxelCoord lavaOreCoord;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
    oreCoord = VoxelCoord(-127, 27, -625);
    oreCoord2 = VoxelCoord(-189, 37, -574);
    lavaOreCoord = VoxelCoord(-250, 58, -583);
  }

  function setupPlayer() public returns (bytes32) {
    spawnCoord = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z);
    assertTrue(world.getTerrainBlock(spawnCoord) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId = world.spawnPlayer(spawnCoord);

    // move player outside spawn
    VoxelCoord[] memory path = new VoxelCoord[](2);
    path[0] = VoxelCoord(spawnCoord.x - 1, spawnCoord.y - 1, spawnCoord.z - 1);
    path[1] = VoxelCoord(path[0].x - 1, path[0].y - 1, path[0].z);
    world.move(path);

    spawnCoord = path[1];

    return playerEntityId;
  }

  function setupPlayer2(int16 zOffset) public returns (bytes32) {
    vm.startPrank(bob, bob);
    spawnCoord2 = VoxelCoord(SPAWN_LOW_X, SPAWN_GROUND_Y + 1, SPAWN_LOW_Z + zOffset);
    assertTrue(world.getTerrainBlock(spawnCoord2) == AirObjectID, "Terrain block is not air");
    bytes32 playerEntityId2 = world.spawnPlayer(spawnCoord2);

    VoxelCoord[] memory path = new VoxelCoord[](1);
    path[0] = VoxelCoord(spawnCoord2.x - 1, spawnCoord2.y - 1, spawnCoord2.z - 1);
    world.move(path);

    spawnCoord2 = path[0];

    vm.stopPrank();
    return playerEntityId2;
  }

  function testMineOre() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    startGasReport("commit ore");
    world.commitOre(oreCoord);
    endGasReport();

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.roll(block.number + 1);
    startGasReport("reveal ore");
    world.revealOre(oreCoord);
    endGasReport();

    bytes32 mineEntityId = ReversePosition.get(oreCoord.x, oreCoord.y, oreCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Entity id not set");
    uint8 oreObjectTypeId = ObjectType.get(mineEntityId);
    assertTrue(oreObjectTypeId != AnyOreObjectID, "Object type not set");

    // commitments cleared
    assertTrue(TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == 0, "Ore commitment not cleared");
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == bytes32(0),
      "Ore committer not cleared"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId) == false, "Commitment not cleared");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    world.mine(oreCoord);

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(InventoryCount.get(playerEntityId, oreObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, oreObjectTypeId), "Inventory objects not set");
    assertTrue(Stamina.getStamina(playerEntityId) < staminaBefore, "Stamina not decremented");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testMineOreLava() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(lavaOreCoord.x + 1, lavaOreCoord.y - 2, lavaOreCoord.z);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(lavaOreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.prevrandao(bytes32(uint256(40)));
    world.commitOre(lavaOreCoord);

    uint256 commitBlockNumber = block.number;
    assertTrue(
      TerrainCommitment.getBlockNumber(lavaOreCoord.x, lavaOreCoord.y, lavaOreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(lavaOreCoord.x, lavaOreCoord.y, lavaOreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == lavaOreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == lavaOreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == lavaOreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.roll(block.number + 10000);

    vm.startPrank(worldDeployer, worldDeployer);
    world.setBlockHash(commitBlockNumber, bytes32(uint256(99)));
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.revealOre(lavaOreCoord);

    assertTrue(Stamina.getStamina(playerEntityId) == 0, "Stamina not set");

    bytes32 mineEntityId = ReversePosition.get(lavaOreCoord.x, lavaOreCoord.y, lavaOreCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Entity id not set");
    uint8 oreObjectTypeId = ObjectType.get(mineEntityId);
    assertTrue(oreObjectTypeId == LavaObjectID, "Object type not set");

    // commitments cleared
    assertTrue(
      TerrainCommitment.getBlockNumber(lavaOreCoord.x, lavaOreCoord.y, lavaOreCoord.z) == 0,
      "Ore commitment not cleared"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(lavaOreCoord.x, lavaOreCoord.y, lavaOreCoord.z) == bytes32(0),
      "Ore committer not cleared"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId) == false, "Commitment not cleared");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
  }

  function testMineOreWithDifferentRevealer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    world.commitOre(oreCoord);

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(bob, bob);
    vm.roll(block.number + 1);
    world.revealOre(oreCoord);
    vm.stopPrank();
    vm.startPrank(alice, alice);

    bytes32 mineEntityId = ReversePosition.get(oreCoord.x, oreCoord.y, oreCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Entity id not set");
    uint8 oreObjectTypeId = ObjectType.get(mineEntityId);
    assertTrue(oreObjectTypeId != AnyOreObjectID, "Object type not set");

    // commitments cleared
    assertTrue(TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == 0, "Ore commitment not cleared");
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == bytes32(0),
      "Ore committer not cleared"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId) == false, "Commitment not cleared");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    world.mine(oreCoord);

    assertTrue(ObjectType.get(mineEntityId) == AirObjectID, "Object not mined");
    assertTrue(InventoryCount.get(playerEntityId, oreObjectTypeId) == 1, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");
    assertTrue(testInventoryObjectsHasObjectType(playerEntityId, oreObjectTypeId), "Inventory objects not set");
    assertTrue(Stamina.getStamina(playerEntityId) < staminaBefore, "Stamina not decremented");
    assertTrue(Stamina.getLastUpdatedTime(playerEntityId) == block.timestamp, "Stamina last update time not set");

    vm.stopPrank();
  }

  function testMineOreWithoutReveal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    vm.expectRevert("MineSystem: ore must be computed before it can be mined");
    world.mine(oreCoord);

    vm.stopPrank();
  }

  function testMineOreWithCommitWithoutReveal() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    VoxelCoord memory finalCoord2 = VoxelCoord(oreCoord.x + 2, oreCoord.y, oreCoord.z + 2);
    bytes32 finalEntityId2 = testGetUniqueEntity();
    ObjectType.set(finalEntityId2, AirObjectID);

    ReversePosition.set(spawnCoord2.x, spawnCoord2.y, spawnCoord2.z, finalEntityId2);
    Position.set(finalEntityId2, spawnCoord2.x, spawnCoord2.y, spawnCoord2.z);

    Position.set(playerEntityId2, finalCoord2.x, finalCoord2.y, finalCoord2.z);
    ReversePosition.set(finalCoord2.x, finalCoord2.y, finalCoord2.z, playerEntityId2);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    world.commitOre(oreCoord);

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(bob, bob);

    vm.expectRevert("MineSystem: ore must be computed before it can be mined");
    world.mine(oreCoord);

    vm.stopPrank();
  }

  function testCommitOreInACommitment() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, GrassObjectID, 2);
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    world.commitOre(oreCoord);

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord2 = VoxelCoord(oreCoord2.x - 1, oreCoord2.y, oreCoord2.z - 1);
    finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, finalEntityId);
    Position.set(finalEntityId, finalCoord.x, finalCoord.y, finalCoord.z);

    Position.set(playerEntityId, finalCoord2.x, finalCoord2.y, finalCoord2.z);
    ReversePosition.set(finalCoord2.x, finalCoord2.y, finalCoord2.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    vm.expectRevert("Player is in a commitment");
    world.commitOre(oreCoord2);

    vm.expectRevert("Player is in a commitment");
    world.mine(VoxelCoord(oreCoord.x, oreCoord.y - 1, oreCoord.z));

    VoxelCoord[] memory newCoords = new VoxelCoord[](1);
    newCoords[0] = VoxelCoord(finalCoord.x, finalCoord.y, finalCoord.z + 1);

    vm.expectRevert("Player is in a commitment");
    world.move(newCoords);

    vm.expectRevert("Player is in a commitment");
    world.logoffPlayer();

    vm.expectRevert("Player is in a commitment");
    world.build(GrassObjectID, VoxelCoord(finalCoord.x, finalCoord.y, finalCoord.z + 1));

    vm.stopPrank();
  }

  function testCommitOreAlreadyCommitment() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();
    bytes32 playerEntityId2 = setupPlayer2(1);

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    VoxelCoord memory finalCoord2 = VoxelCoord(oreCoord.x + 2, oreCoord.y, oreCoord.z + 2);
    bytes32 finalEntityId2 = testGetUniqueEntity();
    ObjectType.set(finalEntityId2, AirObjectID);

    ReversePosition.set(spawnCoord2.x, spawnCoord2.y, spawnCoord2.z, finalEntityId2);
    Position.set(finalEntityId2, spawnCoord2.x, spawnCoord2.y, spawnCoord2.z);

    Position.set(playerEntityId2, finalCoord2.x, finalCoord2.y, finalCoord2.z);
    ReversePosition.set(finalCoord2.x, finalCoord2.y, finalCoord2.z, playerEntityId2);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    world.commitOre(oreCoord);

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
    vm.startPrank(bob, bob);

    vm.expectRevert("OreSystem: terrain commitment already committed");
    world.commitOre(oreCoord);

    vm.stopPrank();
  }

  function testCommitOreAlreadyRevealed() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    world.commitOre(oreCoord);

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.roll(block.number + 1);
    world.revealOre(oreCoord);

    bytes32 mineEntityId = ReversePosition.get(oreCoord.x, oreCoord.y, oreCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Entity id not set");
    uint8 oreObjectTypeId = ObjectType.get(mineEntityId);
    assertTrue(oreObjectTypeId != AnyOreObjectID, "Object type not set");

    // commitments cleared
    assertTrue(TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == 0, "Ore commitment not cleared");
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == bytes32(0),
      "Ore committer not cleared"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId) == false, "Commitment not cleared");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    uint32 staminaBefore = Stamina.getStamina(playerEntityId);

    vm.expectRevert("OreSystem: ore already revealed");
    world.commitOre(oreCoord);

    vm.stopPrank();
  }

  function testCommitOreNonOre() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory mineCoord = VoxelCoord(oreCoord.x, oreCoord.y - 1, oreCoord.z);
    uint8 terrainObjectTypeId = world.getTerrainBlock(mineCoord);
    assertTrue(terrainObjectTypeId != AnyOreObjectID, "Terrain block is not an ore");

    vm.expectRevert("OreSystem: terrain is not an ore");
    world.commitOre(mineCoord);

    vm.stopPrank();
  }

  function testCommitOreWithoutPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    vm.stopPrank();

    vm.expectRevert("Player does not exist");
    world.commitOre(oreCoord);

    vm.stopPrank();
  }

  function testCommitOreTooFar() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    vm.expectRevert("Player is too far");
    world.commitOre(oreCoord);

    vm.stopPrank();
  }

  function testCommitOreWithLoggedOffPlayer() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    world.logoffPlayer();

    vm.expectRevert("Player isn't logged in");
    world.commitOre(oreCoord);

    vm.stopPrank();
  }

  function testRevealOreNotComitted() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    vm.expectRevert("OreSystem: terrain commitment not found");
    world.revealOre(oreCoord);

    vm.stopPrank();
  }

  function testRevealOrePastBlockHashWindow() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);

    VoxelCoord memory finalCoord = VoxelCoord(oreCoord.x + 1, oreCoord.y, oreCoord.z + 1);
    bytes32 finalEntityId = testGetUniqueEntity();
    ObjectType.set(finalEntityId, AirObjectID);

    ReversePosition.set(spawnCoord.x, spawnCoord.y, spawnCoord.z, finalEntityId);
    Position.set(finalEntityId, spawnCoord.x, spawnCoord.y, spawnCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopPrank();
    vm.startPrank(alice, alice);

    uint8 terrainObjectTypeId = world.getTerrainBlock(oreCoord);
    assertTrue(terrainObjectTypeId == AnyOreObjectID, "Terrain block is not an ore");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    world.commitOre(oreCoord);

    uint256 commitBlockNumber = block.number;

    assertTrue(
      TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == block.number,
      "Ore not committed"
    );
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == playerEntityId,
      "Ore not committed by player"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId), "Commitment not set");
    assertTrue(Commitment.getX(playerEntityId) == oreCoord.x, "X not set");
    assertTrue(Commitment.getY(playerEntityId) == oreCoord.y, "Y not set");
    assertTrue(Commitment.getZ(playerEntityId) == oreCoord.z, "Z not set");

    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.roll(block.number + 10000);

    vm.expectRevert();
    world.revealOre(oreCoord);

    vm.startPrank(worldDeployer, worldDeployer);
    world.setBlockHash(commitBlockNumber, bytes32(uint256(10)));
    vm.stopPrank();
    vm.startPrank(alice, alice);

    world.revealOre(oreCoord);

    bytes32 mineEntityId = ReversePosition.get(oreCoord.x, oreCoord.y, oreCoord.z);
    assertTrue(mineEntityId != bytes32(0), "Entity id not set");
    uint8 oreObjectTypeId = ObjectType.get(mineEntityId);
    assertTrue(oreObjectTypeId != AnyOreObjectID, "Object type not set");

    // commitments cleared
    assertTrue(TerrainCommitment.getBlockNumber(oreCoord.x, oreCoord.y, oreCoord.z) == 0, "Ore commitment not cleared");
    assertTrue(
      TerrainCommitment.getCommitterEntityId(oreCoord.x, oreCoord.y, oreCoord.z) == bytes32(0),
      "Ore committer not cleared"
    );
    assertTrue(Commitment.getHasCommitted(playerEntityId) == false, "Commitment not cleared");
    assertTrue(InventorySlots.get(playerEntityId) == 0, "Inventory slot not set");

    vm.stopPrank();
  }
}
