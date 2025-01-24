// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ERC20Registry } from "@latticexyz/world-modules/src/modules/erc20-puppet/tables/ERC20Registry.sol";
import { ERC20_REGISTRY_TABLE_ID } from "@latticexyz/world-modules/src/modules/erc20-puppet/constants.sol";

import { ERC20Metadata, ERC20MetadataData } from "../codegen/tables/ERC20Metadata.sol";
import { NamespaceId } from "../codegen/tables/NamespaceId.sol";

contract TokenMetadataSystem is System {
  function setTokenMetadata(ERC20MetadataData memory metadata) public {
    require(
      ResourceId.unwrap(metadata.systemId) == bytes32(0),
      "TokenMetadataSystem: If this is a MUD token, use setMUDTokenMetadata"
    );
    ERC20Metadata.set(_msgSender(), metadata);
  }

  function setMUDTokenMetadata(ResourceId namespaceId, ERC20MetadataData memory metadata) public {
    AccessControl.requireOwner(namespaceId, _msgSender());
    address tokenAddress = ERC20Registry.get(ERC20_REGISTRY_TABLE_ID, namespaceId);
    require(tokenAddress != address(0), "TokenMetadataSystem: token not found for namespace");
    ERC20Metadata.set(tokenAddress, metadata);
    NamespaceId.set(tokenAddress, namespaceId);
  }

  function deleteTokenMetadata() public {
    ERC20Metadata.deleteRecord(_msgSender());
    NamespaceId.deleteRecord(_msgSender());
  }
}
