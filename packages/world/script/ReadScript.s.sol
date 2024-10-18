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
import { ItemMetadata } from "../src/codegen/tables/ItemMetadata.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { Health } from "../src/codegen/tables/Health.sol";
import { Stamina } from "../src/codegen/tables/Stamina.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerMetadata } from "../src/codegen/tables/PlayerMetadata.sol";
import { Position, PositionData } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { ShardField } from "../src/codegen/tables/ShardField.sol";

import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { coordToShardCoord } from "@biomesaw/utils/src/VoxelCoordUtils.sol";
import { GrassObjectID, DirtObjectID, OakLogObjectID, StoneObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, NeptuniumPickObjectID, SandObjectID, AirObjectID, ChipObjectID, ChipBatteryObjectID, ForceFieldObjectID, ReinforcedOakLumberObjectID, ReinforcedBirchLumberObjectID, ReinforcedRubberLumberObjectID, BedrockObjectID, OakLumberObjectID, SilverBarObjectID, SilverPickObjectID, CobblestoneBrickObjectID, DyeomaticObjectID, CoalOreObjectID, PlayerObjectID, WoodenPickObjectID, ChestObjectID } from "../src/ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID, BlueGlassObjectID, PowerStoneObjectID } from "../src/ObjectTypeIds.sol";
import { addToInventoryCount } from "../src/utils/InventoryUtils.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testRemoveFromInventoryCount, testRemoveEntityIdFromReverseInventoryTool } from "../test/utils/TestUtils.sol";
import { FORCE_FIELD_SHARD_DIM } from "../src/Constants.sol";

contract ReadScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    VoxelCoord memory coord = VoxelCoord(-18, 6, -524);
    VoxelCoord memory shardCoord = coordToShardCoord(coord, FORCE_FIELD_SHARD_DIM);
    bytes32 forceFieldEntityId = ShardField.get(shardCoord.x, shardCoord.y, shardCoord.z);
    require(forceFieldEntityId != bytes32(0), "Force field not found");
    PositionData memory positionData = Position.get(forceFieldEntityId);
    console.log("Force field position:");
    console.logBytes32(forceFieldEntityId);
    console.logInt(positionData.x);
    console.logInt(positionData.y);
    console.logInt(positionData.z);

    vm.stopBroadcast();
  }
}
