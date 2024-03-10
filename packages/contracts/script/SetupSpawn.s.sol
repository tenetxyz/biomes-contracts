// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { getUniqueEntity } from "@latticexyz/world-modules/src/modules/uniqueentity/getUniqueEntity.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";
import { Position } from "../src/codegen/tables/Position.sol";
import { ReversePosition } from "../src/codegen/tables/ReversePosition.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { VoxelCoord } from "@everlonxyz/utils/src/Types.sol";
import { StoneObjectID } from "../src/ObjectTypeIds.sol";
import { SPAWN_LOW_X, SPAWN_HIGH_X, SPAWN_LOW_Z, SPAWN_HIGH_Z, SPAWN_GROUND_Y } from "../src/Constants.sol";

contract SetupSpawn is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // Create 20 x 20 platform of stone
    for (int32 x = SPAWN_LOW_X; x <= SPAWN_HIGH_X; x++) {
      for (int32 z = SPAWN_LOW_Z; z <= SPAWN_HIGH_Z; z++) {
        adminSetObject(StoneObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
      }
    }

    vm.stopBroadcast();
  }

  function adminSetObject(bytes32 objectTypeId, VoxelCoord memory coord) internal {
    bytes32 newEntityId = getUniqueEntity();
    ObjectType.set(newEntityId, objectTypeId);
    Position.set(newEntityId, coord.x, coord.y, coord.z);
    ReversePosition.set(coord.x, coord.y, coord.z, newEntityId);
  }
}
