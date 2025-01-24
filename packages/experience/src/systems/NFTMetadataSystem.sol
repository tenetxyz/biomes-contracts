// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import { IWorld } from "../codegen/world/IWorld.sol";
import { System } from "@latticexyz/world/src/System.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

import { AccessControl } from "@latticexyz/world/src/AccessControl.sol";
import { ERC721Registry } from "@latticexyz/world-modules/src/modules/erc721-puppet/tables/ERC721Registry.sol";
import { ERC721_REGISTRY_TABLE_ID } from "@latticexyz/world-modules/src/modules/erc721-puppet/constants.sol";

import { ERC721Metadata, ERC721MetadataData } from "../codegen/tables/ERC721Metadata.sol";
import { NamespaceId } from "../codegen/tables/NamespaceId.sol";

contract NFTMetadataSystem is System {
  function setNFTMetadata(ERC721MetadataData memory metadata) public {
    require(
      ResourceId.unwrap(metadata.systemId) == bytes32(0),
      "NFTMetadataSystem: If this is a MUD nft, use setMUDNFTMetadata"
    );
    ERC721Metadata.set(_msgSender(), metadata);
  }

  function setMUDNFTMetadata(ResourceId namespaceId, ERC721MetadataData memory metadata) public {
    AccessControl.requireOwner(namespaceId, _msgSender());
    address nftAddress = ERC721Registry.get(ERC721_REGISTRY_TABLE_ID, namespaceId);
    require(nftAddress != address(0), "NFTMetadataSystem: nft not found for namespace");
    ERC721Metadata.set(nftAddress, metadata);
    NamespaceId.set(nftAddress, namespaceId);
  }

  function deleteNFTMetadata() public {
    ERC721Metadata.deleteRecord(_msgSender());
    NamespaceId.deleteRecord(_msgSender());
  }
}
