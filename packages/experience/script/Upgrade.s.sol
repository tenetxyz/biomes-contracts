// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { StoreSwitch } from "@latticexyz/store/src/StoreSwitch.sol";

import { ChipMetadata, ChipMetadataData } from "../src/codegen/tables/ChipMetadata.sol";
import { IWorld } from "../src/codegen/world/IWorld.sol";
import { Tokens } from "../src/codegen/tables/Tokens.sol";
import { NFTs } from "../src/codegen/tables/NFTs.sol";
import { ERC20Metadata } from "../src/codegen/tables/ERC20Metadata.sol";
import { ERC721Metadata } from "../src/codegen/tables/ERC721Metadata.sol";

contract Upgrade is Script {
  function run(address worldAddress) external {
    // Specify a store so that you can use tables directly in PostDeploy
    StoreSwitch.setStoreAddress(worldAddress);

    // Load the private key from the `PRIVATE_KEY` environment variable (in .env)
    uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

    // Start broadcasting transactions from the deployer account
    vm.startBroadcast(deployerPrivateKey);

    // console.logUint(NFTs.lengthNfts(0x3A971f521dde3434B6a3409ABCb77066Dd5123C3));
    // NFTs.deleteRecord(0x3A971f521dde3434B6a3409ABCb77066Dd5123C3);
    // console.log(ERC721Metadata.getName(0x45fCbe727564835ACfe428e41997e1c29697bB2B));
    // ERC721Metadata.deleteRecord(0x45fCbe727564835ACfe428e41997e1c29697bB2B);
    // console.log(ERC20Metadata.getIcon(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F));
    // ERC20Metadata.setName(0x2FF827f8750dbe1A7dbAD0f7354d0D0395551d2F, "Settlers Union Bank Coin");

    // address chipAddress = 0x7E979136dF1D741991D4e1769B576Ab2D65aC5F3;
    // console.log(ChipMetadata.getName(chipAddress));
    // ChipMetadata.deleteRecord(chipAddress);

    vm.stopBroadcast();
  }
}
