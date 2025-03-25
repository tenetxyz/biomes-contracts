// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../../src/codegen/world/IWorld.sol";

import { ensureAdminSystem } from "./ensureAdminSystem.sol";
import { vec3 } from "../../src/Vec3.sol";

contract TeleportScript is Script {
  function run(address worldAddress, address playerAddress, int32 x, int32 y, int32 z) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);
    IWorld world = IWorld(worldAddress);
    require(isContract(worldAddress), "Invalid world address provided");

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    ensureAdminSystem(world);

    world.adminTeleportPlayer(playerAddress, vec3(x, y, z));

    vm.stopBroadcast();
  }

  function isContract(address addr) internal returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }
}
