// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
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
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { WaterObjectID, GrassObjectID, DirtObjectID, OakLogObjectID, StoneObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, SandObjectID, AirObjectID, ChipObjectID, ChipBatteryObjectID, ForceFieldObjectID, ReinforcedOakLumberObjectID, ReinforcedBirchLumberObjectID, ReinforcedRubberLumberObjectID, BedrockObjectID, OakLumberObjectID, SilverBarObjectID, SilverPickObjectID, CobblestoneBrickObjectID, DyeomaticObjectID, CoalOreObjectID, PlayerObjectID, WoodenPickObjectID, ChestObjectID } from "../src/ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID, BlueGlassObjectID } from "../src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { testGetUniqueEntity, testAddToInventoryCount, testRemoveFromInventoryCount, testTransferAllInventoryEntities, testGravityApplies, testGetTerrainObjectTypeId } from "../test/utils/TestUtils.sol";

contract MoveScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    bytes32 playerEntityId = Player.get(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    VoxelCoord memory finalCoord = VoxelCoord(23, 4, -151);

    require(playerEntityId != bytes32(0), "Player entity not found");
    require(!PlayerMetadata.getIsLoggedOff(playerEntityId), "Player isn't logged in");
    VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position.get(playerEntityId));
    bytes32 finalEntityId = ReversePosition.get(finalCoord.x, finalCoord.y, finalCoord.z);
    if (finalEntityId == bytes32(0)) {
      // Check terrain block type
      uint8 terrainObjectTypeId = testGetTerrainObjectTypeId(finalCoord);
      require(
        terrainObjectTypeId == AirObjectID || terrainObjectTypeId == WaterObjectID,
        "MoveSystem: cannot move to non-air block"
      );
      finalEntityId = testGetUniqueEntity();
      ObjectType.set(finalEntityId, AirObjectID);
    } else {
      require(ObjectType.get(finalEntityId) == AirObjectID, "MoveSystem: cannot move to non-air block");
      testTransferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);
    }
    require(!testGravityApplies(finalCoord), "MoveSystem: gravity applies to player");

    ReversePosition.set(playerCoord.x, playerCoord.y, playerCoord.z, finalEntityId);
    Position.set(finalEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

    Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);

    vm.stopBroadcast();
  }
}
