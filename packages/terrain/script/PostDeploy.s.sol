// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";

contract PostDeploy is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // IWorld(worldAddress).setTerrainObjectTypeId(VoxelCoord(141, -63, -34), bytes32(keccak256("grass")));

    VoxelCoord[] memory coords = new VoxelCoord[](1000);
    bytes32[] memory objectTypes = new bytes32[](1000);
    for (uint i = 0; i < 1000; i++) {
      coords[i] = VoxelCoord(141, -63, -34);
      objectTypes[i] = bytes32(keccak256("grass"));
    }
    IWorld(worldAddress).setTerrainObjectTypeIds(coords, objectTypes);

    vm.stopBroadcast();
  }
}
