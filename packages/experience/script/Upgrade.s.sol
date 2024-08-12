// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { ChipMetadata, ChipMetadataData } from "../src/codegen/tables/ChipMetadata.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Tokens } from "../src/codegen/tables/Tokens.sol";

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // console.logUint(Tokens.lengthTokens(0x1f820052916970Ff09150b58F2f0Fb842C5a58be));
    // Tokens.deleteRecord(0x1f820052916970Ff09150b58F2f0Fb842C5a58be);

    address chipAddress = 0x7E979136dF1D741991D4e1769B576Ab2D65aC5F3;
    console.log(ChipMetadata.getName(chipAddress));
    // ChipMetadata.deleteRecord(chipAddress);

    vm.stopBroadcast();
  }
}
