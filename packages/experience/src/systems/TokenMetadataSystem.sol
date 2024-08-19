// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { TokenMetadata, TokenMetadataData } from "../codegen/tables/TokenMetadata.sol";

contract TokenMetadataSystem is System {
  function setTokenMetadata(TokenMetadataData memory metadata) public {
    TokenMetadata.set(_msgSender(), metadata);
  }

  function deleteTokenMetadata() public {
    TokenMetadata.deleteRecord(_msgSender());
  }
}
