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
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
import { StoneObjectID, BasaltCarvedObjectID } from "@biomesaw/terrain/src/ObjectTypeIds.sol";
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
    for (int16 x = SPAWN_LOW_X; x <= SPAWN_HIGH_X; x++) {
      for (int16 z = SPAWN_LOW_Z; z <= SPAWN_HIGH_Z; z++) {
        if (x == SPAWN_LOW_X || x == SPAWN_HIGH_X || z == SPAWN_LOW_Z || z == SPAWN_HIGH_Z) {
          adminSetObject(BasaltCarvedObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
        } else {
          adminSetObject(StoneObjectID, VoxelCoord(x, SPAWN_GROUND_Y, z));
        }
      }
    }

    vm.stopBroadcast();
  }

  function adminSetObject(uint8 objectTypeId, VoxelCoord memory coord) internal {
    bytes32 entityId = ReversePosition.get(coord.x, coord.y, coord.z);
    if (entityId == bytes32(0)) {
      entityId = getUniqueEntity();
      ReversePosition.set(coord.x, coord.y, coord.z, entityId);
    } else {
      if (ObjectType.get(entityId) == objectTypeId) {
        // no-op
        return;
      }
    }
    ObjectType.set(entityId, objectTypeId);
    Position.set(entityId, coord.x, coord.y, coord.z);
  }
}
