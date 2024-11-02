// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

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

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Unstable_CallWithSignatureSystem } from "@latticexyz/world-modules/src/modules/callwithsignature/Unstable_CallWithSignatureSystem.sol";
import { DELEGATION_SYSTEM_ID } from "@latticexyz/world-modules/src/modules/callwithsignature/constants.sol";
import { ChestMetadata, ChestMetadataData } from "../src/codegen/tables/ChestMetadata.sol";
import { testRemoveFromInventoryCount, testAddToInventoryCount } from "../test/utils/TestUtils.sol";
import { NullObjectTypeId, ChestObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChipBatteryObjectID, ForceFieldObjectID } from "../src/ObjectTypeIds.sol";

contract Upgrade2 is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // Unstable_CallWithSignatureSystem newUpgradedSystem = new Unstable_CallWithSignatureSystem();
    // IWorld(worldAddress).registerSystem(DELEGATION_SYSTEM_ID, newUpgradedSystem, true);

    bytes32[] memory entityIds = new bytes32[](35);
    uint16[] memory entityCounts = new uint16[](35);
    entityIds[0] = 0x0000000000000000000000000000000000000000000000000000000000033366;
    entityCounts[0] = 1;
    entityIds[1] = 0x0000000000000000000000000000000000000000000000000000000000076d34;
    entityCounts[1] = 1;
    entityIds[2] = 0x000000000000000000000000000000000000000000000000000000000003692d;
    entityCounts[2] = 1;
    entityIds[3] = 0x0000000000000000000000000000000000000000000000000000000000036076;
    entityCounts[3] = 7;
    entityIds[4] = 0x000000000000000000000000000000000000000000000000000000000002d8b8;
    entityCounts[4] = 1;
    entityIds[5] = 0x0000000000000000000000000000000000000000000000000000000000031cb2;
    entityCounts[5] = 1;
    entityIds[6] = 0x000000000000000000000000000000000000000000000000000000000003882d;
    entityCounts[6] = 7;
    entityIds[7] = 0x0000000000000000000000000000000000000000000000000000000000003153;
    entityCounts[7] = 51;
    entityIds[8] = 0x00000000000000000000000000000000000000000000000000000000000b2329;
    entityCounts[8] = 396;
    entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000006655a;
    entityCounts[9] = 1;
    entityIds[10] = 0x0000000000000000000000000000000000000000000000000000000000049719;
    entityCounts[10] = 7;
    entityIds[11] = 0x00000000000000000000000000000000000000000000000000000000000598cb;
    entityCounts[11] = 1;
    entityIds[12] = 0x000000000000000000000000000000000000000000000000000000000009d3dd;
    entityCounts[12] = 6;
    entityIds[13] = 0x000000000000000000000000000000000000000000000000000000000004ae69;
    entityCounts[13] = 1;
    entityIds[14] = 0x0000000000000000000000000000000000000000000000000000000000036968;
    entityCounts[14] = 1;
    entityIds[15] = 0x0000000000000000000000000000000000000000000000000000000000011888;
    entityCounts[15] = 1;
    entityIds[16] = 0x000000000000000000000000000000000000000000000000000000000005d0dd;
    entityCounts[16] = 4;
    entityIds[17] = 0x0000000000000000000000000000000000000000000000000000000000098897;
    entityCounts[17] = 1;
    entityIds[18] = 0x00000000000000000000000000000000000000000000000000000000000e3e52;
    entityCounts[18] = 1;
    entityIds[19] = 0x000000000000000000000000000000000000000000000000000000000005fae4;
    entityCounts[19] = 2;
    entityIds[20] = 0x0000000000000000000000000000000000000000000000000000000000004a45;
    entityCounts[20] = 198;
    entityIds[21] = 0x0000000000000000000000000000000000000000000000000000000000033be7;
    entityCounts[21] = 1;
    entityIds[22] = 0x00000000000000000000000000000000000000000000000000000000000553e2;
    entityCounts[22] = 1;
    entityIds[23] = 0x0000000000000000000000000000000000000000000000000000000000008d1a;
    entityCounts[23] = 34;
    entityIds[24] = 0x000000000000000000000000000000000000000000000000000000000006a8cf;
    entityCounts[24] = 1;
    entityIds[25] = 0x00000000000000000000000000000000000000000000000000000000000998db;
    entityCounts[25] = 1;
    entityIds[26] = 0x0000000000000000000000000000000000000000000000000000000000076a22;
    entityCounts[26] = 1;
    entityIds[27] = 0x0000000000000000000000000000000000000000000000000000000000030ce7;
    entityCounts[27] = 4;
    entityIds[28] = 0x000000000000000000000000000000000000000000000000000000000004a8c9;
    entityCounts[28] = 1;
    entityIds[29] = 0x000000000000000000000000000000000000000000000000000000000002eb6d;
    entityCounts[29] = 13;
    entityIds[30] = 0x0000000000000000000000000000000000000000000000000000000000030a6b;
    entityCounts[30] = 5;
    entityIds[31] = 0x000000000000000000000000000000000000000000000000000000000002d2c1;
    entityCounts[31] = 64;
    entityIds[32] = 0x000000000000000000000000000000000000000000000000000000000002e94d;
    entityCounts[32] = 787;
    entityIds[33] = 0x0000000000000000000000000000000000000000000000000000000000004080;
    entityCounts[33] = 2;
    entityIds[34] = 0x00000000000000000000000000000000000000000000000000000000000997bd;
    entityCounts[34] = 3;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      if (
        entityId == 0x00000000000000000000000000000000000000000000000000000000000b2329 ||
        entityId == 0x000000000000000000000000000000000000000000000000000000000002e94d
      ) {
        continue;
      }
      console.logBytes32(entityId);
      // require(Chip.getChipAddress(entityId) == 0xd8aF82d9634cDa04D72aA9C26D468bA884f8Be19, "Chip address not set");
      uint8 objectTypeId = ObjectType.get(entityId);
      require(objectTypeId != NullObjectTypeId, "Object type not set");
      // uint16 currentBatteryCount = InventoryCount.get(entityId, ChipBatteryObjectID);
      // uint256 currentBatteryLevel = Chip.getBatteryLevel(entityId);
      uint16 currentBatteryCount = entityCounts[i];
      require(currentBatteryCount > 0, "Battery count is 0");
      uint16 gaveLastTime = currentBatteryCount / 2;
      uint16 giveNow = currentBatteryCount - gaveLastTime;
      require(giveNow > 0, "Give now is 0");
      console.logUint(giveNow);
      testAddToInventoryCount(entityId, objectTypeId, ChipBatteryObjectID, giveNow);
      // Chip.setBatteryLevel(entityId, currentBatteryLevel * 2);
    }

    // for (uint i = 0; i < entityIds.length; i++) {
    //   bytes32 entityId = entityIds[i];
    //   uint8 objectTypeId = ObjectType.get(entityId);
    //   require(objectTypeId != NullObjectTypeId);
    //   uint16 numReinforcedChest = InventoryCount.get(entityId, 162);
    //   console.log("numReinforcedChest");
    //   console.logUint(numReinforcedChest);
    //   if (numReinforcedChest > 0) {
    //     testRemoveFromInventoryCount(entityId, 162, numReinforcedChest);
    //     testAddToInventoryCount(entityId, objectTypeId, ChestObjectID, numReinforcedChest);
    //     testAddToInventoryCount(entityId, objectTypeId, BedrockObjectID, numReinforcedChest);
    //   }

    //   uint16 numBedrockChest = InventoryCount.get(entityId, 163);
    //   console.log("numBedrockChest");
    //   console.logUint(numBedrockChest);
    //   if (numBedrockChest > 0) {
    //     testRemoveFromInventoryCount(entityId, 163, numBedrockChest);
    //     testAddToInventoryCount(entityId, objectTypeId, ChestObjectID, numReinforcedChest);
    //     testAddToInventoryCount(entityId, objectTypeId, ReinforcedOakLumberObjectID, numReinforcedChest);
    //   }
    // }

    vm.stopBroadcast();
  }
}
