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

contract PostDeploy is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // Register a sample ERC721, so that the ERC721 Puppet Module is installed
    // TODO: Figure out a way to do this without having to manually register a ERC721
    // registerERC721(
    //   IWorld(worldAddress),
    //   bytes14("test-721"),
    //   MUDERC721MetadataData({ symbol: "test-721", name: "test-721", baseURI: "" })
    // );

    // Register a sample ERC20, so that the ERC20 Puppet Module is installed
    // TODO: Figure out a way to do this without having to manually register a ERC20
    // registerERC20(
    //   IWorld(worldAddress),
    //   bytes14("test-20"),
    //   MUDERC20MetadataData({ symbol: "test-20", name: "test-20", decimals: 18 })
    // );

    IWorld(worldAddress).initPlayerObjectTypes();
    IWorld(worldAddress).initTerrainBlockObjectTypes();

    IWorld(worldAddress).initThermoblastObjectTypes();
    IWorld(worldAddress).initInteractableObjectTypes();
    IWorld(worldAddress).initWorkbenchObjectTypes();
    IWorld(worldAddress).initDyedObjectTypes();
    IWorld(worldAddress).initHandcraftedObjectTypes();

    IWorld(worldAddress).initThermoblastRecipes();
    IWorld(worldAddress).initInteractablesRecipes();
    IWorld(worldAddress).initWorkbenchRecipes();
    IWorld(worldAddress).initDyedRecipes();
    IWorld(worldAddress).initHandcrafedRecipes();

    vm.stopBroadcast();
  }
}
