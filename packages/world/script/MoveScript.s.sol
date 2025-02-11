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
import { Player } from "../src/codegen/tables/Player.sol";
import { Equipped } from "../src/codegen/tables/Equipped.sol";
import { ReversePlayer } from "../src/codegen/tables/ReversePlayer.sol";
import { PlayerStatus } from "../src/codegen/tables/PlayerStatus.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";
import { LastKnownPosition } from "../src/codegen/tables/LastKnownPosition.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Chip } from "../src/codegen/tables/Chip.sol";
import { VoxelCoord } from "../src/Types.sol";
import { EntityId } from "../src/EntityId.sol";
import { WaterObjectID, GrassObjectID, DirtObjectID, OakLogObjectID, StoneObjectID, BirchLogObjectID, SakuraLogObjectID, RubberLogObjectID, SandObjectID, AirObjectID, ChipObjectID, ChipBatteryObjectID, ForceFieldObjectID, ReinforcedOakLumberObjectID, ReinforcedBirchLumberObjectID, ReinforcedRubberLumberObjectID, BedrockObjectID, OakLumberObjectID, SilverBarObjectID, SilverPickObjectID, CobblestoneBrickObjectID, DyeomaticObjectID, CoalOreObjectID, PlayerObjectID, WoodenPickObjectID, ChestObjectID } from "../src/ObjectTypeIds.sol";
import { CactusObjectID, LilacObjectID, DandelionObjectID, RedMushroomObjectID, BellflowerObjectID, CottonBushObjectID, SwitchGrassObjectID, DaylilyObjectID, AzaleaObjectID, RoseObjectID, BlueGlassObjectID } from "../src/ObjectTypeIds.sol";
import { positionDataToVoxelCoord } from "../src/Utils.sol";
import { testTransferAllInventoryEntities, testGravityApplies } from "../test/utils/TestUtils.sol";

contract MoveScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    EntityId playerEntityId = Player.get(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    VoxelCoord memory finalCoord = VoxelCoord(-604, -44, -754);

    require(playerEntityId.exists(), "Player entity not found");
    EntityId finalEntityId = ReversePosition.get(finalCoord.x, finalCoord.y, finalCoord.z);
    require(finalEntityId.exists(), "Cannot move to unrevealed block");
    require(ObjectType.get(finalEntityId) == AirObjectID, "Cannot move to non-air block");
    testTransferAllInventoryEntities(finalEntityId, playerEntityId, PlayerObjectID);
    require(!testGravityApplies(finalCoord), "Gravity applies to player");

    if (PlayerStatus.getIsLoggedOff(playerEntityId)) {
      LastKnownPosition.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
    } else {
      VoxelCoord memory playerCoord = positionDataToVoxelCoord(Position.get(playerEntityId));

      ReversePosition.set(playerCoord.x, playerCoord.y, playerCoord.z, finalEntityId);
      Position.set(finalEntityId, playerCoord.x, playerCoord.y, playerCoord.z);

      Position.set(playerEntityId, finalCoord.x, finalCoord.y, finalCoord.z);
      ReversePosition.set(finalCoord.x, finalCoord.y, finalCoord.z, playerEntityId);
    }

    vm.stopBroadcast();
  }
}
