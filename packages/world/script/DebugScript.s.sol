// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { ResourceId, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { SystemRegistry } from "@latticexyz/world/src/codegen/tables/SystemRegistry.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";
import { FunctionSelectors } from "@latticexyz/world/src/codegen/tables/FunctionSelectors.sol";
import { Bytes } from "@latticexyz/store/src/Bytes.sol";
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

import { IGravitySystem } from "../src/codegen/world/IGravitySystem.sol";

contract ReadScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    bytes32 playerEntityId = 0x0000000000000000000000000000000000000000000000000000000000001411;
    VoxelCoord memory playerCoord = VoxelCoord(-20, 23, -259);
    bytes memory callData = abi.encodeCall(IGravitySystem.runGravity, (playerEntityId, playerCoord));
    console.log("callData");
    console.logBytes(callData);

    (ResourceId systemId, bytes4 systemFunctionSelector) = FunctionSelectors.get(bytes4(callData));
    (address systemAddress, ) = Systems.get(systemId);

    console.log("systemFunctionSelector");
    console.logBytes4(systemFunctionSelector);

    bytes memory modifiedCallData = Bytes.setBytes4(callData, 0, systemFunctionSelector);
    console.log("modifiedCallData");
    console.logBytes(modifiedCallData);

    vm.stopBroadcast();
  }
}
