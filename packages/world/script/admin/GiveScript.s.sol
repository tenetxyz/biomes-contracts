// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

import { IWorld } from "../../src/codegen/world/IWorld.sol";

import { EntityId } from "../../src/EntityId.sol";
import { ObjectTypes } from "../../src/ObjectTypes.sol";
import { Player } from "../../src/codegen/tables/Player.sol";

import { ensureAdminSystem } from "./ensureAdminSystem.sol";

contract GiveScript is Script {
  function run(address worldAddress, address playerAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);
    IWorld world = IWorld(worldAddress);
    require(isContract(worldAddress), "Invalid world address provided");

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    ensureAdminSystem(world);

    EntityId playerEntityId = Player.get(playerAddress);
    require(playerEntityId.exists(), "Player entity not found");

    world.adminAddToInventory(playerEntityId, ObjectTypes.OakLog, 99);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Chest, 1);
    world.adminAddToInventory(playerEntityId, ObjectTypes.ForceField, 10);
    world.adminAddToInventory(playerEntityId, ObjectTypes.TextSign, 1);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Workbench, 1);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Thermoblaster, 1);
    world.adminAddToInventory(playerEntityId, ObjectTypes.SpawnTile, 1);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Bed, 10);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Bucket, 1);
    world.adminAddToInventory(playerEntityId, ObjectTypes.WaterBucket, 10);
    world.adminAddToInventory(playerEntityId, ObjectTypes.OakSeed, 10);
    world.adminAddToInventory(playerEntityId, ObjectTypes.SpruceSeed, 10);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Fuel, 10);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Wheat, 10);
    world.adminAddToolToInventory(playerEntityId, ObjectTypes.WoodenHoe);
    world.adminAddToolToInventory(playerEntityId, ObjectTypes.SilverPick);
    world.adminAddToolToInventory(playerEntityId, ObjectTypes.NeptuniumAxe);

    vm.stopBroadcast();
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }
}
