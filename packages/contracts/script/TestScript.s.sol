// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { GrassObjectID } from "../src/ObjectTypeIds.sol";

contract TestScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    IWorld world = IWorld(worldAddress);

    world.spawnPlayer(VoxelCoord(149, -61, -27));
    world.teleport(VoxelCoord(149, -62, -38));
    // bytes32 inventoryEntityId = world.mine(GrassObjectID, VoxelCoord(149, -63, -39));
    // world.build(inventoryEntityId, VoxelCoord(150, -62, -38));
    // world.hit(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // world.hit(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // world.hit(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    // world.logoffPlayer();
    // world.loginPlayer(VoxelCoord(149, -63, -39));

    vm.stopBroadcast();
  }
}
