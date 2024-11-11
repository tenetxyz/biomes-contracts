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

    bytes32[] memory entityIds = new bytes32[](66);
    entityIds[0] = 0x000000000000000000000000000000000000000000000000000000000004d5fd;
    entityIds[1] = 0x000000000000000000000000000000000000000000000000000000000004d5fe;
    entityIds[2] = 0x000000000000000000000000000000000000000000000000000000000004d5ff;
    entityIds[3] = 0x000000000000000000000000000000000000000000000000000000000004d600;
    entityIds[4] = 0x000000000000000000000000000000000000000000000000000000000004d605;
    entityIds[5] = 0x000000000000000000000000000000000000000000000000000000000004d60a;
    entityIds[6] = 0x000000000000000000000000000000000000000000000000000000000004d60b;
    entityIds[7] = 0x000000000000000000000000000000000000000000000000000000000004d60c;
    entityIds[8] = 0x000000000000000000000000000000000000000000000000000000000004d60d;
    entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000004d613;
    entityIds[10] = 0x000000000000000000000000000000000000000000000000000000000004d614;
    entityIds[11] = 0x000000000000000000000000000000000000000000000000000000000004d615;
    entityIds[12] = 0x000000000000000000000000000000000000000000000000000000000004d616;
    entityIds[13] = 0x000000000000000000000000000000000000000000000000000000000004d61b;
    entityIds[14] = 0x000000000000000000000000000000000000000000000000000000000004d620;
    entityIds[15] = 0x000000000000000000000000000000000000000000000000000000000004d621;
    entityIds[16] = 0x000000000000000000000000000000000000000000000000000000000004d622;
    entityIds[17] = 0x000000000000000000000000000000000000000000000000000000000004d623;
    entityIds[18] = 0x000000000000000000000000000000000000000000000000000000000004ddab;
    entityIds[19] = 0x000000000000000000000000000000000000000000000000000000000004ddac;
    entityIds[20] = 0x000000000000000000000000000000000000000000000000000000000004ddad;
    entityIds[21] = 0x000000000000000000000000000000000000000000000000000000000004ddaf;
    entityIds[22] = 0x000000000000000000000000000000000000000000000000000000000004ddb0;
    entityIds[23] = 0x000000000000000000000000000000000000000000000000000000000004ddb1;
    entityIds[24] = 0x000000000000000000000000000000000000000000000000000000000004ddb6;
    entityIds[25] = 0x000000000000000000000000000000000000000000000000000000000004ddbb;
    entityIds[26] = 0x000000000000000000000000000000000000000000000000000000000004ddbc;
    entityIds[27] = 0x000000000000000000000000000000000000000000000000000000000004ddbe;
    entityIds[28] = 0x000000000000000000000000000000000000000000000000000000000004ddc0;
    entityIds[29] = 0x000000000000000000000000000000000000000000000000000000000004ddc5;
    entityIds[30] = 0x000000000000000000000000000000000000000000000000000000000004ddc6;
    entityIds[31] = 0x000000000000000000000000000000000000000000000000000000000004ddc7;
    entityIds[32] = 0x000000000000000000000000000000000000000000000000000000000004ddc8;
    entityIds[33] = 0x000000000000000000000000000000000000000000000000000000000004ddc9;
    entityIds[34] = 0x000000000000000000000000000000000000000000000000000000000004ddca;
    entityIds[35] = 0x000000000000000000000000000000000000000000000000000000000004ddcf;
    entityIds[36] = 0x000000000000000000000000000000000000000000000000000000000004ddd4;
    entityIds[37] = 0x000000000000000000000000000000000000000000000000000000000004ddd5;
    entityIds[38] = 0x000000000000000000000000000000000000000000000000000000000004ddd6;
    entityIds[39] = 0x000000000000000000000000000000000000000000000000000000000004ddd7;
    entityIds[40] = 0x000000000000000000000000000000000000000000000000000000000004ddd8;
    entityIds[41] = 0x000000000000000000000000000000000000000000000000000000000004ddd9;
    entityIds[42] = 0x0000000000000000000000000000000000000000000000000000000000051632;
    entityIds[43] = 0x0000000000000000000000000000000000000000000000000000000000051aac;
    entityIds[44] = 0x0000000000000000000000000000000000000000000000000000000000051ab5;
    entityIds[45] = 0x0000000000000000000000000000000000000000000000000000000000051abe;
    entityIds[46] = 0x0000000000000000000000000000000000000000000000000000000000057a8d;
    entityIds[47] = 0x0000000000000000000000000000000000000000000000000000000000057bf4;
    entityIds[48] = 0x0000000000000000000000000000000000000000000000000000000000058656;
    entityIds[49] = 0x0000000000000000000000000000000000000000000000000000000000059095;
    entityIds[50] = 0x000000000000000000000000000000000000000000000000000000000005d2fc;
    entityIds[51] = 0x000000000000000000000000000000000000000000000000000000000005d441;
    entityIds[52] = 0x0000000000000000000000000000000000000000000000000000000000064ed4;
    entityIds[53] = 0x000000000000000000000000000000000000000000000000000000000006c76e;
    entityIds[54] = 0x000000000000000000000000000000000000000000000000000000000008a395;
    entityIds[55] = 0x000000000000000000000000000000000000000000000000000000000008b5f4;
    entityIds[56] = 0x00000000000000000000000000000000000000000000000000000000000902be;
    entityIds[57] = 0x000000000000000000000000000000000000000000000000000000000009e6ab;
    entityIds[58] = 0x00000000000000000000000000000000000000000000000000000000000da819;
    entityIds[59] = 0x00000000000000000000000000000000000000000000000000000000000e4630;
    entityIds[60] = 0x00000000000000000000000000000000000000000000000000000000000e52bd;
    entityIds[61] = 0x00000000000000000000000000000000000000000000000000000000000e5ca2;
    entityIds[62] = 0x00000000000000000000000000000000000000000000000000000000000e8ecd;
    entityIds[63] = 0x00000000000000000000000000000000000000000000000000000000000e9052;
    entityIds[64] = 0x000000000000000000000000000000000000000000000000000000000011fa2c;
    entityIds[65] = 0x0000000000000000000000000000000000000000000000000000000000141e10;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      console.logBytes32(entityId);
      require(Chip.getChipAddress(entityId) == 0xD45bE5726Da3347eab4F7Cb151E3bc9De3a18749, "Chip address not set");
      Chip.setChipAddress(entityId, 0xf19023b2a4958e08852D5CE139974C430AB13A03);
      // uint8 objectTypeId = ObjectType.get(entityId);
      // require(objectTypeId != NullObjectTypeId, "Object type not set");
      // // uint16 currentBatteryCount = InventoryCount.get(entityId, ChipBatteryObjectID);
      // // uint256 currentBatteryLevel = Chip.getBatteryLevel(entityId);
      // uint16 currentBatteryCount = entityCounts[i];
      // require(currentBatteryCount > 0, "Battery count is 0");
      // uint16 gaveLastTime = currentBatteryCount / 2;
      // uint16 giveNow = currentBatteryCount - gaveLastTime;
      // require(giveNow > 0, "Give now is 0");
      // console.logUint(giveNow);
      // testAddToInventoryCount(entityId, objectTypeId, ChipBatteryObjectID, giveNow);
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
