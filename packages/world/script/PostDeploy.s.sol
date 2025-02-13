// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { IWorld } from "../src/codegen/world/IWorld.sol";
import { VoxelCoord } from "@biomesaw/utils/src/Types.sol";
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
