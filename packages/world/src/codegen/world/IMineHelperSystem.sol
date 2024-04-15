// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

/* Autogenerated file. Do not edit manually. */

/**
 * @title IMineHelperSystem
 * @author MUD (https://mud.dev) by Lattice (https://lattice.xyz)
 * @dev This interface is automatically generated from the corresponding system contract. Do not edit manually.
 */
interface IMineHelperSystem {
  function spendStaminaForMining(bytes32 playerEntityId, uint8 mineObjectTypeId, bytes32 equippedEntityId) external;
}