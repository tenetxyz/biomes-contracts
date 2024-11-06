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

import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { Recipes, RecipesData } from "../src/codegen/tables/Recipes.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { voxelCoordsAreEqual } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { positionDataToVoxelCoord, getTerrainObjectTypeId } from "../src/Utils.sol";
import { MAX_PLAYER_HEALTH, MAX_PLAYER_STAMINA, MAX_PLAYER_INFLUENCE_HALF_WIDTH, MAX_PLAYER_INVENTORY_SLOTS, TIME_BEFORE_INCREASE_STAMINA, TIME_BEFORE_INCREASE_HEALTH } from "../src/Constants.sol";
import { AirObjectID, PlayerObjectID, DiamondOreObjectID, WoodenPickObjectID, BedrockObjectID, NeptuniumCubeObjectID, ChipObjectID, TextSignObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "./utils/TestConstants.sol";
import { WORLD_BORDER_LOW_X, WORLD_BORDER_LOW_Y, WORLD_BORDER_LOW_Z, WORLD_BORDER_HIGH_X, WORLD_BORDER_HIGH_Y, WORLD_BORDER_HIGH_Z } from "../src/Constants.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testReverseInventoryToolHasItem, testInventoryObjectsHasObjectType } from "./utils/TestUtils.sol";
import { DisplayContent } from "../src/Types.sol";

import { IERC165 } from "@latticexyz/world/src/IERC165.sol";
import { IChip } from "../src/prototypes/IChip.sol";
import { IDisplayChip } from "../src/prototypes/IDisplayChip.sol";

contract TestDisplayChip is IDisplayChip {
  function onAttached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    return true;
  }

  function onDetached(
    bytes32 playerEntityId,
    bytes32 entityId,
    bytes memory extraData
  ) external payable returns (bool isAllowed) {
    return true;
  }

  function onPowered(bytes32 playerEntityId, bytes32 entityId, uint16 numBattery) external {}

  function onChipHit(bytes32 playerEntityId, bytes32 entityId) external {}

  function getDisplayContent(bytes32 entityId) external view returns (DisplayContent memory) {
    return DisplayContent({ contentType: 1, content: abi.encode("Hello, World!") });
  }

  function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
    return interfaceId == type(IDisplayChip).interfaceId || interfaceId == type(IERC165).interfaceId;
  }
}

contract DisplayTest is MudTest, GasReporter {
  IWorld private world;
  address payable internal worldDeployer;
  address payable internal alice;
  address payable internal bob;
  VoxelCoord spawnCoord;
  TestDisplayChip testDisplayChip;

  function setUp() public override {
    super.setUp();

    // Should match the value in .env during development
    worldDeployer = payable(address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266));
    alice = payable(address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8));
    bob = payable(address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC));
    world = IWorld(worldAddress);
    testDisplayChip = new TestDisplayChip();
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

  function testTextSign() public {
    vm.startPrank(alice, alice);

    bytes32 playerEntityId = setupPlayer();

    vm.startPrank(worldDeployer, worldDeployer);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, TextSignObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 1);
    assertTrue(InventorySlots.get(playerEntityId) == 2, "Inventory slot not set");
    vm.stopPrank();
    vm.startPrank(alice, alice);

    VoxelCoord memory buildCoord = VoxelCoord(spawnCoord.x, spawnCoord.y, spawnCoord.z - 1);
    assertTrue(world.getTerrainBlock(buildCoord) == AirObjectID, "Terrain block is not air");
    bytes32 buildEntityId = world.build(TextSignObjectID, buildCoord);

    assertTrue(
      voxelCoordsAreEqual(positionDataToVoxelCoord(Position.get(buildEntityId)), buildCoord),
      "Position not set"
    );
    assertTrue(
      ReversePosition.get(buildCoord.x, buildCoord.y, buildCoord.z) == buildEntityId,
      "Reverse position not set"
    );
    assertTrue(ObjectType.get(buildEntityId) == TextSignObjectID, "Object not built");
    assertTrue(!testInventoryObjectsHasObjectType(playerEntityId, TextSignObjectID), "Inventory objects not set");
    assertTrue(InventoryCount.get(playerEntityId, TextSignObjectID) == 0, "Inventory count not set");
    assertTrue(InventorySlots.get(playerEntityId) == 1, "Inventory slot not set");

    world.attachChip(buildEntityId, address(testDisplayChip));

    DisplayContent memory textSignContent = world.getDisplayContent(buildEntityId);
    assertTrue(textSignContent.contentType == 1, "Content type not set");
    assertTrue(keccak256(textSignContent.content) == keccak256(abi.encode("Hello, World!")), "Content not set");

    vm.stopPrank();
  }
}
