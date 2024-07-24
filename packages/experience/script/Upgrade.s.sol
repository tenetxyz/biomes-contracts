// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { ChipMetadata, ChipMetadataData } from "../src/codegen/tables/ChipMetadata.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    address chipAddress = 0x712516e61C8B383dF4A63CFe83d7701Bce54B03e;
    console.log(ChipMetadata.getName(chipAddress));
    // ChipMetadata.deleteRecord(chipAddress);

    vm.stopBroadcast();
  }
}
