// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title ITransferSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface ITransferSystem {
  function transfer(bytes32 srcEntityId, bytes32 dstEntityId, bytes32[] memory inventoryEntityIds) external;
}
