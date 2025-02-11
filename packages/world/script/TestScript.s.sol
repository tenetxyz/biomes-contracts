// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
import { InventoryTool } from "../src/codegen/tables/InventoryTool.sol";
import { ReverseInventoryTool } from "../src/codegen/tables/ReverseInventoryTool.sol";
import { InventorySlots } from "../src/codegen/tables/InventorySlots.sol";
import { InventoryCount } from "../src/codegen/tables/InventoryCount.sol";
import { InventoryObjects } from "../src/codegen/tables/InventoryObjects.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { Mass } from "../src/codegen/tables/Mass.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { GrassObjectID, DirtObjectID, OakLogObjectID, StoneObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, NeptuniumPickObjectID, SandObjectID, AirObjectID, ChipObjectID, ChipBatteryObjectID, ForceFieldObjectID, ReinforcedOakLumberObjectID, ReinforcedBirchLumberObjectID, ReinforcedRubberLumberObjectID, BedrockObjectID, OakLumberObjectID, SilverBarObjectID, SilverPickObjectID, CobblestoneBrickObjectID, DyeomaticObjectID, CoalOreObjectID, PlayerObjectID, WoodenPickObjectID, ChestObjectID, SmartChestObjectID, TextSignObjectID, SmartTextSignObjectID, PipeObjectID } from "../src/ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID, BlueGlassObjectID, PowerStoneObjectID } from "../src/ObjectTypeIds.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testRemoveFromInventoryCount, testRemoveEntityIdFromReverseInventoryTool } from "../test/utils/TestUtils.sol";

contract TestScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    bytes32 playerEntityId = Player.get(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    require(playerEntityId != bytes32(0), "Player entity not found");
    // testRemoveFromInventoryCount(playerEntityId, 162, 10);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BedrockObjectID, 4);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipObjectID, 10);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChipBatteryObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ForceFieldObjectID, 2);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, TextSignObjectID, 15);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartTextSignObjectID, 15);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PipeObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, PowerStoneObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, OakLogObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, ChestObjectID, 1);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SmartChestObjectID, 4);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, BlueGlassObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, CoalOreObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SilverBarObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, SandObjectID, 99);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, StoneObjectID, 99);

    bytes32 newInventoryEntityId = testGetUniqueEntity();
    ObjectType.set(newInventoryEntityId, NeptuniumPickObjectID);
    InventoryTool.set(newInventoryEntityId, playerEntityId);
    ReverseInventoryTool.push(playerEntityId, newInventoryEntityId);
    uint128 mass = ObjectTypeMetadata.getMass(NeptuniumPickObjectID);
    require(mass > 0, "Mass must be greater than 0");
    Mass.setMass(newInventoryEntityId, mass);
    testAddToInventoryCount(playerEntityId, PlayerObjectID, NeptuniumPickObjectID, 1);

    // Destroy equipped item
    // bytes32 inventoryEntityId = 0x000000000000000000000000000000000000000000000000000000000004bbb3;
    // testRemoveFromInventoryCount(playerEntityId, NeptuniumPickObjectID, 1);
    // Mass.deleteRecord(inventoryEntityId);
    // InventoryTool.deleteRecord(inventoryEntityId);
    // testRemoveEntityIdFromReverseInventoryTool(playerEntityId, inventoryEntityId);
    // Equipped.deleteRecord(playerEntityId);

    vm.stopBroadcast();
  }
}
