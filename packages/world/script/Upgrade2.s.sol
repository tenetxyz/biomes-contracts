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
import { ObjectTypeMetadata } from "../src/codegen/tables/ObjectTypeMetadata.sol";
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
import { NullObjectTypeId, ChestObjectID, SmartChestObjectID, TextSignObjectID, SmartTextSignObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChipBatteryObjectID, ForceFieldObjectID, GoldBarObjectID, GoldCubeObjectID, SilverBarObjectID, SilverCubeObjectID, DiamondObjectID, DiamondCubeObjectID, NeptuniumBarObjectID, NeptuniumCubeObjectID } from "../src/ObjectTypeIds.sol";

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

    bytes32[] memory entityIds = new bytes32[](89);
    entityIds[0] = 0x00000000000000000000000000000000000000000000000000000000000029f2;
    entityIds[1] = 0x0000000000000000000000000000000000000000000000000000000000002a23;
    entityIds[2] = 0x0000000000000000000000000000000000000000000000000000000000004247;
    entityIds[3] = 0x0000000000000000000000000000000000000000000000000000000000003459;
    entityIds[4] = 0x0000000000000000000000000000000000000000000000000000000000001f6a;
    entityIds[5] = 0x0000000000000000000000000000000000000000000000000000000000002258;
    entityIds[6] = 0x00000000000000000000000000000000000000000000000000000000000020ce;
    entityIds[7] = 0x0000000000000000000000000000000000000000000000000000000000001fb4;
    entityIds[8] = 0x0000000000000000000000000000000000000000000000000000000000001fb5;
    entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000000225f;
    entityIds[10] = 0x00000000000000000000000000000000000000000000000000000000000020cd;
    entityIds[11] = 0x00000000000000000000000000000000000000000000000000000000000020d0;
    entityIds[12] = 0x000000000000000000000000000000000000000000000000000000000000459b;
    entityIds[13] = 0x0000000000000000000000000000000000000000000000000000000000002828;
    entityIds[14] = 0x00000000000000000000000000000000000000000000000000000000000036a2;
    entityIds[15] = 0x0000000000000000000000000000000000000000000000000000000000003aa9;
    entityIds[16] = 0x0000000000000000000000000000000000000000000000000000000000003a9f;
    entityIds[17] = 0x0000000000000000000000000000000000000000000000000000000000003aa3;
    entityIds[18] = 0x00000000000000000000000000000000000000000000000000000000000035b9;
    entityIds[19] = 0x0000000000000000000000000000000000000000000000000000000000003e18;
    entityIds[20] = 0x0000000000000000000000000000000000000000000000000000000000005793;
    entityIds[21] = 0x00000000000000000000000000000000000000000000000000000000000086e4;
    entityIds[22] = 0x000000000000000000000000000000000000000000000000000000000000576b;
    entityIds[23] = 0x0000000000000000000000000000000000000000000000000000000000005037;
    entityIds[24] = 0x0000000000000000000000000000000000000000000000000000000000005045;
    entityIds[25] = 0x0000000000000000000000000000000000000000000000000000000000005043;
    entityIds[26] = 0x0000000000000000000000000000000000000000000000000000000000005782;
    entityIds[27] = 0x0000000000000000000000000000000000000000000000000000000000005776;
    entityIds[28] = 0x0000000000000000000000000000000000000000000000000000000000008b5a;
    entityIds[29] = 0x000000000000000000000000000000000000000000000000000000000000502f;
    entityIds[30] = 0x0000000000000000000000000000000000000000000000000000000000007922;
    entityIds[31] = 0x0000000000000000000000000000000000000000000000000000000000005046;
    entityIds[32] = 0x0000000000000000000000000000000000000000000000000000000000005767;
    entityIds[33] = 0x0000000000000000000000000000000000000000000000000000000000008b6f;
    entityIds[34] = 0x0000000000000000000000000000000000000000000000000000000000008b4f;
    entityIds[35] = 0x0000000000000000000000000000000000000000000000000000000000005044;
    entityIds[36] = 0x0000000000000000000000000000000000000000000000000000000000005022;
    entityIds[37] = 0x0000000000000000000000000000000000000000000000000000000000008b70;
    entityIds[38] = 0x0000000000000000000000000000000000000000000000000000000000008b56;
    entityIds[39] = 0x0000000000000000000000000000000000000000000000000000000000007be4;
    entityIds[40] = 0x000000000000000000000000000000000000000000000000000000000000791e;
    entityIds[41] = 0x0000000000000000000000000000000000000000000000000000000000005783;
    entityIds[42] = 0x000000000000000000000000000000000000000000000000000000000000577f;
    entityIds[43] = 0x0000000000000000000000000000000000000000000000000000000000008b5b;
    entityIds[44] = 0x0000000000000000000000000000000000000000000000000000000000005030;
    entityIds[45] = 0x0000000000000000000000000000000000000000000000000000000000005021;
    entityIds[46] = 0x0000000000000000000000000000000000000000000000000000000000005781;
    entityIds[47] = 0x0000000000000000000000000000000000000000000000000000000000005775;
    entityIds[48] = 0x0000000000000000000000000000000000000000000000000000000000007be5;
    entityIds[49] = 0x0000000000000000000000000000000000000000000000000000000000007921;
    entityIds[50] = 0x0000000000000000000000000000000000000000000000000000000000005784;
    entityIds[51] = 0x0000000000000000000000000000000000000000000000000000000000005790;
    entityIds[52] = 0x0000000000000000000000000000000000000000000000000000000000005778;
    entityIds[53] = 0x0000000000000000000000000000000000000000000000000000000000005036;
    entityIds[54] = 0x0000000000000000000000000000000000000000000000000000000000005779;
    entityIds[55] = 0x0000000000000000000000000000000000000000000000000000000000005038;
    entityIds[56] = 0x000000000000000000000000000000000000000000000000000000000000577a;
    entityIds[57] = 0x0000000000000000000000000000000000000000000000000000000000005024;
    entityIds[58] = 0x0000000000000000000000000000000000000000000000000000000000008b4c;
    entityIds[59] = 0x00000000000000000000000000000000000000000000000000000000000078f0;
    entityIds[60] = 0x0000000000000000000000000000000000000000000000000000000000005770;
    entityIds[61] = 0x000000000000000000000000000000000000000000000000000000000000791d;
    entityIds[62] = 0x0000000000000000000000000000000000000000000000000000000000005768;
    entityIds[63] = 0x000000000000000000000000000000000000000000000000000000000000576a;
    entityIds[64] = 0x00000000000000000000000000000000000000000000000000000000000078f5;
    entityIds[65] = 0x000000000000000000000000000000000000000000000000000000000000578e;
    entityIds[66] = 0x00000000000000000000000000000000000000000000000000000000000078f1;
    entityIds[67] = 0x000000000000000000000000000000000000000000000000000000000000503e;
    entityIds[68] = 0x0000000000000000000000000000000000000000000000000000000000008b46;
    entityIds[69] = 0x000000000000000000000000000000000000000000000000000000000000578f;
    entityIds[70] = 0x0000000000000000000000000000000000000000000000000000000000008b57;
    entityIds[71] = 0x0000000000000000000000000000000000000000000000000000000000005766;
    entityIds[72] = 0x0000000000000000000000000000000000000000000000000000000000007bf0;
    entityIds[73] = 0x0000000000000000000000000000000000000000000000000000000000005023;
    entityIds[74] = 0x0000000000000000000000000000000000000000000000000000000000007bf1;
    entityIds[75] = 0x0000000000000000000000000000000000000000000000000000000000005031;
    entityIds[76] = 0x00000000000000000000000000000000000000000000000000000000000078f4;
    entityIds[77] = 0x0000000000000000000000000000000000000000000000000000000000005769;
    entityIds[78] = 0x000000000000000000000000000000000000000000000000000000000000502e;
    entityIds[79] = 0x00000000000000000000000000000000000000000000000000000000000097ab;
    entityIds[80] = 0x0000000000000000000000000000000000000000000000000000000000009fe0;
    entityIds[81] = 0x000000000000000000000000000000000000000000000000000000000000a19a;
    entityIds[82] = 0x000000000000000000000000000000000000000000000000000000000000a97b;
    entityIds[83] = 0x000000000000000000000000000000000000000000000000000000000000ada6;
    entityIds[84] = 0x000000000000000000000000000000000000000000000000000000000000ae88;
    entityIds[85] = 0x0000000000000000000000000000000000000000000000000000000000005791;
    entityIds[86] = 0x000000000000000000000000000000000000000000000000000000000000ae8d;
    entityIds[87] = 0x0000000000000000000000000000000000000000000000000000000000019962;
    entityIds[88] = 0x000000000000000000000000000000000000000000000000000000000000adcf;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      // if (
      //   entityId == 0x00000000000000000000000000000000000000000000000000000000000309d4 ||
      //   entityId == 0x00000000000000000000000000000000000000000000000000000000002a4960
      // ) {
      //   continue;
      // }
      // require(Chip.getChipAddress(entityId) == 0x4bd5A12B75B24418eCB1285aAAd16a05b94f7096, "Chip address not set");
      require(ObjectType.get(entityId) == ChestObjectID, "Object type not set");
      require(Chip.getBatteryLevel(entityId) == 0, "Battery level not 0");
      if (Chip.getChipAddress(entityId) != address(0)) {
        ObjectType.set(entityId, SmartChestObjectID);
      }
      // Chip.setChipAddress(entityId, 0x907528c1b709DDe480f96Bf468755AeFEEeCB2a8);
      // uint24 currentNumUsesLeft = ItemMetadata.get(entityId);
      // if (currentNumUsesLeft == 0) {
      //   continue;
      // }
      // uint8 objectTypeId = ObjectType.get(entityId);
      // uint24 durability = ObjectTypeMetadata.getDurability(objectTypeId);
      // require(durability > 0, "Durability is 0");
      // console.logBytes32(entityId);
      // console.logUint(durability);
      // ItemMetadata.set(entityId, durability);

      // require(objectTypeId != NullObjectTypeId, "Object type not set");
      // uint16 currentCount = InventoryCount.get(entityId, DiamondObjectID);
      // console.log("currentCount");
      // console.logUint(currentCount);
      // require(currentCount > 0, "Count is 0");
      // uint16 newCount = currentCount * 4;
      // console.log("newCount");
      // console.logUint(newCount);
      // uint16 addAmount = newCount - currentCount;
      // console.log("addAmount");
      // console.logUint(addAmount);
      // testAddToInventoryCount(
      //   0x00000000000000000000000000000000000000000000000000000000000309d8,
      //   objectTypeId,
      //   DiamondObjectID,
      //   addAmount
      // );
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
