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
import { NullObjectTypeId, ChestObjectID, BedrockObjectID, ReinforcedOakLumberObjectID } from "../src/ObjectTypeIds.sol";

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

    bytes32[] memory entityIds = new bytes32[](45);
    entityIds[0] = 0x000000000000000000000000000000000000000000000000000000000004ddb6;
    entityIds[1] = 0x000000000000000000000000000000000000000000000000000000000004d614;
    entityIds[2] = 0x000000000000000000000000000000000000000000000000000000000004d5ff;
    entityIds[3] = 0x000000000000000000000000000000000000000000000000000000000004ddd6;
    entityIds[4] = 0x000000000000000000000000000000000000000000000000000000000004ddb0;
    entityIds[5] = 0x000000000000000000000000000000000000000000000000000000000004ddad;
    entityIds[6] = 0x000000000000000000000000000000000000000000000000000000000004ddab;
    entityIds[7] = 0x000000000000000000000000000000000000000000000000000000000004ddbc;
    entityIds[8] = 0x000000000000000000000000000000000000000000000000000000000004ddd8;
    entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000004ddca;
    entityIds[10] = 0x000000000000000000000000000000000000000000000000000000000004d620;
    entityIds[11] = 0x000000000000000000000000000000000000000000000000000000000004ddc5;
    entityIds[12] = 0x000000000000000000000000000000000000000000000000000000000004ddd4;
    entityIds[13] = 0x000000000000000000000000000000000000000000000000000000000004d60c;
    entityIds[14] = 0x000000000000000000000000000000000000000000000000000000000004d616;
    entityIds[15] = 0x000000000000000000000000000000000000000000000000000000000004d605;
    entityIds[16] = 0x000000000000000000000000000000000000000000000000000000000004ddc8;
    entityIds[17] = 0x000000000000000000000000000000000000000000000000000000000004d613;
    entityIds[18] = 0x000000000000000000000000000000000000000000000000000000000004ddb1;
    entityIds[19] = 0x000000000000000000000000000000000000000000000000000000000004d623;
    entityIds[20] = 0x0000000000000000000000000000000000000000000000000000000000051aac;
    entityIds[21] = 0x000000000000000000000000000000000000000000000000000000000004ddc9;
    entityIds[22] = 0x000000000000000000000000000000000000000000000000000000000004d60d;
    entityIds[23] = 0x000000000000000000000000000000000000000000000000000000000004ddd5;
    entityIds[24] = 0x000000000000000000000000000000000000000000000000000000000004d60b;
    entityIds[25] = 0x000000000000000000000000000000000000000000000000000000000004ddc6;
    entityIds[26] = 0x000000000000000000000000000000000000000000000000000000000004d61b;
    entityIds[27] = 0x000000000000000000000000000000000000000000000000000000000004d615;
    entityIds[28] = 0x0000000000000000000000000000000000000000000000000000000000051ab5;
    entityIds[29] = 0x000000000000000000000000000000000000000000000000000000000004d5fe;
    entityIds[30] = 0x000000000000000000000000000000000000000000000000000000000004d621;
    entityIds[31] = 0x000000000000000000000000000000000000000000000000000000000004ddc0;
    entityIds[32] = 0x000000000000000000000000000000000000000000000000000000000004ddc7;
    entityIds[33] = 0x000000000000000000000000000000000000000000000000000000000004ddbb;
    entityIds[34] = 0x0000000000000000000000000000000000000000000000000000000000051abe;
    entityIds[35] = 0x000000000000000000000000000000000000000000000000000000000004d622;
    entityIds[36] = 0x000000000000000000000000000000000000000000000000000000000004d600;
    entityIds[37] = 0x000000000000000000000000000000000000000000000000000000000004d5fd;
    entityIds[38] = 0x000000000000000000000000000000000000000000000000000000000004ddac;
    entityIds[39] = 0x000000000000000000000000000000000000000000000000000000000004d60a;
    entityIds[40] = 0x000000000000000000000000000000000000000000000000000000000004ddaf;
    entityIds[41] = 0x000000000000000000000000000000000000000000000000000000000004ddd9;
    entityIds[42] = 0x000000000000000000000000000000000000000000000000000000000004ddcf;
    entityIds[43] = 0x000000000000000000000000000000000000000000000000000000000004ddbe;
    entityIds[44] = 0x000000000000000000000000000000000000000000000000000000000004ddd7;
    // entityIds[9] = 0x000000000000000000000000000000000000000000000000000000000000261d;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      console.logBytes32(entityId);
      require(Chip.getChipAddress(entityId) == 0xd8aF82d9634cDa04D72aA9C26D468bA884f8Be19, "Chip address not set");
      Chip.setChipAddress(entityId, 0x0a8E974cfd0fa2933891Ea20e6AD5c83f9B304cc);
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
