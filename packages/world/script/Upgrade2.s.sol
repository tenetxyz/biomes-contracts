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
    entityIds[0] = 0x0000000000000000000000000000000000000000000000000000000000033366;
    entityIds[1] = 0x0000000000000000000000000000000000000000000000000000000000076d34;
    entityIds[2] = 0x000000000000000000000000000000000000000000000000000000000003692d;
    entityIds[3] = 0x0000000000000000000000000000000000000000000000000000000000036076;
    entityIds[4] = 0x000000000000000000000000000000000000000000000000000000000002d8b8;
    entityIds[5] = 0x0000000000000000000000000000000000000000000000000000000000031cb2;
    entityIds[6] = 0x000000000000000000000000000000000000000000000000000000000003882d;
    entityIds[7] = 0x0000000000000000000000000000000000000000000000000000000000003153;
    entityIds[8] = 0x00000000000000000000000000000000000000000000000000000000000b2329;
    entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000006655a;
    entityIds[10] = 0x0000000000000000000000000000000000000000000000000000000000049719;
    entityIds[11] = 0x00000000000000000000000000000000000000000000000000000000000598cb;
    entityIds[12] = 0x000000000000000000000000000000000000000000000000000000000009d3dd;
    entityIds[13] = 0x000000000000000000000000000000000000000000000000000000000004ae69;
    entityIds[14] = 0x0000000000000000000000000000000000000000000000000000000000036968;
    entityIds[15] = 0x0000000000000000000000000000000000000000000000000000000000011888;
    entityIds[16] = 0x000000000000000000000000000000000000000000000000000000000005d0dd;
    entityIds[17] = 0x0000000000000000000000000000000000000000000000000000000000098897;
    entityIds[18] = 0x00000000000000000000000000000000000000000000000000000000000e3e52;
    entityIds[19] = 0x000000000000000000000000000000000000000000000000000000000005fae4;
    entityIds[20] = 0x0000000000000000000000000000000000000000000000000000000000004a45;
    entityIds[21] = 0x0000000000000000000000000000000000000000000000000000000000033be7;
    entityIds[22] = 0x00000000000000000000000000000000000000000000000000000000000553e2;
    entityIds[23] = 0x0000000000000000000000000000000000000000000000000000000000008d1a;
    entityIds[24] = 0x000000000000000000000000000000000000000000000000000000000006a8cf;
    entityIds[25] = 0x00000000000000000000000000000000000000000000000000000000000998db;
    entityIds[26] = 0x0000000000000000000000000000000000000000000000000000000000076a22;
    entityIds[27] = 0x0000000000000000000000000000000000000000000000000000000000030ce7;
    entityIds[28] = 0x000000000000000000000000000000000000000000000000000000000004a8c9;
    entityIds[29] = 0x000000000000000000000000000000000000000000000000000000000002eb6d;
    entityIds[30] = 0x0000000000000000000000000000000000000000000000000000000000030a6b;
    entityIds[31] = 0x000000000000000000000000000000000000000000000000000000000002d2c1;
    entityIds[32] = 0x000000000000000000000000000000000000000000000000000000000002e94d;
    entityIds[33] = 0x0000000000000000000000000000000000000000000000000000000000004080;
    entityIds[34] = 0x00000000000000000000000000000000000000000000000000000000000997bd;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      if (entityId == 0x00000000000000000000000000000000000000000000000000000000000b2329) {
        continue;
      }
      console.logBytes32(entityId);
      // require(Chip.getChipAddress(entityId) == 0xd8aF82d9634cDa04D72aA9C26D468bA884f8Be19, "Chip address not set");
      uint8 objectTypeId = ObjectType.get(entityId);
      require(objectTypeId != NullObjectTypeId, "Object type not set");
      uint16 currentBatteryCount = InventoryCount.get(entityId, ChipBatteryObjectID);
      // uint256 currentBatteryLevel = Chip.getBatteryLevel(entityId);
      uint16 addBatteries = currentBatteryCount / 2;
      if (addBatteries == 0) {
        continue;
      }
      testAddToInventoryCount(entityId, objectTypeId, ChipBatteryObjectID, addBatteries);
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
