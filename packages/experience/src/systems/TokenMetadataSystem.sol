// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/store/src/ResourceId.sol";

import { AccessControlLib } from "@latticexyz/world-modules/src/utils/AccessControlLib.sol";
import { ERC20Registry } from "@latticexyz/world-modules/src/modules/erc20-puppet/tables/ERC20Registry.sol";
import { ERC20_REGISTRY_TABLE_ID } from "@latticexyz/world-modules/src/modules/erc20-puppet/constants.sol";

import { TokenMetadata, TokenMetadataData } from "../codegen/tables/TokenMetadata.sol";

contract TokenMetadataSystem is System {
  function setTokenMetadata(TokenMetadataData memory metadata) public {
    TokenMetadata.set(_msgSender(), metadata);
  }

  function setMUDTokenMetadata(ResourceId namespaceId, TokenMetadataData memory metadata) public {
    AccessControlLib.requireOwner(namespaceId, _msgSender());
    address tokenAddress = ERC20Registry.get(ERC20_REGISTRY_TABLE_ID, namespaceId);
    require(tokenAddress != address(0), "TokenMetadataSystem: token not found for namespace");
    TokenMetadata.set(tokenAddress, metadata);
  }

  function deleteTokenMetadata() public {
    TokenMetadata.deleteRecord(_msgSender());
  }
}
