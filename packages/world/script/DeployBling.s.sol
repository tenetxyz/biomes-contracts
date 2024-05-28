// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

import { Bling } from "../external/Bling.sol";
import { WorldMetadata } from "../src/codegen/tables/WorldMetadata.sol";

contract DeployBling is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    Bling bling = new Bling(worldAddress);
    address blingAddress = address(bling);
    console.log("Bling deployed at address:");
    console.logAddress(blingAddress);

    WorldMetadata.setToken(blingAddress);

    vm.stopBroadcast();
  }
}
