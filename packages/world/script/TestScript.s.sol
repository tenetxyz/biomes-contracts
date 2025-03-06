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

import { Energy } from "../src/codegen/tables/Energy.sol";
import { Player } from "../src/codegen/tables/Player.sol";
import { ObjectType } from "../src/codegen/tables/ObjectType.sol";

import { ObjectTypes } from "../src/ObjectTypes.sol";
import { Vec3 } from "../src/Vec3.sol";
import { EntityId } from "../src/EntityId.sol";

import { MAX_PLAYER_ENERGY } from "../src/Constants.sol";
import { TestUtils } from "../test/utils/TestUtils.sol";

contract TestScript is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    EntityId playerEntityId = Player.get(0xE0ae70caBb529336e25FA7a1f036b77ad0089d2a);
    require(playerEntityId.exists(), "Player entity not found");
    Energy.setEnergy(playerEntityId, MAX_PLAYER_ENERGY);
    Energy.setLastUpdatedTime(playerEntityId, uint128(block.timestamp));

    // TestUtils.addToInventoryCount(playerEntityId, ObjectTypes.Player, ObjectTypes.OakLog, 99);
    // TestUtils.addToInventoryCount(playerEntityId, ObjectTypes.Player, ObjectTypes.Chest, 1);

    vm.stopBroadcast();
  }
}
