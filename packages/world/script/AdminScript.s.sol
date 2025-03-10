// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";

import { registerERC20 } from "@latticexyz/world-modules/src/modules/erc20-puppet/registerERC20.sol";
import { registerERC721 } from "@latticexyz/world-modules/src/modules/erc721-puppet/registerERC721.sol";
import { ERC721MetadataData as MUDERC721MetadataData } from "@latticexyz/world-modules/src/modules/erc721-puppet/tables/ERC721Metadata.sol";
import { ERC20MetadataData as MUDERC20MetadataData } from "@latticexyz/world-modules/src/modules/erc20-puppet/tables/ERC20Metadata.sol";
import { ResourceId, WorldResourceIdLib, WorldResourceIdInstance } from "@latticexyz/world/src/WorldResourceId.sol";
import { ROOT_NAMESPACE } from "@latticexyz/world/src/constants.sol";
import { RESOURCE_SYSTEM } from "@latticexyz/world/src/worldResourceTypes.sol";
import { Systems } from "@latticexyz/world/src/codegen/tables/Systems.sol";

import { Energy } from "../src/codegen/tables/Energy.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";

import { ObjectTypes } from "../src/ObjectTypes.sol";
import { Vec3 } from "../src/Vec3.sol";
import { EntityId, encodePlayerEntityId } from "../src/EntityId.sol";

import { MAX_PLAYER_ENERGY } from "../src/Constants.sol";
import { TestUtils } from "../test/utils/TestUtils.sol";
import { AdminSystem } from "../src/systems/admin/AdminSystem.sol";

contract AdminScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);
    IWorld world = IWorld(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    ensureAdminSystem(world);

    EntityId playerEntityId = encodePlayerEntityId(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    // TODO: create player?
    Energy.setEnergy(playerEntityId, MAX_PLAYER_ENERGY);
    Energy.setLastUpdatedTime(playerEntityId, uint128(block.timestamp));

    world.adminAddToInventory(playerEntityId, ObjectTypes.OakLog, 99);
    world.adminAddToInventory(playerEntityId, ObjectTypes.Chest, 1);
    world.adminAddToolToInventory(playerEntityId, ObjectTypes.SilverPick);

    vm.stopBroadcast();
  }

  function ensureAdminSystem(IWorld world) internal {
    ResourceId adminSystemId = WorldResourceIdLib.encode({
      typeId: RESOURCE_SYSTEM,
      namespace: ROOT_NAMESPACE,
      name: "AdminSystem"
    });
    address existingAdminSystem = Systems.getSystem(adminSystemId);
    if (existingAdminSystem != address(0)) {
      return;
    }
    AdminSystem adminSystem = new AdminSystem();
    world.registerSystem(adminSystemId, adminSystem, true);

    world.registerRootFunctionSelector(
      adminSystemId,
      "adminAddToInventory(bytes32,uint16,uint16)",
      "adminAddToInventory(bytes32,uint16,uint16)"
    );
    world.registerRootFunctionSelector(
      adminSystemId,
      "adminAddToolToInventory(bytes32,uint16)",
      "adminAddToolToInventory(bytes32,uint16)"
    );
    world.registerRootFunctionSelector(
      adminSystemId,
      "adminRemoveFromInventory(bytes32,uint16,uint16)",
      "adminRemoveFromInventory(bytes32,uint16,uint16)"
    );
    world.registerRootFunctionSelector(
      adminSystemId,
      "adminRemoveToolFromInventory(bytes32,bytes32)",
      "adminRemoveToolFromInventory(bytes32,bytes32)"
    );
  }
}
