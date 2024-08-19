// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { NFTMetadata, NFTMetadataData } from "../codegen/tables/NFTMetadata.sol";

contract NFTMetadataSystem is System {
  function setNFTMetadata(NFTMetadataData memory metadata) public {
    NFTMetadata.set(_msgSender(), metadata);
  }

  function deleteNFTMetadata() public {
    NFTMetadata.deleteRecord(_msgSender());
  }
}
