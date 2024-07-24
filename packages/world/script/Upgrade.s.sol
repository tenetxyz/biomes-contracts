// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Unstable_CallWithSignatureSystem } from "@latticexyz/world-modules/src/modules/callwithsignature/Unstable_CallWithSignatureSystem.sol";
import { DELEGATION_SYSTEM_ID } from "@latticexyz/world-modules/src/modules/callwithsignature/constants.sol";
import { ChestMetadata, ChestMetadataData } from "../src/codegen/tables/ChestMetadata.sol";

import { IERC165 } from "@latticexyz/store/src/IERC165.sol";

interface IChestTransferHook is IERC165 {
  function onHookSet(bytes32 chestEntityId) external;

  function onHookRemoved(bytes32 chestEntityId) external;

  function allowTransfer(
    bytes32 srcEntityId,
    bytes32 dstEntityId,
    uint8 transferObjectTypeId,
    uint16 numToTransfer,
    bytes32 toolEntityId,
    bytes memory extraData
  ) external payable returns (bool);
}

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // Unstable_CallWithSignatureSystem newUpgradedSystem = new Unstable_CallWithSignatureSystem();
    // IWorld(worldAddress).registerSystem(DELEGATION_SYSTEM_ID, newUpgradedSystem, true);

    bytes32[] memory entityIds = new bytes32[](2);
    entityIds[0] = 0x00000000000000000000000000000000000000000000000000000000000005fe;
    entityIds[1] = 0x0000000000000000000000000000000000000000000000000000000000000603;

    for (uint i = 0; i < entityIds.length; i++) {
      bytes32 chestEntityId = entityIds[i];
      ChestMetadataData memory chestMetadata = ChestMetadata.get(chestEntityId);
      if (chestMetadata.owner == address(0)) {
        continue;
      }
      console.log("FOUND CHEST");
      console.logBytes32(chestEntityId);
      if (chestMetadata.onTransferHook != address(0)) {
        console.log("REMOVING HOOK");
        IChestTransferHook(chestMetadata.onTransferHook).onHookRemoved(chestEntityId);
        ChestMetadata.setOnTransferHook(chestEntityId, address(0));
      }
      if (chestMetadata.strength > 0) {
        console.log("SETTING STRENGTH TO 0");
        ChestMetadata.setStrength(chestEntityId, 0);
      }
    }

    vm.stopBroadcast();
  }
}
