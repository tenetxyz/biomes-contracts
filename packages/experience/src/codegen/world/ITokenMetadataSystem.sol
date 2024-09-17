// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

import { ERC20MetadataData } from "./../tables/ERC20Metadata.sol";
import { ResourceId } from "@latticexyz/world/src/WorldResourceId.sol";

/**
 * @title ITokenMetadataSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITokenMetadataSystem {
  function experience__setTokenMetadata(ERC20MetadataData memory metadata) external;

  function experience__setMUDTokenMetadata(ResourceId namespaceId, ERC20MetadataData memory metadata) external;

  function experience__deleteTokenMetadata() external;
}