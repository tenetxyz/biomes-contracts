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

    bytes32[] memory entityIds = new bytes32[](1);
    entityIds[0] = 0x0000000000000000000000000000000000000000000000000000000000000a0d;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 entityId = entityIds[i];
      uint8 objectTypeId = ObjectType.get(entityId);
      require(objectTypeId != NullObjectTypeId);
      uint16 numReinforcedChest = InventoryCount.get(entityId, 162);
      console.log("numReinforcedChest");
      console.logUint(numReinforcedChest);
      if (numReinforcedChest > 0) {
        testRemoveFromInventoryCount(entityId, 162, numReinforcedChest);
        testAddToInventoryCount(entityId, objectTypeId, ChestObjectID, numReinforcedChest);
        testAddToInventoryCount(entityId, objectTypeId, BedrockObjectID, numReinforcedChest);
      }

      uint16 numBedrockChest = InventoryCount.get(entityId, 163);
      console.log("numBedrockChest");
      console.logUint(numBedrockChest);
      if (numBedrockChest > 0) {
        testRemoveFromInventoryCount(entityId, 163, numBedrockChest);
        testAddToInventoryCount(entityId, objectTypeId, ChestObjectID, numReinforcedChest);
        testAddToInventoryCount(entityId, objectTypeId, ReinforcedOakLumberObjectID, numReinforcedChest);
      }
    }

    vm.stopBroadcast();
  }
}
