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
import { NullObjectTypeId, ChestObjectID, BedrockObjectID, ReinforcedOakLumberObjectID, ChipBatteryObjectID, ForceFieldObjectID, GoldBarObjectID, GoldCubeObjectID, SilverBarObjectID, SilverCubeObjectID, DiamondObjectID, DiamondCubeObjectID, NeptuniumBarObjectID, NeptuniumCubeObjectID } from "../src/ObjectTypeIds.sol";

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

    bytes32[] memory entityIds = new bytes32[](12);
    entityIds[0] = 0x0000000000000000000000000000000000000000000000000000000000001f69;
    entityIds[1] = 0x00000000000000000000000000000000000000000000000000000000000029f4;
    entityIds[2] = 0x0000000000000000000000000000000000000000000000000000000000002a2c;
    entityIds[3] = 0x0000000000000000000000000000000000000000000000000000000000002a5f;
    entityIds[4] = 0x0000000000000000000000000000000000000000000000000000000000002ab7;
    entityIds[5] = 0x000000000000000000000000000000000000000000000000000000000000346c;
    entityIds[6] = 0x00000000000000000000000000000000000000000000000000000000000034a8;
    entityIds[7] = 0x0000000000000000000000000000000000000000000000000000000000003562;
    entityIds[8] = 0x00000000000000000000000000000000000000000000000000000000000035b8;
    entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000000adc8;
    entityIds[10] = 0x000000000000000000000000000000000000000000000000000000000000add3;
    entityIds[11] = 0x00000000000000000000000000000000000000000000000000000000000199b3;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      // if (
      //   entityId == 0x00000000000000000000000000000000000000000000000000000000000309d4 ||
      //   entityId == 0x00000000000000000000000000000000000000000000000000000000002a4960
      // ) {
      //   continue;
      // }
      require(Chip.getChipAddress(entityId) == 0x4bd5A12B75B24418eCB1285aAAd16a05b94f7096, "Chip address not set");
      Chip.setChipAddress(entityId, 0x907528c1b709DDe480f96Bf468755AeFEEeCB2a8);
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
