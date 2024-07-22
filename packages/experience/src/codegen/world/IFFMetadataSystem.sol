// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IFFMetadataSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IFFMetadataSystem {
  function experience__setForceFieldName(bytes32 entityId, string memory name) external;

  function experience__deleteForceFieldMetadata(bytes32 entityId) external;
}
